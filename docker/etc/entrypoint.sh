#!/bin/sh

chown -R $GOSU_USER /lede

# If GOSU_USER environment variable set to something other than 0:0 (root:root),
# become user:group set within and exec command passed in args
if [ "$GOSU_USER" != "0:0" ]; then
    # make sure a valid user exists in /etc/passwd
    if grep "^builder:" /etc/passwd; then
      sed -i "/^builder:/d" /etc/passwd
    fi
    echo "builder:x:$GOSU_USER:LEDE builder:/lede:/bin/bash" >> /etc/passwd
    exec /usr/local/bin/gosu $GOSU_USER "$@"
fi

# If GOSU_USER was 0:0 exec command passed in args without gosu (assume already root)
exec "$@"

