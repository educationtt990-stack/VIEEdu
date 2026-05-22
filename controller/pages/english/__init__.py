import json
import os
import threading

from PySide6.QtCore import Q_ARG, Property, QMetaObject, QObject, Signal, Slot
from PySide6.QtCore import Qt as QtCoreQt

from controller.pages.english import model


class EnglishController(QObject):
    vocabularyChanged = Signal()
    grammarChanged = Signal()
    exercisesChanged = Signal()
    ipaChanged = Signal(str)
    aiResponseChanged = Signal(str)
    speakingChanged = Signal()
    listeningVisibleChanged = Signal()

    # Thêm các signal mới
    gradeDataChanged = Signal()
    sectionsChanged = Signal()
    aiLoadingChanged = Signal()

    def __init__(self):
        super().__init__()
        self._pronunciation_model = model.PronunciationModel()
        self._ai_service = model.AIService()

        self._db = {}
        self._grade_data = {}  # Dạng {10: ["Topic1", "Topic2", ...], ...}
        self._sections = ["Theory", "Exercises", "AI Practice"]
        self._section_icons = {"Theory": "📖", "Exercises": "✏️", "AI Practice": "🤖"}
        self._section_colors = {
            "Theory": "#3949AB",
            "Exercises": "#2E7D32",
            "AI Practice": "#E65100",
        }
        self._section_bg = {
            "Theory": "#E8EAF6",
            "Exercises": "#E8F5E9",
            "AI Practice": "#FFF3E0",
        }

        self._current_vocab = []
        self._current_grammar = ""
        self._current_exercises = []
        self._current_ai_response = ""
        self._ai_loading = False
        self._speaking = False
        self._listening_visible = False
        self._last_word = ""
        self._play_seq = 0

        self.load_data_from_json("./english.json")

    def load_data_from_json(self, file_path):
        if os.path.exists(file_path):
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    self._db = json.load(f)
                self._build_grade_data()
            except Exception as e:
                print(f"Error loading JSON: {e}")
        else:
            print(f"File not found: {file_path}")

    def _build_grade_data(self):
        """Xây dựng grade_data từ JSON"""
        self._grade_data = {}
        for grade_str, units in self._db.items():
            topics = []
            for unit in units:
                if "title" in unit:
                    topics.append(unit["title"])
            self._grade_data[grade_str] = topics
        self.gradeDataChanged.emit()

    @Property("QVariantMap", notify=gradeDataChanged)
    def gradeData(self):
        """Trả về dict grade -> list topics"""
        return self._grade_data

    @Property(list, constant=True)
    def sections(self):
        return self._sections

    @Property("QVariantMap", constant=True)
    def sectionIcons(self):
        return self._section_icons

    @Property("QVariantMap", constant=True)
    def sectionColors(self):
        return self._section_colors

    @Property("QVariantMap", constant=True)
    def sectionBg(self):
        return self._section_bg

    @Slot(int, result=list)
    def getTopicsForGrade(self, grade):
        """Lấy danh sách topics cho grade cụ thể"""
        return self._grade_data.get(str(grade), [])

    @Slot(str, result=list)
    def getUnitsByGrade(self, grade_str):
        """Lấy toàn bộ units cho grade"""
        return self._db.get(grade_str, [])

    @Slot(int, str, str)
    def openTopic(self, grade, topic_name, section):
        grade_str = str(grade)
        if grade_str not in self._db:
            return

        selected_unit = None
        for unit in self._db[grade_str]:
            if unit["title"] == topic_name:
                selected_unit = unit
                break

        if not selected_unit:
            return

        if section == "Theory":
            theory_data = selected_unit.get("theory", {})
            self._current_vocab = theory_data.get("vocabulary", [])
            self._current_grammar = theory_data.get(
                "grammar", "No grammar guide available."
            )
            self.vocabularyChanged.emit()
            self.grammarChanged.emit()

        elif section == "Exercises":
            self._current_exercises = selected_unit.get("exercises", [])
            self.exercisesChanged.emit()
            theory_data = selected_unit.get("theory", {})
            self._current_vocab = theory_data.get("vocabulary", [])
            self._current_grammar = theory_data.get(
                "grammar", "No grammar guide available."
            )
            self.vocabularyChanged.emit()
            self.grammarChanged.emit()

        elif section == "AI Practice":
            self._ai_loading = True
            self.aiLoadingChanged.emit()
            threading.Thread(
                target=self._ai_intro_thread,
                args=(selected_unit.get("title", ""),),
                daemon=True,
            ).start()

    @Property(list, notify=vocabularyChanged)
    def currentVocabulary(self):
        return self._current_vocab

    @Property(str, notify=grammarChanged)
    def currentGrammar(self):
        return self._current_grammar

    @Property(list, notify=exercisesChanged)
    def currentExercises(self):
        return self._current_exercises

    @Property(str, notify=aiResponseChanged)
    def aiResponse(self):
        return self._current_ai_response

    @Property(bool, notify=aiLoadingChanged)
    def aiLoading(self):
        return self._ai_loading

    @Slot(str, result=str)
    def generateIPA(self, text):
        ipa = self._pronunciation_model.generate_ipa(text)
        self.ipaChanged.emit(ipa)
        return ipa

    @Property(bool, notify=speakingChanged)
    def speaking(self):
        return self._speaking

    @Property(bool, notify=listeningVisibleChanged)
    def listeningVisible(self):
        return self._listening_visible

    @Slot(str)
    def speakWord(self, text):
        try:
            file_path = self._pronunciation_model.speak(text)
        except Exception as e:
            print(f"[speakWord] TTS error: {e}")
            return

        self._last_word = text
        if not self._listening_visible:
            self._listening_visible = True
            self.listeningVisibleChanged.emit()

        self._play_seq += 1
        seq = self._play_seq
        self._speaking = True
        self.speakingChanged.emit()

        threading.Thread(
            target=self._playback_thread,
            args=(file_path, seq),
            daemon=True,
        ).start()

    @Property(str, notify=speakingChanged)
    def lastWord(self):
        return self._last_word

    @Slot()
    def dismissSpeak(self):
        if self._listening_visible:
            self._listening_visible = False
            self.listeningVisibleChanged.emit()
        self._speaking = False
        self.speakingChanged.emit()

    @Slot()
    def repeatSpeak(self):
        if self._last_word:
            self.speakWord(self._last_word)

    def _playback_thread(self, file_path, seq):
        import subprocess
        import time

        played = False

        # Windows winmm.dll MCI
        if not played:
            try:
                import ctypes
                from ctypes import wintypes

                winmm = ctypes.windll.winmm
                winmm.mciSendStringW.argtypes = [
                    wintypes.LPCWSTR,
                    wintypes.LPWSTR,
                    wintypes.UINT,
                    wintypes.HANDLE,
                ]
                winmm.mciSendStringW.restype = wintypes.UINT
                buf = ctypes.create_unicode_buffer(256)
                ret = winmm.mciSendStringW(
                    f'open "{file_path}" type mpegvideo alias myaudio',
                    buf,
                    len(buf),
                    None,
                )
                if ret == 0:
                    winmm.mciSendStringW("play myaudio wait", None, 0, None)
                    winmm.mciSendStringW("close myaudio", None, 0, None)
                    played = True
            except Exception as e:
                print(f"[speakWord] MCI error: {e}")

        # VLC
        if not played:
            vlc_tries = [
                ["--aout=directsound"],
                ["--aout=winmm"],
                ["--aout=waveout"],
                ["--aout=mmdevice"],
            ]
            for args in vlc_tries:
                if played:
                    break
                try:
                    import vlc

                    inst = vlc.Instance(*args, "--intf", "dummy")
                    if inst is None:
                        continue
                    p = inst.media_player_new()
                    if p is None:
                        continue
                    p.set_media(inst.media_new(file_path))
                    p.play()
                    for _ in range(600):
                        time.sleep(0.1)
                        if not p.is_playing():
                            break
                    played = True
                except Exception as e:
                    print(f"[speakWord] VLC({args}) error: {e}")

        # ffplay
        if not played:
            try:
                subprocess.run(
                    [
                        "ffplay",
                        "-nodisp",
                        "-autoexit",
                        "-loglevel",
                        "quiet",
                        "-sample_rate",
                        "44100",
                        file_path,
                    ],
                    timeout=30,
                )
                played = True
            except Exception as e:
                print(f"[speakWord] ffplay error: {e}")

        # PowerShell MediaPlayer
        if not played:
            try:
                uri = file_path.replace("\\", "/")
                subprocess.run(
                    [
                        "powershell",
                        "-NoProfile",
                        "-Command",
                        f"Add-Type -AssemblyName PresentationCore;"
                        f"$p=New-Object System.Windows.Media.MediaPlayer;"
                        f"$p.Open([Uri]'file:///{uri}');"
                        f"$p.Play();"
                        f"Start-Sleep 10",
                    ],
                    timeout=15,
                )
                played = True
            except Exception as e:
                print(f"[speakWord] PS MediaPlayer error: {e}")

        # Windows Media Player COM
        if not played:
            try:
                subprocess.run(
                    [
                        "powershell",
                        "-NoProfile",
                        "-Command",
                        f"$wm=New-Object -ComObject WMPlayer.OCX;"
                        f"$wm.URL='{file_path}';"
                        f"$wm.controls.play();"
                        f"Start-Sleep 10;"
                        f"$wm.close()",
                    ],
                    timeout=15,
                )
                played = True
            except Exception as e:
                print(f"[speakWord] WMP error: {e}")

        if not played:
            print("[speakWord] all playback methods failed", file_path)

        QMetaObject.invokeMethod(
            self, "_finishPlayback", QtCoreQt.QueuedConnection, Q_ARG(int, seq)
        )

    @Slot(int)
    def _finishPlayback(self, seq):
        if seq != self._play_seq:
            return
        self._speaking = False
        self.speakingChanged.emit()

    def _ai_intro_thread(self, topic):
        response = self._ai_service.get_intro(topic)
        QMetaObject.invokeMethod(
            self, "_finishAiResponse",
            QtCoreQt.QueuedConnection,
            Q_ARG(str, response),
        )

    @Slot(str, str)
    def aiChat(self, topic, message):
        self._ai_loading = True
        self.aiLoadingChanged.emit()
        threading.Thread(
            target=self._ai_chat_thread,
            args=(topic, message),
            daemon=True,
        ).start()

    def _ai_chat_thread(self, topic, message):
        response = self._ai_service.chat(topic, message)
        QMetaObject.invokeMethod(
            self, "_finishAiResponse",
            QtCoreQt.QueuedConnection,
            Q_ARG(str, response),
        )

    @Slot(str)
    def _finishAiResponse(self, response):
        self._current_ai_response = response
        self._ai_loading = False
        self.aiLoadingChanged.emit()
        self.aiResponseChanged.emit(self._current_ai_response)
