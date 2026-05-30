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

echo "Test all configured packages are in manifest file $MANIFEST..."
if [ ! -f "$MANIFEST" ]; then
    fail "$MANIFEST does not exist"
    exit 1
fi

for p in $LEDE_PACKAGES; do
    [[ $p == -* ]] && continue
	grep -q -E "^$p " "$MANIFEST" || fail "package not in manifest: $p"
done

if [ $FAIL -ne 0 ]; then
	echo "======== TEST FAILED ======="
	echo "LEDE_PACKAGES: $LEDE_PACKAGES"
	echo "MANIFEST: $MANIFEST"
	cat "$MANIFEST"
fi

exit $FAIL
