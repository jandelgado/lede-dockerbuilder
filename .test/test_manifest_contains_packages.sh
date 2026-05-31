#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/test-common" "$@"

MANIFEST="$DIR/$PREFIX.manifest"

if [ ! -f "$MANIFEST" ]; then
    fail "manifest not found: $MANIFEST"
    dump_context
    exit 1
fi

for p in $LEDE_PACKAGES; do
    [[ $p == -* ]] && continue
    grep -q -E "^$p " "$MANIFEST" || fail "package not in manifest: $p"
done

if (( FAIL )); then
    dump_context
    echo "manifest:"
    cat "$MANIFEST"
fi

exit $FAIL
