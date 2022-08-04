#!/bin/bash
source $1
DIR=$2  # e.g. output/
FAIL=0

fail() {
    echo "  ERROR: $*"
    FAIL=1
}

PREFIX="openwrt-$LEDE_RELEASE-$LEDE_TARGET-$LEDE_SUBTARGET-$LEDE_PROFILE"

echo "Test if images are generated for $PREFIX ..."

FILES=$(find "$DIR"  -type f -name "$PREFIX-*.img.gz" | wc -l)

[ "$FILES" -eq "0" ] && fail "no images were built for $PREFIX"

exit $FAIL
