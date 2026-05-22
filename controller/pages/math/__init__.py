import json
import os

from PySide6.QtCore import Property, QObject, Signal, Slot


class MathController(QObject):
    def __init__(self):
        super().__init__()
