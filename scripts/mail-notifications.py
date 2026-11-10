"""Restore Mail's notification preferences without changing other apps."""

import pathlib
import plistlib
import subprocess


# Captured from macOS 27.0.1 with the requested settings selected:
# notifications, desktop, Notification Center, lock screen and badges enabled;
# persistent alerts; default previews; automatic grouping; summaries enabled.
# Apple stores these controls in an undocumented bit field.
MAIL_SETTINGS = {
    "auth": 1,
    "flags": 310378578,
    "content_visibility": 0,
    "grouping": 0,
}


def update(preferences):
    apps = preferences.setdefault("apps", [])
    mail = next((app for app in apps if app.get("bundle-id") == "com.apple.mail"), None)
    if mail is None:
        raise RuntimeError("Open Mail and enable notifications once before rebuilding.")
    changed = any(mail.get(key) != value for key, value in MAIL_SETTINGS.items())
    mail.update(MAIL_SETTINGS)
    return changed


def main():
    modern = pathlib.Path.home() / (
        "Library/Group Containers/group.com.apple.usernoted/Library/Preferences/"
        "group.com.apple.usernoted.plist"
    )
    domain = str(modern.with_suffix("")) if modern.exists() else "com.apple.ncprefs"
    result = subprocess.run(
        ["/usr/bin/defaults", "export", domain, "-"], check=True, capture_output=True
    )
    preferences = plistlib.loads(result.stdout)
    if update(preferences):
        subprocess.run(
            ["/usr/bin/defaults", "import", domain, "-"],
            input=plistlib.dumps(preferences), check=True,
        )
        subprocess.run(["/usr/bin/killall", "usernoted"], check=False)


if __name__ == "__main__":
    main()
