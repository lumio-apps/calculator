<p align="center">
  <img src="docs/logo.png" alt="Calnote logo" width="120">
</p>

<h1 align="center">Calnote</h1>

<p align="center">
  Calendar and notes in one simple, offline app for Android and Windows.<br>
  Tap any date to see or write notes for that day.
</p>

<p align="center">
  <a href="https://github.com/lumio-apps/calnote/actions/workflows/build-apk.yml"><img src="https://github.com/lumio-apps/calnote/actions/workflows/build-apk.yml/badge.svg" alt="Build APK"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-0F766E.svg" alt="MIT license"></a>
  <a href="https://github.com/lumio-apps/calnote/releases"><img src="https://img.shields.io/github/v/release/lumio-apps/calnote?color=0F766E" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20Windows-0F766E.svg" alt="Android and Windows">
</p>

## Screenshots

<p align="center">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/1.png" alt="Calendar with a dot on days that have notes" width="250">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/2.png" alt="List of all notes with colours, checklists and tags" width="250">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/3.png" alt="Menu with backup, theme and update check" width="250">
</p>

## Features

- **Calendar first:** monthly and weekly views, with a dot on every day that has notes
- **Day view:** a week strip and a quick-add box for fast notes
- **Notes without a date:** a separate tab for ideas and lists that do not belong to a day
- **Rich notes:** title, text or checklist, colour, tags and pinning
- **Repeating notes:** every day, week, month or year (bills, birthdays, habits)
- **Backup and restore:** export all notes to one file and import them on another phone
- **Share:** send any note as plain text
- **Search, archive and trash**
- **Light, dark and system theme**
- **Check for updates:** one tap in the menu tells you if a newer version is out
- **Works on Windows too:** a wide layout with a sidebar, a large month calendar that shows note titles, and a day panel. Keyboard shortcuts: Ctrl+N for a new note, Ctrl+F to search.
- **Private by design:** everything is stored on your device. No account, no ads, no tracking.

## Download

### Android

Get the latest APK from the [Releases page](https://github.com/lumio-apps/calnote/releases). Each release has three APK files:

| File name ends with | Use it for |
| --- | --- |
| `arm64-v8a.apk` | Almost every phone made since 2017. Pick this one if unsure. |
| `armeabi-v7a.apk` | Older 32-bit phones |
| `x86_64.apk` | Emulators and a few tablets |

To update, install the new APK over the old one. Your notes are kept. You can also use **Check for updates** in the app menu, which picks the right file for you.

### Windows

1. On the [Releases page](https://github.com/lumio-apps/calnote/releases), download the file ending in `windows-x64.zip`.
2. Right-click the zip, choose **Extract All**, and pick a folder (for example `Documents\Calnote`).
3. Open the folder and run `calnote.exe`. Keep all the other files in the same folder; the app needs them.

Windows may show "Windows protected your PC" the first time, because the app is new and not signed with a paid certificate. Click **More info**, then **Run anyway**.

Works on 64-bit Windows 10 and 11. Your notes are stored in `%APPDATA%\Lumio Apps\Calnote`, separate from the app folder.

To update: close Calnote, extract the new zip into the same folder and replace the old files. Your notes are kept. **Check for updates** in the app links straight to the new Windows zip.

### Coming from 0.3.x (Android)

Version 0.4.0 is signed with a new private key, so it cannot be installed over 0.3.x. Do this once: **Export backup** in the old app, uninstall it, install the new one, then **Import backup**.

## Privacy

Calnote does not collect any data. Your notes live in a local database on your device and never leave it. Use **Export backup** to keep a copy.

The app uses the internet for one thing only: when you tap **Check for updates**, it asks GitHub for the newest version number. Nothing about you or your notes is sent. The app never connects on its own, and it never downloads or installs anything by itself.

## Build it yourself

Requirements: [Flutter](https://docs.flutter.dev/get-started/install) (stable channel), plus the Android SDK for Android or Visual Studio with "Desktop development with C++" for Windows.

```bash
# Generate the android/ folder once
flutter create --platforms=android --org io.github.lumio_apps --project-name calnote .

flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter build apk --release --split-per-abi

# Windows (run on a Windows PC)
flutter build windows --release
```

The Windows app ends up in `build\windows\x64\runner\Release`.

`flutter create` only adds the `android/` folder. Your code in `lib/` is not changed. Add the internet permission to `android/app/src/main/AndroidManifest.xml` so the update check works (the GitHub workflow does this for you):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Official releases are built by [GitHub Actions](.github/workflows/build-apk.yml) from tagged commits and signed with the maintainer's private release key, which is stored as an encrypted repository secret. APKs you build yourself are signed with your own key, so they cannot be installed over an official release.

## Project structure

```
lib/
  main.dart              app entry point
  app_info.dart          version and links
  theme.dart             colours and note colours
  models/                Note model
  data/                  SQLite database, app state, backup, update check
  screens/               calendar, day view, editor, lists, search,
                         desktop_shell.dart (wide layout for Windows and tablets)
  widgets/               note card, drawer, dialogs, helpers
fastlane/                store listing text, icon and screenshots
```

## Releasing a new version

1. Raise the version in `pubspec.yaml` (both parts, for example `0.6.1+10`) and in `lib/app_info.dart`.
2. Add the changes to `CHANGELOG.md`.
3. Run `flutter analyze`.
4. Push, wait for a green build, then tag: `git tag v0.6.1` and `git push origin v0.6.1`. The release gets the three APKs and the Windows zip.

## Roadmap

- Automatic backups
- Home screen widget
- Hindi and other languages

Ideas and bug reports are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).

Part of [Lumio Apps](https://github.com/lumio-apps).
