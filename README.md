# Glances Client

A minimal, pure-black (AMOLED) monitoring client for the [Glances](https://github.com/nicolargo/glances) system monitoring tool.

**v1.0.0** — a deliberately lean, read-only mobile client.

## Why this exists

Glances has a web UI and can be accessed from a browser, but until now there was no dedicated mobile client that gives you the Glances dashboard in your pocket. This project fills that gap: a native Android app that talks directly to the Glances REST API (`/api/4`) and renders the live dashboard on a battery-friendly pure-black screen.

## Features

- **Live dashboard** — CPU, memory, load average, filesystems and Docker container status at a glance, auto-refreshing every 2 seconds
- **Per-screen views** — dedicated screens for CPU, Memory, Disks, Network and Services (containers), reachable from the bottom navigation bar
- **AMOLED pure-black theme** — a display-only design tuned for OLED panels, with minimal battery drain
- **Server configuration** — connect to any Glances host (`http://`, `https://`, or bare `host:port`), persisted between sessions, with a reset button to switch servers at any time
- **Pull-to-refresh** — force a fresh snapshot whenever you want it
- **Error handling** — clear, retryable error states when the server is unreachable

> **Note:** v1 is intentionally display-only. The dashboard cards are not tappable and there is no per-container or per-process detail view — this keeps v1 a focused, minimal monitoring client. Expanded features are planned for the next release (see below).

## Requirements

- A running [Glances](https://github.com/nicolargo/glances) server (v4 API) reachable from your device
- The Glances server should have the REST API enabled (`glances -w`)

## Installation

Download the latest APK from the [Releases](../../releases) page and install it on your Android device (allow "install from unknown sources" if prompted).

On first launch, enter your Glances server address and tap **Connect**.

## Building from source

```bash
flutter pub get
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Upcoming in the next update

- Per-container and per-process drill-down detail screens
- Tappable dashboard cards that navigate to the matching screen
- Live graphs / history charts
- Process list with sorting and filtering

## License

See [LICENSE](LICENSE).
