#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

xcodegen generate

/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project CBORGUsageMonitor.xcodeproj \
  -scheme CBORGUsageMonitor \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
