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

Upstream builds every extension listed in `release_build_versions.txt`, publishes them to `flatcar/sysext-bakery` releases, and serves sysupdate through the `extensions.flatcar.org` redirector — that hub exists because upstream splits images across per-version release tags, which is not a layout `systemd-sysupdate` can consume directly.

This fork builds only its own extensions, publishes them to its own releases, and serves sysupdate straight from GitHub: a release already exposes its assets at `<base>/<tag>/<file>`, which is exactly what a `url-file` source needs (`<base>/SHA256SUMS` to enumerate versions, `<base>/<filename>` to fetch them). So the rolling per-extension release doubles as the update source, and no redirecting web server is needed.

Changes to upstream files:

| File | Change |
| ---- | ------ |
| [`release_build_versions.txt`](release_build_versions.txt) | Trimmed to this fork's extensions. Sole gate on what gets built. |
| [`lib/libbakery.sh`](lib/libbakery.sh) | `bakery` defaults to `$GITHUB_REPOSITORY` so CI reads and writes this fork's releases; added `bakery_base` (sysupdate source URL) and `release_arches`. All overridable via `.env`. |
| [`lib/sysupdate.conf.tmpl`](lib/sysupdate.conf.tmpl) | Source `Path=` built from `{BAKERY_BASE}` instead of the hub's `https://{BAKERY_HUB}/extensions/`. |
| [`lib/generate.sh`](lib/generate.sh) | Substitutes `{BAKERY_BASE}` when generating the sysupdate config. |
| [`release.sh`](release.sh) | Builds `$release_arches` rather than a hardcoded `x86-64 arm64`. |
| [`release_meta.sh`](release_meta.sh) | Per-extension metadata releases now also carry the `.raw` images, so the manifest and the files it lists sit under one URL. |
| [`.github/workflows/release.yaml`](.github/workflows/release.yaml) | Uploads `*.raw` to the per-extension release. |
| [`.github/workflows/update-all-metadata.yaml`](.github/workflows/update-all-metadata.yaml) | Same. |

Everything else is additive: `ipmitool.sysext/`, its docs, and the devcontainer.
