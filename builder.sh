#!/bin/sh
# A Docker based LEDE image builder.
# Jan Delgado 02-2017

set -e

# base Tag to use for docker imag
IMAGE_TAG=lede-imagebuilder

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# may be overridden in the config file
OUTPUT_DIR=$SCRIPT_DIR/output
ROOTFS_OVERLAY=$SCRIPT_DIR/rootfs-overlay

function usage_and_exit {
    echo "dockerized LEDE image builder."
    echo ""
    echo "usage: $0 COMMAND CONFIGFILE"
    echo "  COMMAND is one of:"
    echo "   build-docker-image - just build the docker image"
    echo "   build - build docker image, then start container and build the LEDE image"
    echo "   shell - start shell in docker cotainer"
    echo "  CONFIGFILE - configuraton to use."
    echo ""
    echo "example:"
    echo "  $0 build example.cfg"
    echo ""
    echo "resulting images go to $OUTPUT_DIR (override in config)"
    echo "rootfs-overlay is $ROOTFS_OVERLAY (override in config)"
    echo ""
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


[ $# -ne 2 ] && usage_and_exit

# pull in config file
eval "$(cat $2)"

echo "--- configuration -------------------"
echo "LEDE_RELEASE......: $LEDE_RELEASE"
echo "LEDE_TARGET.......: $LEDE_TARGET"
echo "LEDE_SUBTARGET....: $LEDE_SUBTARGET"
echo "LEDE_PROFILE......: $LEDE_PROFILE"
echo "LEDE_BUILDER_URL..: $LEDE_BUILDER_URL"
IMAGE_TAG=$IMAGE_TAG:$LEDE_RELEASE-$LEDE_TARGET-$LEDE_SUBTARGET 
echo "DOCKER_IMAGE_TAG..: $IMAGE_TAG"
echo "-------------------------------------"

case $1 in
     build) 
         build_docker_image  
         build_lede_image  ;;
     build-docker-image) 
         build_docker_image  ;;
     shell) 
         run_shell ;;
     *) usage_and_exit
esac


