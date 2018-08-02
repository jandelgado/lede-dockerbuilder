# Dockerized OpenWRT image builder

[![Build Status](https://travis-ci.org/jandelgado/lede-dockerbuilder.svg?branch=master)](https://travis-ci.org/jandelgado/lede-dockerbuilder)

<!-- vim-markdown-toc GFM -->

* [What](#what)
    * [Note](#note)
* [Why](#why)
* [How](#how)
    * [Usage](#usage)
    * [Configuration file](#configuration-file)
    * [File system overlay](#file-system-overlay)
    * [Example directory structure](#example-directory-structure)
        * [Debugging](#debugging)
* [Examples](#examples)
* [Author](#author)
* [License](#license)

<!-- vim-markdown-toc -->

## What

Easily and quickly build OpenWRT custom images using a self-contained
docker container and the
[OpenWrt](https://wiki.openwrt.org/doc/howto/obtain.firmware.generate) image
builder. On the builder host, Docker is the only requirement. Supports latest
OpenWRT release (18.06).

### Note

The OpenWRT-dockerbuilder uses pre-compiled packages to build the final image. 
Look [here](https://github.com/jandelgado/lede-dockercompiler) if you are looking 
for a docker images to compile OpenWRT completely from source.

## Why

* customized and optimized (size) images with your personal configurations
* full automatic image creation (could be run in CI)
* reproducable results
* easy configuration, fast build (in minutes)

## How

```
$ git clone https://github.com/jandelgado/lede-dockerbuilder.git
$ cd lede-dockerbuilder
$ ./builder.sh build example-nexx-wt3020.conf
```
Your custom images can now be found in the `output` diretory.

The `build` command will first build the docker image containing the actual image
builder. The resulting docker image is per default tagged with
`openwrt-imagebuilder:<Release>-<Target>-<Subtarget>`.  Afterwards a container,
which builds the actual OpenWRT image, is run. The final OpenWRT image will be
available in the `output/` directory.

### Usage
```
Dockerized LEDE/OpenWRT image builder.

Usage: ./builder.sh COMMAND CONFIGFILE [OPTIONS] 
  COMMAND is one of:
    build-docker-image- just build the docker image
    build             - build docker image, then start container and build the LEDE image
    shell             - start shell in docker container
  CONFIGFILE          - configuraton file to use

  OPTIONS:
  -o OUTPUT_DIR       - output directory 
  -f ROOTFS_OVERLAY   - rootfs-overlay directory 
  --skip-sudo         - call docker directly, without sudo

  command line options -o, -f, -r override config file settings.

Example:
  ./builder.sh build example.cfg -o output -f myrootfs
```

### Configuration file

The configuration file is quiet self-explanatory. The following parameters are
mandatory:

  * `LEDE_TARGET` - Target architecture
  * `LEDE_SUBTARGET` - Sub target architecture
  * `LEDE_RELEASE` - LEDE release to use
  * `LEDE_PROFILE` - LEDE profile to use
  * `LEDE_BUILDER_URL` - URL of the LEDE image builder to use
  * `LEDE_PACKAGES` - list of packages to include/exclude. Prepend package to be excluded with `-`.

`LEDE_TARGET`, `LEDE_SUBTARGET` and `LEDE_RELEASE` are used to construct the
URL of the image builder binary, `LEDE_BUILDER_URL` as well as for the
construction for the tag of the docker image.

You can find the proper values (for 18.06) by browsing the OpenWRT website
[here](https://downloads.openwrt.org/releases/18.06.0/targets/)  and
[here](https://lede-project.org/toh/views/toh_admin_fw-pkg-download).

In addition the following optional parameters can be set, to further control
output and image creation:

  * `OUTPUT_DIR` - path where resulting images are stored. Defaults to `output`
    in the scripts directory (can be overridden by -o parameter)
  * `ROOTFS_OVERLAY` - path of the root file system overlay directory. Defaults
    to `rootfs-overlay` in the scripts directory (can be overridden by -f
    parameter)

Use the `BASEDIR_CONFIG_FILE` variable to set locations of `OUTPUT_DIR` or
`ROOTFS_OVERLAY` relative to the configuration files location. This allows
self-contained projects outside of the lede-dockerbuilder folder. If e.g.
`ROOTFS_OVERLAY=$BASEDIR_CONFIG_FILE/rootfs-overlay` is set, then the 
rootfs-overlay directory is expected to be in the same directory as the 
configuration file.

[Example configuration](example.conf) for my [NEXX
WT3020](https://wiki.openwrt.org/toh/nexx/wt3020) router, where I have an
encrypted USB disk attached so I can use it as a simple NAS.

```
# LEDE profile to use: NEXX WT3020
LEDE_PROFILE=wt3020-8M

# specify the URL where the builder can be downloaded. 
LEDE_RELEASE=18.06.0
LEDE_TARGET=ramips
LEDE_SUBTARGET=mt7620
LEDE_BUILDER_URL="https://downloads.openwrt.org/releases/$LEDE_RELEASE/targets/$LEDE_TARGET/$LEDE_SUBTARGET/openwrt-imagebuilder-$LEDE_RELEASE-$LEDE_TARGET-$LEDE_SUBTARGET.Linux-x86_64.tar.xz" 

# list packages to include in LEDE image. prepend packages to deinstall with "-".
LEDE_PACKAGES="samba36-server kmod-usb-storage kmod-scsi-core kmod-fs-ext4 ntfs-3g\
    kmod-nls-cp437 kmod-nls-iso8859-1 vsftpd cryptsetup kmod-crypto-xts\
    kmod-crypto-iv block-mount kmod-usb-ohci kmod-usb2 kmod-dm\
    kmod-crypto-misc kmod-crypto-cbc kmod-crypto-crc32c kmod-crypto-hash\
    kmod-crypto-user iwinfo tcpdump\
    -ppp -kmod-ppp -kmod-pppoe -kmod-pppox -ppp-mod-pppoe"

# optionally override OUTPUT_DIR and ROOTFS_OVERLAY directory location here

```

### File system overlay

Place any files and folders that should be copied to the root file system of
the resulting image to the directory pointed to by `ROOTFS_OVERLAY` (default:
`rootfs-overlay/`), which can be overridden by the -f command line option.

### Example directory structure

The following is an example directoy layout, which I use to create a customized
OpenWRT image for my [NEXX WT3020](https://wiki.openwrt.org/toh/nexx/wt3020)
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
│   ├── openwrt-18.06.0-ramips-mt7620-device-wt3020-8m.manifest
│   ├── openwrt-18.06.0-ramips-mt7620-wt3020-8M-squashfs-factory.bin
│   ├── openwrt-18.06.0-ramips-mt7620-wt3020-8M-squashfs-sysupgrade.bin
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

* [minimal image with LUCI web GUI for the Raspberry PI 2](example-rpi2.conf). Just ~8MB gziped. I use this image on my home dnsmasq/openvpn 'server'.  
* [image for the TP-Link WR1043ND](example-wrt1043nd.conf)
* [image with samba, vsftpd and encrypted usb disk for NEXX-WT3020](example-nexx-wt3020.conf). Is the predessor of ...
* [image with samba, vsftpd and encrypted usb disk for GINET-GL-M300N](example-ginet-gl-mt300n.conf). This is my travel router setup where I have an encrypted USB disk connected to the router.

To build an example run `./builder.sh build <config-file>`, e.g.

```shell
$ ./builder.sh build example-rpi2.conf 
```

The resulting image can be found in the `output/` directory.

## Author

Jan Delgado

## License

Apache License 2.0
