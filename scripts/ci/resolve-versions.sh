#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

vlc_input="${VLC_VERSION_INPUT:-latest-3}"

latest_vlc_3() {
  local tmp
  tmp="$(mktemp)"
  curl -fsSL 'https://download.videolan.org/pub/videolan/vlc/' >"$tmp"
  python3 - "$tmp" <<'PY'
import re
import sys

text = open(sys.argv[1], encoding="utf-8", errors="ignore").read()
versions = sorted(
    set(re.findall(r'href="(3\.0\.[0-9.]+)/"', text)),
    key=lambda s: tuple(int(part) for part in s.split(".")),
)
if not versions:
    raise SystemExit("could not resolve latest VLC 3 release")
print(versions[-1])
PY
  rm -f "$tmp"
}

resolve_value() {
  local input="$1"
  local resolver="$2"
  if [[ "$input" == latest-* ]]; then
    "$resolver"
  else
    printf '%s\n' "$input"
  fi
}

vlc_version="$(resolve_value "$vlc_input" latest_vlc_3)"

require_vlc_release_version "$vlc_version"

log "vlc_version=$vlc_version"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "vlc_version=$vlc_version" >>"$GITHUB_OUTPUT"
else
  printf 'vlc_version=%s\n' "$vlc_version"
fi
