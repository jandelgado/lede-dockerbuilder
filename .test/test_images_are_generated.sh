#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/test-common" "$@"

FILES=$(find "$DIR" -type f \( -name "$PREFIX-*.img.gz" -o -name "$PREFIX-*.bin" \) | wc -l)

if (( FILES == 0 )); then
    fail "no images found for prefix '$PREFIX'"
    dump_context
    echo "files in $DIR:"
    ls "$DIR" 2>/dev/null || echo "(directory empty or missing)"
fi

exit $FAIL
