from PySide6.QtCore import Property, QObject, QSettings, Signal, Slot
from sysinfo import personalizaion


class SettingsController(QObject):
    themeModeChanged = Signal()
    accentModeChanged = Signal()
    customAccentChanged = Signal()
    primaryModeChanged = Signal()
    customPrimaryChanged = Signal()
    secondaryModeChanged = Signal()
    customSecondaryChanged = Signal()
    settingsChanged = Signal()

    _COLOR_PRESETS = [
        "#1565C0",  # Blue
        "#2E7D32",  # Green
        "#E65100",  # Orange
        "#6A1B9A",  # Purple
        "#C62828",  # Red
        "#00838F",  # Cyan
        "#AD1457",  # Pink
        "#37474F",  # Blue Grey
    ]

    def __init__(self):
        super().__init__()
        self._settings = QSettings("VIEEdu", "VIEEdu")

        self._theme_mode = self._settings.value("theme_mode", 0, type=int)
        self._accent_mode = self._settings.value("accent_mode", 0, type=int)
        self._custom_accent = self._settings.value("custom_accent", self._COLOR_PRESETS[0], type=str)
        self._primary_mode = self._settings.value("primary_mode", 0, type=int)
        self._custom_primary = self._settings.value("custom_primary", self._COLOR_PRESETS[0], type=str)
        self._secondary_mode = self._settings.value("secondary_mode", 0, type=int)
        self._custom_secondary = self._settings.value("custom_secondary", self._COLOR_PRESETS[4], type=str)

    # ── Theme ────────────────────────────────────────────

    @Property(int, notify=themeModeChanged)
    def themeMode(self):
        return self._theme_mode

    @themeMode.setter
    def themeMode(self, value):
        if value != self._theme_mode:
            self._theme_mode = value
            self._settings.setValue("theme_mode", value)
            self.themeModeChanged.emit()
            self.settingsChanged.emit()

    # ── Accent ───────────────────────────────────────────

    @Property(int, notify=accentModeChanged)
    def accentMode(self):
        return self._accent_mode

    @accentMode.setter
    def accentMode(self, value):
        if value != self._accent_mode:
            self._accent_mode = value
            self._settings.setValue("accent_mode", value)
            self.accentModeChanged.emit()
            self.settingsChanged.emit()

    @Property(str, notify=customAccentChanged)
    def customAccent(self):
        return self._custom_accent

    @customAccent.setter
    def customAccent(self, value):
        if value != self._custom_accent:
            self._custom_accent = value
            self._settings.setValue("custom_accent", value)
            self.customAccentChanged.emit()
            self.settingsChanged.emit()

    # ── Primary ──────────────────────────────────────────

    @Property(int, notify=primaryModeChanged)
    def primaryMode(self):
        return self._primary_mode

    @primaryMode.setter
    def primaryMode(self, value):
        if value != self._primary_mode:
            self._primary_mode = value
            self._settings.setValue("primary_mode", value)
            self.primaryModeChanged.emit()
            self.settingsChanged.emit()

    @Property(str, notify=customPrimaryChanged)
    def customPrimary(self):
        return self._custom_primary

    @customPrimary.setter
    def customPrimary(self, value):
        if value != self._custom_primary:
            self._custom_primary = value
            self._settings.setValue("custom_primary", value)
            self.customPrimaryChanged.emit()
            self.settingsChanged.emit()

    # ── Secondary ────────────────────────────────────────

    @Property(int, notify=secondaryModeChanged)
    def secondaryMode(self):
        return self._secondary_mode

    @secondaryMode.setter
    def secondaryMode(self, value):
        if value != self._secondary_mode:
            self._secondary_mode = value
            self._settings.setValue("secondary_mode", value)
            self.secondaryModeChanged.emit()
            self.settingsChanged.emit()

    @Property(str, notify=customSecondaryChanged)
    def customSecondary(self):
        return self._custom_secondary

    @customSecondary.setter
    def customSecondary(self, value):
        if value != self._custom_secondary:
            self._custom_secondary = value
            self._settings.setValue("custom_secondary", value)
            self.customSecondaryChanged.emit()
            self.settingsChanged.emit()

    # ── Resolvers ────────────────────────────────────────

    @Slot(result=str)
    def resolveAccent(self):
        if self._accent_mode == 1:
            return self._custom_accent
        return personalizaion.accent_color()

    @Slot(result=str)
    def resolvePrimary(self):
        if self._primary_mode == 1:
            return self._custom_primary
        return self.resolveAccent()

    @Slot(result=str)
    def resolveSecondary(self):
        if self._secondary_mode == 1:
            return self._custom_secondary
        return self.resolveAccent()

    @Slot(result=bool)
    def resolveDark(self):
        if self._theme_mode == 1:
            return False
        if self._theme_mode == 2:
            return True
        return personalizaion.is_dark_mode()

    @Property(list, constant=True)
    def colorPresets(self):
        return self._COLOR_PRESETS
