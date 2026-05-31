#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/test-common" "$@"

MANIFEST="$DIR/$PREFIX.manifest"

if [ ! -f "$MANIFEST" ]; then
    fail "manifest not found: $MANIFEST"
    dump_context
    exit 1
fi

for p in $LEDE_PACKAGES; do
    [[ $p != -* ]] && continue
    p=${p:1}
    grep -q -E "^$p " "$MANIFEST" && fail "excluded package found in manifest: $p"
done

if (( FAIL )); then
    dump_context
fi

exit $FAIL
