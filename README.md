# Dockerized LEDE image builder

## What?
Easily build LEDE custom images using a self contained docker
container and the [LEDE image builder](https://lede-project.org/docs/user-guide/imagebuilder).

## Why?
  * customize LEDE images for your personal needs
  * space optimize images
  * automatically create LEDE images
  * reproducable results

## How?
```
$ git clone https://github.com/jandelgado/lede-dockerbuilder.git
$ cd lede-dockerbuilder
<<<edit example.cfg or create own configuration>>>
$ ./builder.sh build example.cfg
```
The `build` command will first build the docker image containing the LEDE image builder. The resulting docker image is tagged `lede-imagebuilder:<Release-Target-Subtarget>`.  Afterwards a container, which builds the actual LEDE image, is run.  The final LEDE image will be available in the `output/` directory.

### Configuration file
The configuration file is quiet self-explanatory. The following parameters are mandatory:
  * `LEDE_TARGET` - Target architecture
  * `LEDE_SUBTARGET` - Sub target architecture
  * `LEDE_RELEASE` - LEDE release to use
  * `LEDE_PROFILE` - LEDE profile to use
  * `LEDE_BUILDER_URL` - URL of the LEDE image builder to use
  * `LEDE_PACKAGES` - list of packages to include/exclude. Prepend package to be excluded with `-`.

`LEDE_TARGET`, `LEDE_SUBTARGET` and `LEDE_RELEASE` are used to construct the URL of the image builder binary, `LEDE_BUILDER_URL` as well as for the construction for the tag of the docker image.

You can find the proper values by browsing the LEDE website [here](http://ftp.halifax.rwth-aachen.de/lede/releases/17.01.1/targets/)  and [here](https://lede-project.org/toh/views/toh_admin_fw-pkg-download).

In addition the following optional parameters can be set, to further control output and image creation:
  * `OUTPUT_DIR` - path where resulting images are stored. Defaults to `output` in the scripts directory
  * `ROOTFS_OVERLAY` - path of the root file system overlay directory. Defaults to `rootfs-overlay` in the scripts directory

[Example configuration](example.cfg) for my [NEXX WT3020](https://wiki.openwrt.org/toh/nexx/wt3020) router, where I have an encrypted USB disk attached.
```
# LEDE profile to use
LEDE_PROFILE=wt3020-8M

# specify the URL where the builder can be downloaded. 
LEDE_RELEASE=17.01.1
LEDE_TARGET=ramips
LEDE_SUBTARGET=mt7620
LEDE_BUILDER_URL="https://downloads.lede-project.org/releases/$LEDE_RELEASE/targets/$LEDE_TARGET/$LEDE_SUBTARGET/lede-imagebuilder-$LEDE_RELEASE-$LEDE_TARGET-$LEDE_SUBTARGET.Linux-x86_64.tar.xz"

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
Place any files and folders that should be copied to the resulting image to the `rootfs-overlay/` directory.

### Example directory structure
The following is an example directoy layout, which is used to create a customized LEDE image for an [NEXX WT3020](https://wiki.openwrt.org/toh/nexx/wt3020) router (including the generated output).
```
├── Dockerfile
├── etc
│   └── entrypoint.sh
├── builder.sh
├── output
│   ├── lede-17.01.1-ramips-mt7620-device-wt3020-8m.manifest
│   ├── lede-17.01.1-ramips-mt7620-wt3020-8M-squashfs-factory.bin
│   ├── lede-17.01.1-ramips-mt7620-wt3020-8M-squashfs-sysupgrade.bin
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

## Debugging
Run `./builder.sh shell CONFIGFILE` to get a shell into the docker container, e.g. `./builder.sh shell example.cfg`.

# Author
Jan Delgado

# License
Apache License 2.0
