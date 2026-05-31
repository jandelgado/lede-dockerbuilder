#!/bin/bash
# run all tests for a given configuration. tests are run after images are
# built. we do some simple assertions on the generated artifacts to e.g. make
# sure the configured packages are included etc.
set -eou pipefail

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if (( $# != 2 )); then
    echo "Usage: $(basename "$0") <configuration> <output-directory>"
    echo "Example: $(basename "$0") example-x86_64.conf output"
    exit 1
fi

CONF=$1
OUT=$2
PASSED=0
FAILED=0

if ! source "$CONF" 2>/dev/null; then
    echo "ERROR: cannot load configuration: $CONF"
    exit 1
fi

echo "======================================================================"
echo " TEST RESULTS  $CONF in $OUT"
echo "======================================================================"

for t in "$SCRIPT_DIR"/test_*.sh; do
    name=$(basename "$t" .sh | sed 's/^test_//')
    if output=$("$t" "$CONF" "$OUT" 2>&1); then
        echo "  [ PASS ] $name"
        PASSED=$(( PASSED + 1 ))
    else
        echo "  [ FAIL ] $name"
        echo "$output" | sed 's/^/             /'
        FAILED=$(( FAILED + 1 ))
    fi
done

total=$(( PASSED + FAILED ))
echo "----------------------------------------------------------------------"
echo " $total tests: $PASSED passed, $FAILED failed"
echo "======================================================================"
[[ $FAILED -eq 0 ]] || exit 1
