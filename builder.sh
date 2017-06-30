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
    echo "Dockerized LEDE/OpenWRT image builder."
    echo ""
    echo "Usage: $0 COMMAND CONFIGFILE [-o OUTPUT_DIR] [-f ROOTFS_OVERLAY]"
    echo "  COMMAND is one of:"
    echo "    build-docker-image- just build the docker image"
    echo "    build             - build docker image, then start container and build the LEDE image"
    echo "    shell             - start shell in docker container"
    echo "  CONFIGFILE          - configuraton file to use"
    echo "  OUTPUT_DIR          - output directory (default $OUTPUT_DIR)"
    echo "  ROOTFS_OVERLAY      - rootfs-overlay directory (default $ROOTFS_OVERLAY)"
    echo "  command line options -o, -f override config file settings."
    echo ""
    echo "Example:"
    echo "  $0 build example.cfg -o output -f myrootfs"
    exit 1
}

# build container and pass in the actual builder to use
function build_docker_image  {
    echo "building container $IMAGE_TAG ..."
	sudo docker build --build-arg BUILDER_URL="$LEDE_BUILDER_URL" \
                      -t $IMAGE_TAG docker
}

# run the builder in the container.
function build_lede_image {
	mkdir -p $OUTPUT_DIR
    echo "building image for $LEDE_PROFILE ..."
	sudo docker run \
			--rm \
			-e GOSU_USER=`id -u`:`id -g` \
			-v $ROOTFS_OVERLAY:/lede/rootfs-overlay:z \
			-v $OUTPUT_DIR:/lede/output:z \
			-ti --rm $IMAGE_TAG \
			  make image PROFILE="$LEDE_PROFILE" \
				PACKAGES="$LEDE_PACKAGES" \
				FILES="/lede/rootfs-overlay" \
				BIN_DIR="/lede/output"
}

# run a shell in the container, useful for debugging.
function run_shell {
	sudo docker run \
			--rm \
			-e GOSU_USER=`id -u`:`id -g` \
			-v $ROOTFS_OVERLAY:/lede/rootfs-overlay:z \
			-v $OUTPUT_DIR:/lede/output:z \
			-ti --rm $IMAGE_TAG
}

if [ $# -lt 2 ]; then
    usage_and_exit
fi

COMMAND=$1; shift
CONFIG_FILE=$1; shift

# pull in config file
if [ ! -f $CONFIG_FILE ]; then 
    echo "error opening $CONFIG_FILE"
    exit 1
fi
eval "$(cat $CONFIG_FILE)"

# parse cli args, can override config file params
while [[ $# -gt 1 ]]; do
    key="$1"
    case $key in
        -f) ROOTFS_OVERLAY="$2"; shift ;;
        -o) OUTPUT_DIR="$2"; shift ;;
        *) echo "invalid option: $key"; exit 1;;
    esac
    shift
done

echo "--- configuration -------------------"
echo "LEDE_RELEASE......: $LEDE_RELEASE"
echo "LEDE_TARGET.......: $LEDE_TARGET"
echo "LEDE_SUBTARGET....: $LEDE_SUBTARGET"
echo "LEDE_PROFILE......: $LEDE_PROFILE"
echo "LEDE_BUILDER_URL..: $LEDE_BUILDER_URL"
IMAGE_TAG=$IMAGE_TAG:$LEDE_RELEASE-$LEDE_TARGET-$LEDE_SUBTARGET 
echo "DOCKER_IMAGE_TAG..: $IMAGE_TAG"
echo "OUTPUT_DIR........: $OUTPUT_DIR"
echo "ROOTFS_OVERLAY....: $ROOTFS_OVERLAY"
echo "-------------------------------------"

case $COMMAND in
     build) 
         build_docker_image  
         build_lede_image  ;;
     build-docker-image) 
         build_docker_image  ;;
     shell) 
         run_shell ;;
     *) usage_and_exit
esac


