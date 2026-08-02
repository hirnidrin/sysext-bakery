#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# ipmitool sysext bakery extension.
#

# Functions in this script will be called by bakery.sh.
# All library functions from lib/ will be available.

# We ship ipmievd.service, so systemd needs to learn about it on merge.
RELOAD_SERVICES_ON_MERGE="true"

# Fetch and print a list of available stable versions.
# Called by 'bakery.sh list <sysext>.
function list_available_versions() {
  # Upstream moved from GitHub to Codeberg (Forgejo). There are no "releases",
  #  only git tags of the form "IPMITOOL_1_8_19", which we normalise to
  #  "1.8.19". Release candidates ("..._1_8_15RC1") are filtered out by the
  #  match, and so are a handful of ancient non-conforming tags.
  curl -fsSL --retry-delay 1 --retry 60 --retry-connrefused \
       --retry-max-time 60 --connect-timeout 20 \
       "https://codeberg.org/api/v1/repos/IPMITool/ipmitool/tags?limit=100" \
    | jq -r '.[].name' \
    | sed --quiet -E 's/^IPMITOOL_([0-9]+)_([0-9]+)_([0-9]+)$/\1.\2.\3/p' \
    | sort -Vr
}
# --

# Download the application shipped with the sysext and populate the sysext root directory.
# This function runs in a subshell inside of a temporary work directory.
# It is safe to download / build directly in "./" as the work directory
#   will be removed after this function returns.
# Called by 'bakery.sh create <sysext>' with:
#   "sysextroot" - First positional argument.
#                    Root directory of the sysext to be created.
#   "arch"       - Second positional argument.
#                    Target architecture of the sysext.
#   "version"    - Third positional argument.
#                    Version number to build.
function populate_sysext_root() {
  local sysextroot="$1"
  local arch="$2"
  local version="$3"

  local img_arch="$(arch_transform 'x86-64' 'amd64' "$arch")"
  img_arch="$(arch_transform 'arm64' 'arm64/v8' "$img_arch")"

  local image="docker.io/alpine:3.21"

  announce "Building ipmitool $version for $arch"

  local user_group="$(id -u):$(id -g)"

  cp "${scriptroot}/ipmitool.sysext/build.sh" .
  docker run --rm \
    -i \
    -v "$(pwd)":/install_root \
    --platform "linux/${img_arch}" \
    ${image} \
        /install_root/build.sh "${version}" "$user_group"

  cp -aR usr "${sysextroot}"/
}
# --
