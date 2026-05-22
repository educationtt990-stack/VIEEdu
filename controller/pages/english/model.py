import asyncio
import os
import tempfile
import uuid

import edge_tts
from openrouter import OpenRouter
from phonemizer import phonemize
from phonemizer.backend.espeak.wrapper import EspeakWrapper

EspeakWrapper.set_library(r"C:\Program Files\eSpeak NG\libespeak-ng.dll")

API_KEY = "OPENROUTER_API_KEY"
MODEL = "qwen/qwen3.7-max"


class PronunciationModel:
    def __init__(self):
        pass

    def generate_ipa(self, text: str):
        return phonemize(
            text,
            language="en-us",
            backend="espeak",
            strip=True,
        )

    async def _gen(self, text, path):
        tts = edge_tts.Communicate(text=text, voice="en-US-AriaNeural")
        await tts.save(path)

    def speak(self, text: str) -> str:
        file_path = os.path.join(tempfile.gettempdir(), f"{uuid.uuid4()}.mp3")

        try:
            asyncio.run(self._gen(text, file_path))
        except Exception as e:
            print(f"[PronunciationModel.speak] edge-tts error: {e}")
            raise

        if not os.path.exists(file_path) or os.path.getsize(file_path) == 0:
            raise RuntimeError(f"TTS generated empty/missing file: {file_path}")

        return file_path


class AIService:
    _SYSTEM_PROMPT_TPL = """You are an AI English tutor for Vietnamese students.

Your role:
- Explain vocabulary, grammar, and pronunciation in simple Vietnamese when needed.
- Provide examples and exercises.
- Correct mistakes gently.
- Answer questions about the current topic.

Current topic: {topic}

Keep responses concise (under 200 words), use simple English, and include Vietnamese explanations where helpful.
Format responses with HTML if it helps readability (<b>, <i>, <br>)."""

    def __init__(self, api_key=API_KEY, model=MODEL):
        self._api_key = api_key
        self._model = model
        self._conversations: dict[str, list[dict]] = {}

    def get_intro(self, topic: str) -> str:
        return self._call_api(
            topic, "Give me a brief introduction and overview of this topic."
        )

    def chat(self, topic: str, message: str) -> str:
        return self._call_api(topic, message)

    def _call_api(self, topic: str, message: str) -> str:
        if topic not in self._conversations:
            self._conversations[topic] = [
                {
                    "role": "system",
                    "content": self._SYSTEM_PROMPT_TPL.format(topic=topic),
                },
            ]
        self._conversations[topic].append({"role": "user", "content": message})

        try:
            with OpenRouter(api_key=self._api_key) as client:
                response = client.chat.send(
                    model=self._model,
                    messages=self._conversations[topic],
                    max_tokens=512,
                )
            reply = response.choices[0].message.content
        except Exception as e:
            reply = f"<b>Error:</b> {e}"

        self._conversations[topic].append({"role": "assistant", "content": reply})
        return reply
