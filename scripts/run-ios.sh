#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -n "${PETFRIENDLY_FLUTTER_BIN:-}" ]]; then
  task_flutter="$PETFRIENDLY_FLUTTER_BIN"
elif command -v flutter >/dev/null 2>&1; then
  task_flutter="$(command -v flutter)"
else
  task_flutter="$HOME/.cache/petfriendly/flutter/bin/flutter"
fi
if [[ ! -x "$task_flutter" ]]; then
  echo 'Flutter SDK not found. Set PETFRIENDLY_FLUTTER_BIN to the flutter executable.' >&2
  exit 1
fi
if [[ -n "${PETFRIENDLY_SIMULATOR_ID:-}" ]]; then
  task_device="$PETFRIENDLY_SIMULATOR_ID"
else
  task_device="$(xcrun simctl list devices available --json | python3 -c 'import json,sys; devices=[d for group in json.load(sys.stdin)["devices"].values() for d in group if d["name"].startswith("iPhone")]; booted=[d for d in devices if d["state"]=="Booted"]; print((booted or devices)[0]["udid"] if devices else "")')"
fi
if [[ -z "$task_device" ]]; then
  echo 'No available iPhone simulator. Install an iOS runtime in Xcode.' >&2
  exit 1
fi
if ! xcrun simctl list devices booted --json | python3 -c 'import json,sys; target=sys.argv[1]; sys.exit(0 if any(d["udid"]==target for group in json.load(sys.stdin)["devices"].values() for d in group) else 1)' "$task_device"; then
  xcrun simctl boot "$task_device"
fi
open -a Simulator
xcrun simctl bootstatus "$task_device" -b
task_config="${PETFRIENDLY_CONFIG:-}"
if [[ -n "$task_config" ]]; then
  exec "$task_flutter" run -d "$task_device" --dart-define-from-file="$task_config"
else
  exec "$task_flutter" run -d "$task_device"
fi
