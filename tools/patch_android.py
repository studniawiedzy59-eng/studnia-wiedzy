#!/usr/bin/env python3
"""Adjusts the Android manifest that `flutter create` generates.

1. Lets the app find the phone's text-to-speech engine. Without this entry
   Android 11 and newer hide the engine and words are not spoken.
2. Shows the app name as "Movira" under the icon.

Safe to run more than once. Run from the repository root.
"""
import pathlib
import sys

MANIFEST = pathlib.Path("android/app/src/main/AndroidManifest.xml")
TTS_ACTION = "android.intent.action.TTS_SERVICE"
TTS_INTENT = f"""
        <intent>
            <action android:name="{TTS_ACTION}"/>
        </intent>"""


def main():
    if not MANIFEST.exists():
        print(f"{MANIFEST} not found")
        return 1
    text = MANIFEST.read_text(encoding="utf-8")

    if TTS_ACTION not in text:
        if "<queries>" in text:
            text = text.replace("<queries>", "<queries>" + TTS_INTENT, 1)
        elif "</manifest>" in text:
            block = f"    <queries>{TTS_INTENT}\n    </queries>\n"
            text = text.replace("</manifest>", block + "</manifest>", 1)
        else:
            print("manifest has no <queries> and no </manifest>")
            return 1

    text = text.replace('android:label="movira"', 'android:label="Movira"')
    if 'android:label="Movira"' not in text:
        print("could not set the app label")
        return 1

    MANIFEST.write_text(text, encoding="utf-8")
    print("manifest patched")
    return 0


if __name__ == "__main__":
    sys.exit(main())
