#!/bin/bash
# A container based OpenWRT image builder.
#
# https://github.com/jandelgado/lede-dockerbuilder
#
# (c) Jan Delgado 2017-2021
set -euo pipefail

# base Tag to use for docker imag
IMAGE_TAG=openwrt-imagebuilder
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# may be overridden in the config file
OUTPUT_DIR=$SCRIPT_DIR/output
ROOTFS_OVERLAY=$SCRIPT_DIR/rootfs-overlay
LEDE_DISABLED_SERVICES=
REPOSITORIES_CONF=
PROG=$0

function usage {
    cat<<EOT
Dockerized LEDE/OpenWRT image builder.

Usage: $1 COMMAND CONFIGFILE [OPTIONS]
  COMMAND is one of:
    build-docker-image - build the docker image (run once first)
    profiles  - start container and show avail profiles for current configuration
    build     - start container and build the LEDE/OpenWRT image
    shell     - start shell in docker container
  CONFIGFILE  - configuraton file to use

  OPTIONS:
  -o OUTPUT_DIR       - output directory (default $OUTPUT_DIR)
  --docker-opts OPTS  - additional options to pass to docker run
                        (can occur multiple times)
  -f ROOTFS_OVERLAY   - rootfs-overlay directory (default $ROOTFS_OVERLAY)
  --skip-sudo         - call docker directly, without sudo
  --dockerless        - use podman and buildah instead of docker daemon

  command line options -o, -f override config file settings.

Example:
  # build the builder docker image first
  $PROG build-docker-image example.conf

  # now build the OpenWrt image
  $PROG build example.conf -o output -f myrootfs

  # show available profiles
  $PROG profiles example.conf 

  # mount downloads to host directory during build
  $PROG build example-nexx-wt3020.conf --docker-opts "-v=\$(pwd)/dl:/lede/imagebuilder/dl:z"
EOT
    exit 0
}

# return given file path as absolute path. path to file must exist.
function abspath {
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

# build container and pass in the actual builder to use
function build_docker_image  {
    echo "building docker image $IMAGE_TAG ..."
    # shellcheck disable=2086
    $SUDO $DOCKER_BUILD\
        --build-arg BUILDER_URL="$LEDE_BUILDER_URL" -t "$IMAGE_TAG" docker
}

function run_cmd_in_container {
    local docker_term_opts="-ti"
    [ ! -t 0 ] && docker_term_opts="-i"
    if [ -n "$REPOSITORIES_CONF" ]; then
        conf="$(abspath "$REPOSITORIES_CONF")"
        repositories_volume=(-v "$conf":/lede/imagebuilder/repositories.conf:z)
    else
        repositories_volume=()
    fi

    # shellcheck disable=SC2068 disable=SC2086
    $SUDO $DOCKER_RUN\
        --rm\
		$docker_term_opts \
        -v "$(abspath "$ROOTFS_OVERLAY")":/lede/rootfs-overlay:z \
        -v "$(abspath "$OUTPUT_DIR")":/lede/output:z \
        "${repositories_volume[@]}" \
        ${DOCKER_OPTS[@]} \
        --rm "$IMAGE_TAG" "$@"
}

# run the builder in the container.
function build_lede_image {
    echo "building image for $LEDE_PROFILE ..."
    run_cmd_in_container  make image PROFILE="$LEDE_PROFILE" \
                PACKAGES="$LEDE_PACKAGES" \
                DISABLED_SERVICES="$LEDE_DISABLED_SERVICES" \
                FILES="/lede/rootfs-overlay" \
                BIN_DIR="/lede/output"
}

# show available profiles
function show_profiles {
    run_cmd_in_container make info
}

# run a shell in the container, useful for debugging.
function run_shell {
    run_cmd_in_container bash
}

# print message and exit
function fail {
    echo "ERROR: $*" >&2
    exit 1
}

if [ $# -lt 2 ]; then
    usage "$0"
    exit 1
fi

COMMAND=$1; shift
CONFIG_FILE=$1; shift

# default: use docker
SUDO=sudo
DOCKER_BUILD="docker build"
DOCKER_RUN="docker run -e GOSU_UID=$(id -ur) -e GOSU_GID=$(id -g)"
DOCKER_OPTS=()

# pull in config file, making $BASEDIR_CONFIG_FILE available inside`
[ ! -f "$CONFIG_FILE" ] && fail "can not open $CONFIG_FILE"
# shellcheck disable=SC2034
BASEDIR_CONFIG_FILE=$( cd "$( dirname "$CONFIG_FILE" )" && pwd )
eval "$(cat "$CONFIG_FILE")"

# if macos skip sudo
if [ "$(uname)" == "Darwin" ]; then
    SUDO=""
fi


# parse cli args, can override config file params
while [[ $# -ge 1 ]]; do
    key="$1"
    case $key in
        -f)
            ROOTFS_OVERLAY="$2"; shift ;;
        -o)
            OUTPUT_DIR="$2"; shift ;;
        --skip-sudo)
            SUDO="" ;;
        --docker-opts) 
            DOCKER_OPTS+=("$2"); shift ;;
        --dockerless)
            SUDO=""
            DOCKER_BUILD="buildah bud --layers=true"
            DOCKER_RUN="podman run" ;;
        *)
            fail "invalid option: $key";;
    esac
    shift
done

mkdir -p "$OUTPUT_DIR"
[ ! -d "$OUTPUT_DIR" ] && fail "output-dir: no such directory $OUTPUT_DIR"
[ ! -d "$ROOTFS_OVERLAY" ] && fail "rootfs-overlay: no such directory $ROOTFS_OVERLAY"

# set default LEDE_BUILDER_URL if not overriden in configuration file
if [ -z "${LEDE_BUILDER_URL+x}" ]; then
    LEDE_BUILDER_URL="https://downloads.openwrt.org/releases/$LEDE_RELEASE/targets/$LEDE_TARGET/$LEDE_SUBTARGET/openwrt-imagebuilder-$LEDE_RELEASE-$LEDE_TARGET-$LEDE_SUBTARGET.Linux-x86_64.tar.xz"
fi

IMAGE_TAG=$IMAGE_TAG:$LEDE_RELEASE-$LEDE_TARGET-$LEDE_SUBTARGET

function print_config {
    cat<<EOT
--- configuration ------------------------------
RELEASE...........: $LEDE_RELEASE
TARGET............: $LEDE_TARGET
SUBTARGET.........: $LEDE_SUBTARGET
PROFILE...........: $LEDE_PROFILE
BUILDER_URL.......: $LEDE_BUILDER_URL
DOCKER_IMAGE_TAG..: $IMAGE_TAG
OUTPUT_DIR........: $OUTPUT_DIR
ROOTFS_OVERLAY....: $ROOTFS_OVERLAY
DISABLED_SERVICES.: $LEDE_DISABLED_SERVICES
REPOSITORIES_CONF.: $REPOSITORIES_CONF
CONTAINER ENGINE..: $(echo "$DOCKER_RUN" | cut -d " " -f1)
------------------------------------------------
EOT
}

case $COMMAND in
     build)
         print_config
         build_lede_image  ;;
     build-docker-image)
         print_config
         build_docker_image  ;;
     profiles)
         show_profiles ;;
     shell)
         print_config
         run_shell ;;
     *)
        usage "$0"
        exit 0 ;;
esac

