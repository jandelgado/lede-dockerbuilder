#!/bin/sh

chown -R $GOSU_USER /lede

# If GOSU_USER environment variable set to something other than 0:0 (root:root),
# become user:group set within and exec command passed in args
if [ "$GOSU_USER" != "0:0" ]; then
    exec gosu $GOSU_USER "$@"
fi

# If GOSU_USER was 0:0 exec command passed in args without gosu (assume already root)
exec "$@"

