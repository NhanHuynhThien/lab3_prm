#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
SDK_DIR="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
AVD_NAME=TokenLedger_Pixel_10_Pro_120Hz
DEVICE_ID=emulator-5554
if ! "$SDK_DIR/platform-tools/adb" -s "$DEVICE_ID" get-state >/dev/null 2>&1; then
  "$SDK_DIR/emulator/emulator" -avd "$AVD_NAME" -gpu host -feature -Vulkan -no-snapshot-load > /tmp/tokenledger-pixel10-120hz.log 2>&1 &
fi
"$SDK_DIR/platform-tools/adb" -s "$DEVICE_ID" wait-for-device
for attempt in {1..60}; do
  [[ $("$SDK_DIR/platform-tools/adb" -s "$DEVICE_ID" shell getprop sys.boot_completed | tr -d '\r') == 1 ]] && break
  sleep 1
done
"$SDK_DIR/platform-tools/adb" -s "$DEVICE_ID" shell settings put system peak_refresh_rate 120.0
"$SDK_DIR/platform-tools/adb" -s "$DEVICE_ID" shell settings put system min_refresh_rate 120.0
"$SDK_DIR/platform-tools/adb" -s "$DEVICE_ID" reverse tcp:8787 tcp:8787
flutter run --profile -d "$DEVICE_ID" --dart-define-from-file=.env.local
