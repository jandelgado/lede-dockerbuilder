#!/bin/sh

# only needed in docker, not rootless podman.
if [ -f /.dockerenv ]; then
    # this is very, very slow inside a docker container.
    chown -R "$GOSU_UID:$GOSU_GID" /lede
fi

# If GOSU_UID:GOSU_GID environment variable set to something other than 0:0 (root:root),
# become user:group set within and exec command passed in args
if [ "$GOSU_UID:$GOSU_GID" != "0:0" ]; then
    # make sure a valid user exists in /etc/passwd
    sed -i "/^builder:/d" /etc/passwd || true
    echo "builder:x:$GOSU_UID:$GOSU_GID:LEDE builder:/lede:/bin/bash" >> /etc/passwd
    sed -i "/^builder:/d" /etc/group || true
    echo "builder:x:$GOSU_GID" >> /etc/group
    exec su-exec "$GOSU_UID:$GOSU_GID" "$@"
fi

# If GOSU_UID:GOSU_GID was 0:0 exec command passed in args without gosu (assume already root)
exec "$@"

