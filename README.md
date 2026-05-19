# CBORG Usage Monitor

Native macOS menu bar app and WidgetKit widget for the CBORG `/user/info` usage endpoint.

## What it does

- Saves the CBORG API key in macOS Keychain.
- Polls `https://api.cborg.lbl.gov/user/info` from the menu bar app.
- Caches sanitized usage in the app group `group.dev.local.CBORGUsageMonitor`.
- Shows budget percent, spend, reset date, and key alias in the app and widget.
- Keeps the widget keyless; the widget only reads the cached snapshot.

## Run

```bash
cd CBORGUsageMonitor
./Scripts/run.sh
```

If `CBORG_API_KEY` is set when `Scripts/run.sh` launches the app, the app imports it into Keychain on first launch. Otherwise, paste it once in the app and click **Save Key**.

## Widget

After `Scripts/run.sh` finishes, open Notification Center, choose **Edit Widgets**, and search for **CBORG Usage**.
