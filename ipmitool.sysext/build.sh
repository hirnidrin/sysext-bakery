#!/bin/ash
#
# Build script helper for the ipmitool sysext.
# This script runs inside an ephemeral alpine container.
# It builds a static ipmitool / ipmievd and exports the binaries to a
#  bind-mounted volume.
# See https://codeberg.org/IPMITool/ipmitool/src/branch/master/README for
#  build instructions.
#
set -euo pipefail

version="$1"
export_user_group="$2"

# Upstream tags releases as e.g. "IPMITOOL_1_8_19".
tag="IPMITOOL_$(echo "${version}" | tr '.' '_')"

apk --no-cache add \
  autoconf \
  automake \
  build-base \
  curl \
  libtool \
  linux-headers \
  m4 \
  make \
  ncurses-dev \
  ncurses-static \
  openssl-dev \
  openssl-libs-static \
  readline-dev \
  readline-static

cd /opt
curl -fsSL --retry 5 --retry-connrefused -o ipmitool.tar.gz \
  "https://codeberg.org/IPMITool/ipmitool/archive/${tag}.tar.gz"
tar -xzf ipmitool.tar.gz
cd /opt/ipmitool

autoreconf -vif

# "LDFLAGS=-static" makes configure's link tests use the static libs, so the
#  libcrypto / readline checks reflect what the final static link can do.
# "LIBS=-lncurses" is required for the static readline check to link;
#  libreadline.a needs the terminfo symbols from libncurses.a.
# lanplus (IPMI 2.0 RMCP+) is what pulls in openssl, ipmishell needs readline.
CFLAGS='-Os' \
LDFLAGS='-static' \
LIBS='-lncurses' \
  ./configure \
    --prefix=/usr \
    --exec-prefix=/usr \
    --bindir=/usr/bin \
    --sbindir=/usr/bin \
    --sysconfdir=/etc \
    --mandir=/usr/share/man \
    --localstatedir=/var \
    --enable-ipmievd \
    --enable-ipmishell \
    --enable-intf-lan \
    --enable-intf-lanplus \
    --enable-intf-open \
    --enable-intf-serial \
    --disable-intf-bmc \
    --disable-intf-free \
    --disable-intf-imb \
    --disable-intf-lipmi \
    --disable-intf-usb \
    --disable-internal-md5

# WARNING: NEVER ship /usr/sbin in a sysext - hence "--sbindir=/usr/bin" above,
#  which puts ipmievd next to ipmitool in /usr/bin.

# ipmitool and ipmievd are linked through libtool, which swallows a plain
#  "-static" instead of passing it on to the compiler. "-all-static" is
#  libtool's way of asking for a fully static binary. It cannot be used for
#  ./configure above because configure links its test programs with plain gcc.
make LDFLAGS='-all-static'
make DESTDIR=/install_root install-strip

# "make install" pulls the IANA private enterprise number registry (used to
#  print vendor names instead of numeric IDs) from a URL that has served an
#  HTML landing page rather than the registry for years - see the
#  "fix-downloaded-iana-file" patch distros carry. We do not ship the registry,
#  so drop whatever was fetched instead of shipping a bogus lookup table.
# Users who want the lookups can place the real file, from
#  https://www.iana.org/assignments/enterprise-numbers.txt , in
#  ~/.local/share/misc/enterprise-numbers on the host - ipmitool checks that
#  location before the one in /usr/share/misc.
rm -f /install_root/usr/share/misc/enterprise-numbers
rmdir /install_root/usr/share/misc

# A sysext must be self-contained: fail the build rather than ship a binary
#  that expects libraries from the host.
for bin in /install_root/usr/bin/ipmitool /install_root/usr/bin/ipmievd ; do
  if readelf -d "${bin}" | grep -q NEEDED ; then
    echo "ERROR: '${bin}' is not statically linked:"
    readelf -d "${bin}"
    exit 1
  fi
done

# Guard against a silently crypto-less build: configure disables lanplus
#  (i.e. all remote IPMI 2.0 access) when it cannot link against libcrypto.
help_output="$(/install_root/usr/bin/ipmitool -h 2>&1 || true)"
case "${help_output}" in
  *lanplus*) ;;
  *) echo "ERROR: the lanplus interface is missing from this build:"
     echo "${help_output}"
     exit 1;;
esac

chown -R "$export_user_group" /install_root
