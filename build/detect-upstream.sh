#!/usr/bin/env bash
# Prints the latest stable upstream CirrOS version on stdout (e.g. 0.6.3),
# parsed from the release directories at https://download.cirros-cloud.net/.
# Pre-releases (0.3.1~pre1, 0.5.0_pre4, -rc1...) never match the strict
# X.Y.Z pattern. A release directory only counts once its SHA256SUMS lists the
# x86_64 disk image, so a half-uploaded release is not picked up.
# Runs in the upstream-watch reusable workflow (no KVM needed): keep it
# portable bash + curl + grep + sort only.

set -euo pipefail

BASE='https://download.cirros-cloud.net'
UA='openimages-ci'

listing=$(curl -fsSL -A "$UA" "$BASE/")
if [[ -z "$listing" ]]; then
  echo "::error::could not fetch $BASE/" >&2
  exit 1
fi

versions=$(printf '%s\n' "$listing" \
  | grep -oE 'href="[0-9]+\.[0-9]+\.[0-9]+/"' \
  | sed -E 's#href="([0-9.]+)/"#\1#' \
  | sort -uV -r)

for v in $versions; do
  if curl -fsSL -A "$UA" "$BASE/$v/SHA256SUMS" 2>/dev/null \
      | grep -qE "^[0-9a-f]{64} [ *]?cirros-${v//./\\.}-x86_64-disk\.img$"; then
    printf '%s\n' "$v"
    exit 0
  fi
done

echo "::error::no CirrOS release with an x86_64 disk image found in $BASE/" >&2
exit 1
