#!/bin/sh
set -e


# If GOSU_UID:GOSU_GID environment variable set to something other than 0:0 (root:root),
# become user:group set within and exec command passed in args
if [ "$GOSU_UID:$GOSU_GID" != "0:0" ] && [ "$GOSU_UID:$GOSU_GID" != ":" ]; then
    export HOME="/lede"

    chown "$GOSU_UID:$GOSU_GID" /lede
    chown "$GOSU_UID:$GOSU_GID" /lede/*

    # only needed when run with docker
    if [ -f /.dockerenv ]; then
        echo hello
#        chown -R "$GOSU_UID:$GOSU_GID" /lede
    fi
    groupadd -f -g "$GOSU_GID" builder
    useradd -u "$GOSU_UID" -g "$GOSU_GID" -s /bin/bash -d "/lede" builder || :
    exec chroot --userspec "$GOSU_UID:$GOSU_GID" --skip-chdir / "$@"
fi

# If GOSU_UID:GOSU_GID was 0:0 exec command passed in args
# without gosu (assume already root)
exec "$@"

