import json
import uuid
import winsound
from datetime import datetime, timezone

from PySide6.QtCore import Property, QObject, QSettings, QTimer, Signal, Slot


class NotesController(QObject):
    notesChanged = Signal()
    reminderDue = Signal(str, str, str)  # note_id, text, reminder_at

    def __init__(self):
        super().__init__()
        self._settings = QSettings("VIEEdu", "VIEEdu")
        raw = self._settings.value("notes", "[]", type=str)
        self._notes = json.loads(raw)
        self._timer = QTimer(self)
        self._timer.timeout.connect(self._check_reminders)
        self._timer.start(30000)

    def _save(self):
        self._settings.setValue("notes", json.dumps(self._notes, ensure_ascii=False))
        self.notesChanged.emit()

    @Property("QVariantList", notify=notesChanged)
    def notes(self):
        return self._notes

    @Slot(str, str)
    def addNote(self, text, reminder_at=""):
        note = {
            "id": str(uuid.uuid4()),
            "text": text,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "completed": False,
            "reminder_at": reminder_at,
        }
        self._notes.insert(0, note)
        self._save()

    @Slot(str)
    def toggleNote(self, note_id):
        for note in self._notes:
            if note["id"] == note_id:
                note["completed"] = not note["completed"]
                self._save()
                return

    @Slot(str)
    def deleteNote(self, note_id):
        self._notes = [n for n in self._notes if n["id"] != note_id]
        self._save()

    @Slot(str, str, str)
    def updateNote(self, note_id, new_text, reminder_at=""):
        for note in self._notes:
            if note["id"] == note_id:
                note["text"] = new_text
                note["reminder_at"] = reminder_at
                self._save()
                return

    def _check_reminders(self):
        now = datetime.now(timezone.utc)
        changed = False
        for note in self._notes:
            if note.get("completed"):
                continue
            reminder_str = note.get("reminder_at", "")
            if not reminder_str:
                continue
            try:
                # Chuẩn hoá: "Z" → "+00:00" cho Python < 3.11
                reminder_dt = datetime.fromisoformat(
                    reminder_str.replace("Z", "+00:00")
                )
                # Nếu reminder naive (không có tzinfo) thì gán UTC
                if reminder_dt.tzinfo is None:
                    reminder_dt = reminder_dt.replace(tzinfo=timezone.utc)

                if reminder_dt <= now:
                    note["reminder_at"] = ""
                    changed = True
                    winsound.PlaySound("SystemAsterisk", winsound.SND_ALIAS | winsound.SND_ASYNC)
                    self.reminderDue.emit(note["id"], note["text"], reminder_str)
            except ValueError:
                pass

        if changed:
            self._save()
