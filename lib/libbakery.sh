#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# Copyright (c) 2025 the Flatcar Maintainers.
# Use of this source code is governed by the Apache 2.0 license.
#
# Bakery library functions umbrella include file.
# Source this file to get access to all library functions.

libroot="$(dirname "${BASH_SOURCE[0]}")"
scriptroot="$(cd "$(dirname "${BASH_SOURCE[0]}")/../"; pwd)"

# In GitHub Actions this resolves to the repo the workflow runs in (i.e. this
#  fork), so releases are looked up and published there rather than upstream.
# A local ".env" (sourced below) still overrides it.
bakery="${GITHUB_REPOSITORY:-flatcar/sysext-bakery}"
bakery_hub="extensions.flatcar.org"

if [[ -s "${scriptroot}/.env" ]]; then
  source "${scriptroot}/.env"
fi

# Base URL the generated sysupdate .conf files fetch extension images from.
# A GitHub release serves assets at "<base>/<tag>/<file>", which is exactly the
#  layout systemd-sysupdate expects of a url-file source: it appends
#  "/SHA256SUMS" to enumerate versions and "/<filename>" to fetch them. Since
#  the per-extension metadata release carries both the manifest and the images,
#  this needs no redirecting web server (that is what "bakery_hub" is for
#  upstream, where releases are split across per-version tags).
# Resolved after ".env" so both this and "bakery" stay overridable.
bakery_base="${bakery_base:-https://github.com/${bakery}/releases/download}"

# Add new library function scripts here:
source "${libroot}/helpers.sh"
source "${libroot}/generate.sh"
source "${libroot}/list.sh"
source "${libroot}/boot.sh"
source "${libroot}/test.sh"
