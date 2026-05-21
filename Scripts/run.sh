#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

./Scripts/build.sh

APP_PATH="$(find "$HOME/Library/Developer/Xcode/DerivedData" -path '*CBORGUsageMonitor.app' -type d | sort | tail -1)"
if [[ -z "$APP_PATH" ]]; then
  echo "CBORGUsageMonitor.app was not found in DerivedData."
  exit 1
fi

WIDGET_PATH="$APP_PATH/Contents/PlugIns/CBORGUsageMonitorWidgetExtension.appex"
if [[ ! -d "$WIDGET_PATH" ]]; then
  echo "CBORGUsageMonitorWidgetExtension.appex was not found in the app bundle."
  exit 1
fi

codesign --force --sign - --timestamp=none \
  --entitlements CBORGUsageMonitorWidgetExtension/CBORGUsageMonitorWidgetExtension.entitlements \
  "$WIDGET_PATH"
codesign --force --sign - --timestamp=none \
  --entitlements CBORGUsageMonitor/CBORGUsageMonitor.entitlements \
  "$APP_PATH"

pluginkit -a "$WIDGET_PATH"

if pgrep -x CBORGUsageMonitor >/dev/null; then
  pkill -x CBORGUsageMonitor
  sleep 1
fi

if [[ -n "${CBORG_API_KEY:-}" ]]; then
  launchctl setenv CBORG_API_KEY "$CBORG_API_KEY"
  open "$APP_PATH"
  sleep 2
  launchctl unsetenv CBORG_API_KEY
else
  open "$APP_PATH"
fi

echo "Opened $APP_PATH"
echo "If needed, open Notification Center > Edit Widgets and search for CBORG Usage."
