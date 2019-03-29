# Changelog for lede-dockerbuilder

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

