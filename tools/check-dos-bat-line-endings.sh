#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

bad=0
for file in dos/*.BAT; do
    if LC_ALL=C awk 'index($0, "\r") != length($0) { exit 1 }' "$file"; then
        :
    else
        printf '%s: expected CRLF line endings\n' "$file" >&2
        bad=1
    fi
done

exit "$bad"
