#!/bin/bash

source $1
DIR=$2  # e.g. output/
FAIL=0

fail() {
    echo "  ERROR: $*"
    FAIL=1
}

PREFIX="openwrt-$LEDE_RELEASE-$LEDE_TARGET-$LEDE_SUBTARGET-$LEDE_PROFILE"
MANIFEST="$DIR/$PREFIX.manifest"

echo "Test all excluded packages are not in manifest file $MANIFEST..."
if [ ! -f "$MANIFEST" ]; then
    fail "$MANIFEST does not exist"
    exit 1
fi

for p in $LEDE_PACKAGES; do 
    # consider only excluded packages, starting with "-", e.g. "-ppp"
    [[ ! $p == -* ]] && continue
    p=${p:1}
    grep -q -E "^$p " "$MANIFEST" && fail "package not expected to be in manifest: $p"
done

exit $FAIL
