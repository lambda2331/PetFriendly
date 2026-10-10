#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
task_platform="${1:-ios}"
case "$task_platform" in
  ios|android) ;;
  *) echo 'Usage: scripts/run-configured.sh ios|android [device-id]' >&2; exit 1 ;;
esac
task_config="${PETFRIENDLY_CONFIG:-config/app.$task_platform.local.json}"
python3 scripts/configure_services.py check --platform "$task_platform" --config "$task_config"
if [[ "$task_platform" == ios ]]; then
  export PETFRIENDLY_CONFIG="$task_config"
  if [[ -n "${2:-}" ]]; then export PETFRIENDLY_SIMULATOR_ID="$2"; fi
  exec ./scripts/run-ios.sh
fi
if [[ -n "${PETFRIENDLY_FLUTTER_BIN:-}" ]]; then
  task_flutter="$PETFRIENDLY_FLUTTER_BIN"
elif command -v flutter >/dev/null 2>&1; then
  task_flutter="$(command -v flutter)"
else
  task_flutter="$HOME/.cache/petfriendly/flutter/bin/flutter"
fi
export ANDROID_HOME="${ANDROID_HOME:-$HOME/.cache/petfriendly/android-sdk}"
exec "$task_flutter" run -d "${2:-emulator-5554}" --dart-define-from-file="$task_config"
