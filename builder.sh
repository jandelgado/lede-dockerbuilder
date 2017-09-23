#!/bin/bash
# A Docker based LEDE image builder.
# (c) Jan Delgado 02-2017

set -e

# base Tag to use for docker imag
IMAGE_TAG=lede-imagebuilder

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# may be overridden in the config file
OUTPUT_DIR=$SCRIPT_DIR/output
ROOTFS_OVERLAY=$SCRIPT_DIR/rootfs-overlay

function usage_and_exit {
    cat<<EOT
Dockerized LEDE/OpenWRT image builder.

Usage: $1 COMMAND CONFIGFILE [OPTIONS] 
  COMMAND is one of:
    build-docker-image- just build the docker image
    build             - build docker image, then start container and build the LEDE image
    shell             - start shell in docker container
  CONFIGFILE          - configuraton file to use

  OPTIONS:
  -o OUTPUT_DIR       - output directory (default $OUTPUT_DIR)
  -f ROOTFS_OVERLAY   - rootfs-overlay directory (default $ROOTFS_OVERLAY)
  --skip-sudo         - call docker directly, without sudo

  command line options -o, -f, -r override config file settings.

Example:
  ./builder.sh build example.cfg -o output -f myrootfs
EOT
    exit 0
}

# build container and pass in the actual builder to use
function build_docker_image  {
    echo "building container $IMAGE_TAG ..."
	$SUDO docker build --build-arg BUILDER_URL="$LEDE_BUILDER_URL" \
                      -t $IMAGE_TAG docker
}

function run_cmd_in_container {
	$SUDO docker run \
			--rm \
			-e GOSU_USER=`id -u`:`id -g` \
            -v $(cd $ROOTFS_OVERLAY; pwd):/lede/rootfs-overlay:z \
            -v $(cd $OUTPUT_DIR; pwd):/lede/output:z \
			-ti --rm $IMAGE_TAG "$@"
}

# run the builder in the container.
function build_lede_image {
	mkdir -p $OUTPUT_DIR
    echo "building image for $LEDE_PROFILE ..."
    run_cmd_in_container  make image PROFILE="$LEDE_PROFILE" \
				PACKAGES="$LEDE_PACKAGES" \
				FILES="/lede/rootfs-overlay" \
				BIN_DIR="/lede/output"
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
    usage_and_exit $0
fi

COMMAND=$1; shift
CONFIG_FILE=$1; shift
SUDO=sudo

# pull in config file
[ ! -f "$CONFIG_FILE" ] && fail "can not open $CONFIG_FILE"
eval "$(cat "$CONFIG_FILE")"

# parse cli args, can override config file params
while [[ $# -ge 1 ]]; do
    key="$1"
    case $key in
        -f) ROOTFS_OVERLAY="$2"; shift ;;
        -o) OUTPUT_DIR="$2"; shift ;;
        --skip-sudo) SUDO="" ;;
        *) fail "invalid option: $key";;
    esac
    shift
done

[ ! -d "$OUTPUT_DIR" ] && fail "output-dir: no such directory $OUTPUT_DIR"
[ ! -d "$ROOTFS_OVERLAY" ] && fail "rootfs-overlay: no such directory $ROOTFS_OVERLAY"

IMAGE_TAG=$IMAGE_TAG:$LEDE_RELEASE-$LEDE_TARGET-$LEDE_SUBTARGET 
cat<<EOT
--- configuration ------------------------------
LEDE_RELEASE......: $LEDE_RELEASE
LEDE_TARGET.......: $LEDE_TARGET
LEDE_SUBTARGET....: $LEDE_SUBTARGET
LEDE_PROFILE......: $LEDE_PROFILE
LEDE_BUILDER_URL..: $LEDE_BUILDER_URL
DOCKER_IMAGE_TAG..: $IMAGE_TAG
OUTPUT_DIR........: $OUTPUT_DIR
ROOTFS_OVERLAY....: $ROOTFS_OVERLAY
------------------------------------------------
EOT

case $COMMAND in
     build) 
         build_docker_image  
         build_lede_image  ;;
     build-docker-image) 
         build_docker_image  ;;
     shell) 
         run_shell ;;
     *) usage_and_exit $0
esac

