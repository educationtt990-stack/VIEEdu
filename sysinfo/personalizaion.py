import colorsys
import winreg

def is_dark_mode():
    try:
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        )
        value, _ = winreg.QueryValueEx(key, "AppsUseLightTheme")
        return value == 0
    except:
        return False


def get_accent_rgb():
    key_path = r"Software\Microsoft\Windows\DWM"
    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path) as key:
        value, _ = winreg.QueryValueEx(key, "ColorizationColor")

    r = (value >> 16) & 0xFF
    g = (value >> 8) & 0xFF
    b = value & 0xFF
    return r, g, b


def adjust_accent_for_theme(r, g, b, dark_mode):
    # normalize
    r_, g_, b_ = r/255, g/255, b/255

    # RGB → HLS (note: Python dùng HLS, không phải HSL)
    h, l, s = colorsys.rgb_to_hls(r_, g_, b_)

    if dark_mode:
        # dark theme → tăng lightness để nổi bật
        l = max(l, 0.55)
        s = min(s * 1.1, 1.0)
    else:
        # light theme → giảm lightness để không chói
        l = min(l, 0.45)
        s = min(s * 1.0, 1.0)

    r2, g2, b2 = colorsys.hls_to_rgb(h, l, s)

    return int(r2*255), int(g2*255), int(b2*255)


def accent_color():
    r, g, b = get_accent_rgb()
    dark = is_dark_mode()

    r, g, b = adjust_accent_for_theme(r, g, b, dark)

    return "#{:02X}{:02X}{:02X}".format(r, g, b)