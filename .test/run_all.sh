#!/bin/bash
# run all tests for a given configuration. tests are run after images are
# built. we do some simple assertions on the generated artifiacts to e.g. make
# sure the configured packages are included etc.
set -eou pipefail

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONF=$1
OUT=$2
RC=0

echo "----------------------------------------------------------------------"
echo "run tests for $CONF"
echo "----------------------------------------------------------------------"
for t in "$SCRIPT_DIR"/test_*.sh; do 
    if "$t" "$CONF" "$OUT"; then
        echo "test OK"
    else
        echo "test FAILED"
        RC=1
    fi
done

exit $RC
