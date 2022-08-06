Some tests that are run after the images are built. This is used in the CI
to make sure images are built as expected.

Usage: `./run_all.sh <configuraion> <output-directory>`

Example:

```shell
$ ./.test/run_all.sh example-x86_64.conf output
```
