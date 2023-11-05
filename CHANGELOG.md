# Changelog for lede-dockerbuilder

## v3.5 [2923-11-05]

* Upgrade to OpenWrt 23.05.0 & make examples run again
* Ugrade docker base image

## v3.4 [2023-04-19]

* Upgrade to OpenWrt 22.03.4
 
## v3.3 [2022-09-19]

* Upgrade to OpenWrt 22.03.0
* add script to run x86_64 image in qemu

## v3.2 [2022-08-07]

* build image using nix-shell, which does not require a container

## v3.1 [2022-05-03]

* Upgrade to OpenWrt 21.02.3
* Add an example for the upcoming OpenWrt 22.03 version

## v3.0 [2022-05-03]

* add experimental support for nerdctl with the new `--nerdctl` option
* `--dockerless` option removed, use `--podman` or `--nerdctl` instead.
  Docker is still the default
* `--skip-sudo` removed, is now the default. Use `--sudo` to run commands with
  sudo
* use ubuntu LTS as base image

## v2.11 [2022-03-16]

* bump to OpenWrt 21.02.2

## v2.10 [2021-09-19]

* bump to OpenWrt 21.02.0

## v2.9 [2021-08-20]

* bump to OpenWrt 21.02.0-rc4

## v2.8 [2021-08-02]

* bump to OpenWrt 21.02.0-rc3
* add new `profile` option to show available profiles
* ci uses matrix build now

## v2.7 [2021-03-17] 

* bump to OpenWrt 19.07.7

## v2.6 [2021-02-17] 

* bump to OpenWrt 19.07.6
* bump alpine in builder image to 3.13

## v2.5 [2020-10-21]

* bump to OpenWrt 19.07.4

## v2.4 [2020-05-25]

* new option `--docker-opts OPTS` to pass additional docker options to docker-run
* examples upgraded to use OpenWrt 19.07.3
* new Raspberry Pi 4 example

## v2.3 [2020-01-26]

* changed: when using podman, run as root in container
* new: optionally disable services in `/etc/init.d` with variable `LEDE_DISABLED_SERVICES`

## v2.2 [2020-01-24]

* examples upgraded to use 19.07.0
 
## v2.1 [2019-12-01]

* new environment variable `REPOSITORIES_CONF` added to specify custom
  `repositories.conf` file
* replace `gosu` by `su-exec`

## v2.0 [2019-07-28]

* add new option `--dockerless` to allow dockerless operation using buildah
  and podman. 
* `build` option does now longer implicitly builds the docker image. Must now
  explicitly call `build-docker-image` before building an OpenWrt image.
* minor optimizations in Dockerfile

## v1.5 [2019-07-06]

* examples upgraded to use 18.06.4

## v1.4 [2019-03-29]

* build container now uses Alpine 3.9 as base image
* examples upgraded to use 18.06.2 

## v1.3 [2019-02-02]

* bumped version to OpenWRT 18.06.2
* new x86_64 example with info on how to run in qemu

## v1.2 [2018-09-01]

* `LEDE_BUILDER_URL` is now an optional parameter
* bumped version to OpenWRT 18.06.1
* simplified examples (by removing LEDE_BUILDER_URL)
* output dir will be automatically created
* minor changes

## v1.1 [2018-08-02] 

* Support for [OpenWRT 18.06](https://openwrt.org/releases/18.06/notes-18.06.0) added.
  Since LEDE and OpenWRT projects merged, all examples will now use OpenWRT.
* CI added (checks script and tries to build examples)

## v1.0 (2018-08-02)

Just tagged the last release for LEDE 17.01 / OpenWRT 15.05 before upgrading
to OpenWRT 18.06

