# Containerized OpenWrt image builder

![Build Status](https://github.com/jandelgado/lede-dockerbuilder/workflows/test/badge.svg)

<!-- vim-markdown-toc GFM -->

* [What](#what)
    * [Note](#note)
* [Why](#why)
* [How](#how)
    * [Usage](#usage)
        * [Dockerless operation](#dockerless-operation)
    * [Configuration file](#configuration-file)
    * [File system overlay](#file-system-overlay)
    * [Example directory structure](#example-directory-structure)
        * [Debugging](#debugging)
* [Examples](#examples)
    * [Building a x86_64 image and running it in qemu](#building-a-x86_64-image-and-running-it-in-qemu)
* [Building an OpenWrt snapshot release](#building-an-openwrt-snapshot-release)
* [Author](#author)
* [License](#license)

<!-- vim-markdown-toc -->

## What

Easily and quickly build OpenWrt custom images (e.g. for your embedded device
our Raspberry PI) using a self-contained docker container and the
[OpenWrt image builder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder).
On the builder host, Docker or podman/buildah (for dockerless
operation) is the only requirement. Supports latest OpenWrt release (21.02.0).

### Note

The OpenWrt-dockerbuilder uses pre-compiled packages to build the final image. 
Look [here](https://github.com/jandelgado/lede-dockercompiler) if you are looking 
for a docker images to compile OpenWrt completely from source.

## Why

* customized and optimized (size) images with your personal configurations
* full automatic image creation (could be run in CI)
* reproducable results
* easy configuration, fast build (in minutes)

## How

```
$ git clone https://github.com/jandelgado/lede-dockerbuilder.git
$ cd lede-dockerbuilder
$ ./builder.sh build-docker-image example-nexx-wt3020.conf
$ ./builder.sh build example-nexx-wt3020.conf
```

The `build-docker-image` command will first build the docker image containing
the actual image builder. The resulting docker image is per default tagged with
`openwrt-imagebuilder:<Release>-<Target>-<Subtarget>`.  The `build` command
will afterwards run a container, which builds the actual OpenWrt image. The
final OpenWrt image will be available in the `output/` directory.

### Usage

```
Dockerized LEDE/OpenWRT image builder.

Usage: ./builder.sh COMMAND CONFIGFILE [OPTIONS]
  COMMAND is one of:
    build-docker-image - build the docker image (run once first)
    profiles  - start container and show avail profiles for current configuration
    build     - start container and build the LEDE/OpenWRT image
    shell     - start shell in docker container
  CONFIGFILE  - configuraton file to use

  OPTIONS:
  -o OUTPUT_DIR       - output directory (default /home/paco/src/lede-dockerbuilder/output)
  --docker-opts OPTS  - additional options to pass to docker run
                        (can occur multiple times)
  -f ROOTFS_OVERLAY   - rootfs-overlay directory (default /home/paco/src/lede-dockerbuilder/rootfs-overlay)
  --skip-sudo         - call docker directly, without sudo
  --dockerless        - use podman and buildah instead of docker daemon

  command line options -o, -f override config file settings.

Example:
  # build the builder docker image first
  ./builder.sh build-docker-image example.conf

  # now build the OpenWrt image
  ./builder.sh build example.conf -o output -f myrootfs

  # show available profiles
  ./builder.sh profiles example.conf 

  # mount downloads to host directory during build
  ./builder.sh build example-nexx-wt3020.conf --docker-opts "-v=$(pwd)/dl:/lede/imagebuilder/dl:z"
```

#### Dockerless operation

When called with `--dockerless` option, lede-dockerbuilder will use buildah and 
podman to build and run the container.

### Configuration file

The configuration file is quiet self-explanatory. The following parameters are
mandatory (prefixed with `LEDE_` for historical reasons, config works also
with OpenWrt):

* `LEDE_TARGET` - Target architecture
* `LEDE_SUBTARGET` - Sub target architecture
* `LEDE_RELEASE` - Release to use
* `LEDE_PROFILE` - Profile to use
* `LEDE_PACKAGES` - list of packages to include/exclude. Prepend package to be excluded with `-`
* `LEDE_DISABLED_SERVICES` - list of services to disable on startup in /etc/init.d

`LEDE_TARGET`, `LEDE_SUBTARGET` and `LEDE_RELEASE` are used to construct the
URL of the image builder binary well as for the construction for the tag of the
docker image.

You can find the proper values by browsing the OpenWrt website e.g.
[here](https://openwrt.org/docs/techref/targets/start)  and
[here](https://openwrt.org/toh/views/toh_admin_fw-pkg-download).

In addition the following optional parameters can be set, to further control
output and image creation:

* `OUTPUT_DIR` - path where resulting images are stored. Defaults to `output`
  in the scripts directory (can be overridden by -o parameter). Will be
  automatically created.
* `ROOTFS_OVERLAY` - path of the root file system overlay directory. Defaults
  to `rootfs-overlay` in the scripts directory (can be overridden by -f
  parameter).
* `LEDE_BUILDER_URL` - URL of the LEDE/OpenWrt image builder to use, override
   if you do not wish to use the default builder
   (`https://downloads.openwrt.org/releases/$LEDE_RELEASE/targets/$LEDE_TARGET/$LEDE_SUBTARGET/openwrt-imagebuilder-$LEDE_RELEASE-$LEDE_TARGET-$LEDE_SUBTARGET.Linux-x86_64.tar.xz`)
* `REPOSITORIES_CONF` - optional file file to use instead of the default
  `repositories.conf`. The file will be mounted in the container.
  Look at the [official documentation](https://openwrt.org/docs/guide-user/additional-software/imagebuilder#add_package_repositories_optional)
  for more information.

Use the `BASEDIR_CONFIG_FILE` variable to set locations of `OUTPUT_DIR` or
`ROOTFS_OVERLAY` relative to the configuration files location. This allows
self-contained projects outside of the lede-dockerbuilder folder. If e.g.
`ROOTFS_OVERLAY=$BASEDIR_CONFIG_FILE/rootfs-overlay` is set, then the
rootfs-overlay directory is expected to be in the same directory as the
configuration file.

[Example configuration](example-nexx-wt3020.conf) for my [NEXX
WT3020](https://openwrt.org/toh/nexx/wt3020) router, where I have an
encrypted USB disk attached so I can use it as a simple NAS with samba and ftp:

```
# LEDE profile to use: NEXX WT3020
LEDE_PROFILE=nexx_wt3020-8m
LEDE_RELEASE=21.02.0-rc4
LEDE_TARGET=ramips
LEDE_SUBTARGET=mt7620

# list packages to include in LEDE image. prepend packages to deinstall with "-".
LEDE_PACKAGES="ksmbd-server ksmbd-utils vsftpd lsblk iwinfo tcpdump block-mount\
    kmod-usb-storage-uas kmod-scsi-core kmod-fs-ext4 ntfs-3g\
    kmod-nls-cp437 kmod-nls-iso8859-1 cryptsetup kmod-crypto-xts\
    kmod-mt76 kmod-usb2 kmod-usb-ohci kmod-usb-core kmod-dm kmod-crypto-ecb\
    kmod-crypto-misc kmod-crypto-cbc kmod-crypto-crc32c kmod-crypto-hash\
    kmod-crypto-user\
    -ppp -kmod-ppp -kmod-pppoe -kmod-pppox -ppp-mod-pppoe\
    -ip6tables -odhcp6c -kmod-ipv6 -kmod-ip6tables -odhcpd-ipv6only"
```

### File system overlay

Place any files and folders that should be copied to the root file system of
the resulting image to the directory pointed to by `ROOTFS_OVERLAY` (default:
`rootfs-overlay/`), which can be overridden by the -f command line option.

### Example directory structure

The following is an example directoy layout, which I use to create a customized
OpenWrt image for my [NEXX WT3020](https://openwrt.org/toh/nexx/wt3020)
router (including the generated output).

```
├── builder.sh
├── docker
│   ├── Dockerfile
│   └── etc
│        └── entrypoint.sh
├── example.cfg
├── example-openwrt.cfg
├── output
│   ├── openwrt-xx.yy.z-ramips-mt7620-device-wt3020-8m.manifest
│   ├── openwrt-xx.yy.z-ramips-mt7620-wt3020-8M-squashfs-factory.bin
│   ├── openwrt-xx.yy.z-ramips-mt7620-wt3020-8M-squashfs-sysupgrade.bin
│   └── sha256sums
├── README.md
└── rootfs-overlay
    ├── etc
    │   ├── config
    │   │   ├── dhcp
    │   │   ├── dropbear
    │   │   ├── firewall
    │   │   ├── network
    │   │   ├── samba
    │   │   ├── system
    │   │   ├── wireless
    │   ├── dropbear
    │   │   └── authorized_keys
    │   ├── hotplug.d
    │   │   └── block
    │   │       └── 10-mount
    │   ├── passwd
    │   ├── rc.local
    │   ├── shadow
    │   └── vsftpd.conf
    ├── README.md
    └── usr
        └── local
            └── bin
                └── fix_sta_ap.sh
```

#### Debugging

Run `./builder.sh shell CONFIGFILE` to get a shell into the docker container,
e.g. `./builder.sh shell example.cfg`.

## Examples

These examples evolved from images I use myself.

* [image with LUCI web GUI for the Raspberry PI 2](example-rpi2.conf).
  Just ~8MB gziped. I use this image on my home dnsmasq/openvpn 'server'.
* [image with LUCI web GUI and adblocker for the Raspberry PI 4](example-rpi4.conf)
* [image for the TP-Link WR1043ND](example-wrt1043nd.conf)
* [image with samba, vsftpd and encrypted usb disk for
  NEXX-WT3020](example-nexx-wt3020.conf). Is the predessor of ...
* [image with samba, vsftpd and encrypted usb disk for
  GINET-GL-M300N V2](example-ginet-gl-mt300n-v2.conf). This is my travel router
  setup where I have an encrypted USB disk connected to the router.

To build an example run `./builder.sh build <config-file>`, e.g.

```shell
$ ./builder.sh build example-rpi2.conf 
```

The resulting image can be found in the `output/` directory. The [OpenWrt
wiki](https://openwrt.org/docs/guide-user/installation/generic.sysupgrade)
describes how to flash the new image in detail.

### Building a x86_64 image and running it in qemu

The [example-x86_64.conf](example-x86_64.conf) file can be used to build a
x86_64 based OpenWrt image which can also be run in qemu, e.g. if you need
a virtual router/firewall.

First build the image with `builder.sh build example-x86_64.conf`, then unpack
the resulting image with `gunzip output/openwrt-19.07.x-x86-64-combined-ext4.img.gz`.
Now the image can be started with qemu:

```
qemu-system-x86_64 \
    -enable-kvm \
    -nographic \
    -device ide-hd,drive=d0,bus=ide.0 \
    -drive file=output/openwrt-19.07.0-x86-64-combined-ext4.img,id=d0,if=none  \
    -netdev user,id=hn0 \
    -device virtio-net-pci,netdev=hn0,id=wan \
    -netdev user,id=hn1,hostfwd=tcp::5555-:22001 \
    -device virtio-net-pci,netdev=hn1,id=lan 
```

The `hostfwd=...` part can be omitted and is used in case you redirect port
22001 on your WAN adapter to port 22 of the LAN adapter, in case you want to
access SSH in the VM from your qemu-host. Check the `/etc/config/firewall` file
for details.

Qemu will assign the IP address `10.0.2.15/24` to the `WAN` interface (`eth1`)
and OpenWrt the address `192.168.1.1/24` to the `LAN` (`br-lan` bridge with
`eth0`) interface.

Note: press `CTRL-A X` to exit qemu.

## Building an OpenWrt snapshot release

To build a [snapshot](https://downloads.openwrt.org/snapshots) release, set
`LEDE_RELEASE` to `snapshots` and let `LEDE_BUILDER_URL` point to the image
builder in the snapshot dir, e.g.

```
LEDE_RELEASE=snapshots
LEDE_BUILDER_URL="https://downloads.openwrt.org/$LEDE_RELEASE/targets/$LEDE_TARGET/$LEDE_SUBTARGET/openwrt-imagebuilder-$LEDE_TARGET-$LEDE_SUBTARGET.Linux-x86_64.tar.xz" 
```

See the [Raspberry Pi 4 example](example-rpi4.conf) which builds an image for
the raspi 4, which is (as of may 2020) only available on the snapshots branch.

## Author

Jan Delgado

## License

Apache License 2.0
