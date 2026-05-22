import os
import sys

from PySide6.QtCore import Qt
from PySide6.QtGui import QAction, QColor, QIcon, QPainter, QPixmap
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication, QMenu, QSystemTrayIcon

import resources
from controller.pages import english
from controller.pages.math import MathController
from controller.pages.notes import NotesController
from controller.pages.settings import SettingsController

os.environ["QML_XHR_ALLOW_FILE_READ"] = "1"
os.environ["QT_ENABLE_HIGHDPI_SCALING"] = "1"
os.environ["QT_AUTO_SCREEN_SCALE_FACTOR"] = "1"

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setOrganizationName("VIEEdu")
    app.setApplicationName("VIEEdu")
    app.setQuitOnLastWindowClosed(False)  # prevent quit when window hides
    engine = QQmlApplicationEngine()

    # Keep strong references to prevent GC from collecting PySide6 objects
    engine._keepers = []

    englishController = english.EnglishController()
    engine.rootContext().setContextProperty("englishController", englishController)
    engine._keepers.append(englishController)

    settingsController = SettingsController()
    engine.rootContext().setContextProperty("settingsController", settingsController)
    engine._keepers.append(settingsController)

    mathController = MathController()
    engine.rootContext().setContextProperty("mathController", mathController)
    engine._keepers.append(mathController)

    notesController = NotesController()
    engine.rootContext().setContextProperty("notesController", notesController)
    engine._keepers.append(notesController)

    def update_context():
        ctx = engine.rootContext()
        ctx.setContextProperty("isDark", settingsController.resolveDark())
        ctx.setContextProperty("accentColor", settingsController.resolveAccent())

    update_context()
    settingsController.settingsChanged.connect(update_context)

    engine.load(os.path.join(str(os.path.dirname(__file__)), "qml/main.qml"))

    if not engine.rootObjects():
        sys.exit(-1)

    window = engine.rootObjects()[0]

    # ── System tray ──────────────────────────────────────
    icon_path = os.path.join(os.path.dirname(__file__),
                             "images/icon/favicon.png")
    tray_icon = QIcon(icon_path)
    if tray_icon.isNull():
        pm = QPixmap(32, 32)
        pm.fill(Qt.GlobalColor.transparent)
        p = QPainter(pm)
        p.setBrush(QColor("#1565C0"))
        p.setPen(Qt.PenStyle.NoPen)
        p.drawRoundedRect(0, 0, 32, 32, 6, 6)
        p.setPen(QColor("white"))
        p.setFont(p.font())
        p.drawText(pm.rect(), Qt.AlignmentFlag.AlignCenter, "V")
        p.end()
        tray_icon = QIcon(pm)

    tray = QSystemTrayIcon()
    tray.setIcon(tray_icon)
    tray.setToolTip("VIEEdu")

    tray_menu = QMenu()
    open_action = QAction("Mở")
    tray_menu.addAction(open_action)
    tray_menu.addSeparator()
    exit_action = QAction("Thoát")
    tray_menu.addAction(exit_action)

    tray.setContextMenu(tray_menu)

    # Show/hide tray when window is hidden/shown
    def on_visible_changed(visible):
        if visible:
            tray.hide()
        else:
            tray.show()

    window.visibleChanged.connect(on_visible_changed)

    # Restore from tray
    def show_window():
        window.show()
        window.raise_()
        window.requestActivate()

    open_action.triggered.connect(show_window)

    def on_tray_activated(reason):
        if reason == QSystemTrayIcon.ActivationReason.DoubleClick:
            show_window()

    tray.activated.connect(on_tray_activated)
    exit_action.triggered.connect(app.quit)

    sys.exit(app.exec())
