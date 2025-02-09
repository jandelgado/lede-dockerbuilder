#!/bin/bash
# A frontend to the OpenWrt image builder, using containers (e.g. docker) 
# or a nix-shell to run the OpenWrt image builder.
#
# https://github.com/jandelgado/lede-dockerbuilder
#
# (c) Jan Delgado 2017-2022
set -euo pipefail
PROG=$0
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# may be overridden in the config file
OUTPUT_DIR=$SCRIPT_DIR/output
ROOTFS_OVERLAY=$SCRIPT_DIR/rootfs-overlay
LEDE_DISABLED_SERVICES=
REPOSITORIES_CONF=

BUILD_DIR=${NIX_BUILD_DIR:-"$SCRIPT_DIR/.build"}
SUDO=""
DOCKER_BUILD="docker build"
DOCKER_RUN="docker run -e GOSU_UID=$(id -ur) -e GOSU_GID=$(id -g)"
RUNTIME="docker"
DOCKER_OPTS=()

function usage {
    cat<<EOT
Dockerized LEDE/OpenWRT image builder.

Usage: $PROG COMMAND CONFIGFILE [OPTIONS]
  COMMAND is one of:
    build-docker-image - build the docker image (run once first)
    profiles           - show available profiles for current configuration
    build              - start container and build the LEDE/OpenWRT image
    shell              - start shell in the build dir 
  CONFIGFILE           - configuraton file to use

  OPTIONS:
  -o OUTPUT_DIR        - output directory (default $OUTPUT_DIR)
  --docker-opts OPTS   - additional options to pass to docker run
                         (can occur multiple times)
  -f ROOTFS_OVERLAY    - rootfs-overlay directory (default $ROOTFS_OVERLAY)
  --sudo               - call container tool with sudo
  --podman             - use buildah and podman to build and run container
  --nerdctl            - use nerdctl to build and run container
  --docker             - use docker to build and run container (default)
  --nix                - build using nix-shell

  command line options -o, -f override config file settings.

Example:
  # build the builder docker image first
  $PROG build-docker-image example-glinet-gl-ar750.conf

  # now build the OpenWrt image, overriding output and rootfs locations
  $PROG build example-glinet-gl-ar750.conf -o output -f myrootfs

  # show available profiles for the arch/target/subtarget of the given configuration
  $PROG profiles example-glinet-gl-ar750.conf

  # pass additional docker options: mount downloads to host directory during build
  $PROG build example-glinet-gl-ar750.conf --docker-opts "-v=$(pwd)/dl:/lede/imagebuilder/dl:z"

  # use nix to build the OpenWrt image, no need to build a container first
  $PROG build example-x86_64.conf --nix
EOT
    exit 0
}

# return given file path as absolute path. path to file must exist.
function abspath {
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

# build container and pass in the actual builder to use
function build_docker_image  {
    local url=$1
    local tag=$2

    echo "building docker image $tag ..."
    # shellcheck disable=2086
    $SUDO $DOCKER_BUILD\
        --build-arg BUILDER_URL="$url" -t "$tag" docker
}

function run_cmd_in_nix_shell {
    nix-shell --pure --run "bash -c '$*'"
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
        -v "$(abspath "$ROOTFS_OVERLAY")":/lede/rootfs-overlay \
        -v "$(abspath "$OUTPUT_DIR")":/lede/output \
        "${repositories_volume[@]}" \
        ${DOCKER_OPTS[@]} \
        ${_DOCKER_OPTS:-} \
        --rm "$(image_tag)" bash -c "$*"
}

function run_cmd {
    if [ "$RUNTIME" == "nix" ]; then
        run_cmd_in_nix_shell "$@"
    else
        run_cmd_in_container "$@"
    fi
}

# return the command to run the builder
function build_cmd {
    local build_dir=$1
    local overlay=$2
    local output=$3
    local cmd="make -C \"$build_dir\" \
        image PROFILE=\"$LEDE_PROFILE\" \
        PACKAGES=\"$LEDE_PACKAGES\" \
        DISABLED_SERVICES=\"$LEDE_DISABLED_SERVICES\" \
        FILES=\"$overlay\" \
        BIN_DIR=\"$output\""
    echo "$cmd"
}

# show available profiles
function show_profiles {
    local build_dir=$1
    run_cmd make -C "$build_dir" info
}

# run a shell in the container, useful for debugging.
function run_shell {
    local cwd=$1
    run_cmd "cd $cwd && bash"
}

# print message and exit
function fail {
    echo "ERROR: $*" >&2
    exit 1
}

function warn {
    echo "WARNING: $*" >&2
}

# download the OpenWRT image builder (when using nix-shell) to $1 from url $2
download_builder() {
    local dir=$1
    local url=$2

    if [ -d "$dir" ]; then
        # image builder already downloaded
        return
    fi

    mkdir -p "$dir"
    echo curl "download $url -> $dir" 
    curl --progress-bar "$url" -o "$dir/tmpbuilder" \
         && tar xfa "$dir/tmpbuilder" --strip-components=1 -C "$dir" \
         && rm "$dir/tmpbuilder"
}

function print_config {
    local runtime
    if [ "$RUNTIME" == "nix" ]; then
        runtime="nix, dir: $BUILD_DIR"
    else
        runtime="$RUNTIME, image tag:$(image_tag)"
    fi
    cat<<EOT
--- configuration ------------------------------
RELEASE...........: $LEDE_RELEASE
TARGET............: $LEDE_TARGET
SUBTARGET.........: $LEDE_SUBTARGET
PROFILE...........: $LEDE_PROFILE
BUILDER_URL.......: $(builder_url)
OUTPUT_DIR........: $OUTPUT_DIR
ROOTFS_OVERLAY....: $ROOTFS_OVERLAY
DISABLED_SERVICES.: $LEDE_DISABLED_SERVICES
REPOSITORIES_CONF.: $REPOSITORIES_CONF
RUNTIME...........: $runtime
------------------------------------------------
EOT
}

# tests if given version is less then provided version in semver, e.g.
# version_ge_than("24.0.10", "23") -> false
# version_ge_than("24.0.10", "24") -> true
function version_ge_than { [ "${1%%.*}" -ge "$2" ]; }

# return default LEDE_BUILDER_URL if not overriden in configuration file
function builder_url {
    # using .zst since OpenWrt 24, .xz before
    if [ -z "${LEDE_BUILDER_URL+x}" ]; then
        if version_ge_than "$LEDE_RELEASE" "24"; then
            local ext="zst"
        else
            local ext="xz"
        fi
        echo "https://downloads.openwrt.org/releases/$LEDE_RELEASE/targets/$LEDE_TARGET/$LEDE_SUBTARGET/openwrt-imagebuilder-$LEDE_RELEASE-$LEDE_TARGET-$LEDE_SUBTARGET.Linux-x86_64.tar.$ext"
        return
    fi
    echo "$LEDE_BUILDER_URL"
}

function image_tag {
    echo "openwrt-imagebuilder:$LEDE_RELEASE-$LEDE_TARGET-$LEDE_SUBTARGET"
}

function builder_dir {
    if [ "$RUNTIME" == "nix" ]; then
        echo "$BUILD_DIR/$LEDE_RELEASE-$LEDE_TARGET-$LEDE_SUBTARGET"
    else
        echo "."
    fi
}

function ensure_dirs {
    mkdir -p "$OUTPUT_DIR"
    [ ! -d "$OUTPUT_DIR" ] && fail "output-dir: no such directory $OUTPUT_DIR"
    [ ! -d "$ROOTFS_OVERLAY" ] && fail "rootfs-overlay: no such directory $ROOTFS_OVERLAY"
    true
}

function ensure_nix_env {
    local builder_dir=$1
    local builder_url=$2
    download_builder "$builder_dir" "$builder_url"
}

# parse cli args, can override config file params
function parse_options {
    while [[ $# -ge 1 ]]; do
        local key="$1"
        case $key in
            -f)
                ROOTFS_OVERLAY="$2"; shift 
                ;;
            -o)
                OUTPUT_DIR="$2"; shift 
                ;;
            --nix)
                RUNTIME="nix"
                ;;
            --sudo)
                SUDO="sudo" 
                ;;
            --docker-opts)
                DOCKER_OPTS+=("$2"); shift 
                ;;
            --docker)
                ;;
            --nerdctl)
                DOCKER_BUILD="nerdctl build"
                DOCKER_RUN="nerdctl run -e GOSU_UID=$(id -ur) -e GOSU_GID=$(id -g)"
                RUNTIME="nerdctl"
                ;;
            --podman)
                DOCKER_BUILD="buildah bud --layers=true"
                DOCKER_RUN="podman run" 
                RUNTIME="podman"
                ;;
            --dockerless)
                fail "option --dockerless removed. Use --podman or --nerdctl instead"
                ;;
            --skip-sudo)
                warn "option --skip-sudo removed (is now the default). Use --sudo to enable sudo"
                ;;

            *)
                fail "invalid option: $key";;
        esac
        shift
    done
}

function dispatch_command {
    local command=$1

    ensure_dirs
    [ "$RUNTIME" == "nix" ] && ensure_nix_env "$(builder_dir)" "$(builder_url)"

    case $command in
         build)
             print_config
             if [ "$RUNTIME" == "nix" ]; then
                 cmd=$(build_cmd "$(builder_dir)" "$ROOTFS_OVERLAY" "$OUTPUT_DIR")
             else 
                 cmd=$(build_cmd "$(builder_dir)" "/lede/rootfs-overlay" "/lede/output")
             fi
             run_cmd "$cmd"
             ;;
         build-docker-image)
             [ "$RUNTIME" == "nix" ] && warn "refusing to build docker image when using --nix" && exit
             print_config
             build_docker_image "$(builder_url)" "$(image_tag)"
             ;;
         profiles)
             show_profiles "$(builder_dir)"
             ;;
         shell)
             print_config
             run_shell "$(builder_dir)"
             ;;
         *)
            usage "$0"
            # shellcheck disable=2317
            exit 0
            ;;
    esac
}

if [ $# -lt 2 ]; then
    usage "$0"
    # shellcheck disable=2317
    exit 1
fi

COMMAND=$1; shift
CONFIG_FILE=$1; shift

# globally pull in config file, making $BASEDIR_CONFIG_FILE available inside`
[ ! -f "$CONFIG_FILE" ] && fail "can not open $CONFIG_FILE"
# shellcheck disable=SC2034
BASEDIR_CONFIG_FILE=$( cd "$( dirname "$CONFIG_FILE" )" && pwd )
eval "$(cat "$CONFIG_FILE")"

parse_options "$@"
dispatch_command "$COMMAND"
