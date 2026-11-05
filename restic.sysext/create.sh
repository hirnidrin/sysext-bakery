#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# restic sysext bakery extension.
#

# No units ship, so systemd has nothing to learn on merge.
RELOAD_SERVICES_ON_MERGE="false"

function list_available_versions() {
  list_github_releases "restic" "restic"
}
# --

function populate_sysext_root() {
  local sysextroot="$1"
  local arch="$2"
  local version="$3"

  local rel_arch="$(arch_transform "x86-64" "amd64" "$arch")"
  local file="restic_${version#v}_linux_${rel_arch}.bz2"
  local base="https://github.com/restic/restic/releases/download/${version}"

  curl --fail --silent --show-error --location --remote-name "${base}/${file}"
  curl --fail --silent --show-error --location --remote-name "${base}/SHA256SUMS"
  sha256sum --check --ignore-missing --strict SHA256SUMS
  bunzip2 "${file}"

  mkdir -p "${sysextroot}/usr/bin"
  install -m 0755 "${file%.bz2}" "${sysextroot}/usr/bin/restic"
}
# --
