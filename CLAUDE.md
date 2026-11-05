# Reference documentation

Consult these when working in this repo — prefer them over guessing at bakery or sysext behaviour:

- <https://flatcar.github.io/sysext-bakery/> — the bakery: available extensions, per-extension usage and Butane snippets, and how to build/add an extension. Rendered from this repo's `docs/`, so a change here should keep that page correct.
- <https://www.flatcar.org/docs/latest/sys-ext/> — how sysexts behave on Flatcar: merging at boot, `/etc/extensions`, systemd-sysupdate, baking extensions into OS images.

# Repo setup

This is a fork of [flatcar/sysext-bakery](https://github.com/flatcar/sysext-bakery), hosted at `origin` (hirnidrin/sysext-bakery).

## Branches

- **`main`** — the user's individual bakery: upstream content plus their own changes/additions. Tracks `origin/main`.
- **`upstream-main`** — a 1:1 mirror of flatcar's `main` branch. Tracks `origin/upstream-main`.

There is no local `upstream` remote — only `origin`.

## Sync workflow

Upstream syncing is done manually by the user, in this order:

1. On GitHub's web UI, while viewing the `upstream-main` branch, use the "Sync fork" button to fast-forward it from `flatcar:main`. (This works because GitHub's per-branch sync compares against the parent repo's default branch regardless of local branch name.)
2. Locally: `git checkout upstream-main && git pull` (pulls from `origin/upstream-main`, now up to date).
3. `git checkout main && git merge upstream-main`, resolve any conflicts.
4. `git push` (pushes `main` to `origin/main`).

Do not add an `upstream` remote or attempt to pull from flatcar directly — the user handles that step via GitHub's UI.

# Build and release pipeline

This fork builds and hosts **only its own extensions** (currently just `ipmitool`), x86-64 only, served to `systemd-sysupdate` directly from this repo's GitHub releases. `README.md` documents the *what* for users; the below is the *how*, for working on it.

## Flow

`.github/workflows/release.yaml` — manually triggered (`workflow_dispatch` only; no cron — these two extensions don't update often enough to warrant a daily check), four chained jobs:

1. `list-builds` → `release_dispatcher.sh`: reads `release_build_versions.txt`, expands `latest` via `bakery.sh list <ext> --latest true` (queries the *upstream project's* API), skips anything already released here, emits `builds` (`ext:version`) and `extensions` JSON.
2. `create-release` → `release.sh <ext>:<ver>`: builds each arch in `$release_arches`, force-pushes tag `<ext>-<ver>`, publishes `.raw` + `.conf` + `SHA256SUMS` + build logs there.
3. `update-extension-metadata` → `release_meta.sh <ext>`: aggregates all versions' assets into the rolling `<ext>` tag — manifest **and** images, so it works as a sysupdate source.
4. `update-global-metadata` → `release_meta.sh`: aggregate `SHA256SUMS` release. Walks *all* `*.sysext` dirs, so it logs ~35 `SKIPPED` lines for extensions we don't build. Expected, not a fault.

`release_build_versions.txt` is the sole gate on what gets built. Upstream's other `*.sysext` dirs stay in the tree so merges stay clean; they simply never build.

## Configuration

All in `lib/libbakery.sh`, all overridable from `.env` — but **`.env` is gitignored, so CI never sees it**. That is why the defaults derive from `$GITHUB_REPOSITORY`, which Actions sets to this fork:

- `bakery` — repo whose releases are read and written.
- `bakery_base` — base URL baked into generated sysupdate `.conf` files. Resolved *after* `.env` so it follows an overridden `bakery`.
- `release_arches` — arches the release pipeline builds (`x86-64`; upstream builds arm64 too, but it is an emulated build and dominates run time). Does not affect `bakery.sh create --arch`.

## Why no redirector

`systemd-sysupdate`'s `url-file` source only needs a base URL where `<base>/SHA256SUMS` enumerates versions and `<base>/<filename>` fetches them. A GitHub release serves assets at exactly that layout, so the rolling `<ext>` release *is* the update source. Upstream needs `extensions.flatcar.org` (a Caddy redirector, `tools/http-url-rewrite-server/`) only because it splits images across per-version tags. `Verify=false` in the generated conf disables just the GPG check on the manifest — payload hashes are always verified.

## Gotchas

- **Never run `release.sh` or `release_meta.sh` locally** — both end in `git push origin <tag> --force`.
- Dry-run the dispatcher safely: `GITHUB_REPOSITORY=hirnidrin/sysext-bakery GITHUB_OUTPUT=/tmp/out ./release_dispatcher.sh` (read-only).
- **Re-running the release workflow is a no-op if the release already exists** — `builds`/`extensions` come back empty and every downstream job is gated off. To force a rebuild, delete the **release** on GitHub (the tag is irrelevant, it gets force-pushed).
- A `.conf` is generated at *build* time and stored in the per-version release; the metadata jobs only copy it. So changing `bakery_base` requires a rebuild — "Force an update to all metadata" will faithfully re-publish the stale conf.
- `report-missing-extension-docs.yaml` opens issues on any push touching `release_build_versions.txt` for extensions lacking docs.

## Adding an extension

`<name>.sysext/create.sh` (+ optional `files/`, `test.sh`) → `docs/<name>.md` → row in `docs/index.md` → line in `release_build_versions.txt` → row in the README table. The README's version column and the modified-files table there are hand-maintained; keep them true.
