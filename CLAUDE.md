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
