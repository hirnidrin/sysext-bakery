# sysext-bakery (adapted)

This is an adapted / extended version of the [Flatcar Sysext Bakery](https://github.com/flatcar/sysext-bakery). Refer to the original repository for general information, usage, and developer documentation.

## Documentation

- [Sysext Bakery docs](https://flatcar.github.io/sysext-bakery/) — the bakery itself: available extensions, per-extension usage and Butane snippets, and how to build and add extensions. Rendered from this repo's `docs/`.
- [Flatcar system extensions](https://www.flatcar.org/docs/latest/sys-ext/) — how sysexts work on Flatcar: merging at boot, `/etc/extensions`, systemd-sysupdate, and baking extensions into OS images.

## Extensions built here

These are the extensions added by this fork. They are built and hosted in [this repository's releases](https://github.com/hirnidrin/sysext-bakery/releases), x86-64 only, and check for new upstream versions daily.

| Extension | Latest version | Documentation |
| --------- | -------------- | ------------- |
| `ipmitool` | [1.8.19](https://github.com/hirnidrin/sysext-bakery/releases/tag/ipmitool-1.8.19) | [docs/ipmitool.md](docs/ipmitool.md) |

The upstream bakery's own extensions are still present in this tree as build scripts, so they can be built locally with `./bakery.sh create <name> <version>`, but they are not released here — use [the upstream bakery](https://github.com/flatcar/sysext-bakery/releases) for those. What gets built and hosted is controlled by [`release_build_versions.txt`](release_build_versions.txt).

## Customizations

_TBD_
