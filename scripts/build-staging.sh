#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
task_platform="${1:-android}"
task_config="${PETFRIENDLY_CONFIG:-config/app.$task_platform.staging.local.json}"
case "$task_platform" in ios|android) ;; *) echo 'Usage: scripts/build-staging.sh ios|android' >&2; exit 1 ;; esac
python3 scripts/configure_services.py check --platform "$task_platform" --config "$task_config" --release
if command -v flutter >/dev/null 2>&1; then task_flutter="$(command -v flutter)"; else task_flutter="$HOME/.cache/petfriendly/flutter/bin/flutter"; fi
if [[ "$task_platform" == android ]]; then
  [[ -f android/key.properties ]] || { echo 'Configure local Android signing first.' >&2; exit 1; }
  export ANDROID_HOME="${ANDROID_HOME:-$HOME/.cache/petfriendly/android-sdk}"
  "$task_flutter" build appbundle --release --dart-define-from-file="$task_config"
  "$task_flutter" build apk --release --dart-define-from-file="$task_config"
else
  # Simulator build only. TestFlight needs an Apple Developer team and signing.
  "$task_flutter" build ios --simulator --debug --dart-define-from-file="$task_config"
fi
