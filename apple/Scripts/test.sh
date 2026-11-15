#!/bin/zsh
set -euo pipefail
apple=${0:A:h:h}
env_file="$apple/../.env"
token=""
if [[ -f "$env_file" ]]; then
  token=$(sed -n 's/^SWITCHBOARD_TOKEN=//p' "$env_file" | head -1)
fi
TEST_RUNNER_SWITCHBOARD_TOKEN="$token" xcodebuild \
  -project "$apple/Switchboard.xcodeproj" \
  -scheme "Switchboard macOS" \
  -configuration Debug \
  -derivedDataPath "${SWITCHBOARD_DERIVED_DATA:-$apple/build/tests}" \
  test CODE_SIGNING_ALLOWED=YES "$@"
