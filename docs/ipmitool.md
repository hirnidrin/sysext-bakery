# ipmitool sysext

This sysext ships [ipmitool](https://codeberg.org/IPMITool/ipmitool), a command
line utility for managing IPMI-enabled devices - reading sensors, querying FRU
inventory and the system event log, and controlling chassis power both locally
(via the BMC of the machine it runs on) and remotely over the network.

The sysext is built from upstream source inside an ephemeral Alpine container
and is fully statically linked, so it has no dependencies on the host OS.

It installs:

- `/usr/bin/ipmitool` - the CLI, with the `open`, `lan`, `lanplus` and `serial`
  interfaces and the interactive `ipmitool shell` compiled in.
- `/usr/bin/ipmievd` - the IPMI event daemon, which forwards BMC events to the
  journal. Note that upstream installs this to `sbin`; a sysext must never ship
  `/usr/sbin` (it is a symlink to `/usr/bin` on Flatcar), so it lives in
  `/usr/bin` here.
- `/usr/lib/systemd/system/ipmievd.service` - a unit for the above. It is not
  enabled by default; see below.

The IANA private enterprise number registry (`enterprise-numbers`) is not
shipped, so OEM vendors are reported by number (`IANA 674`) rather than by name
(`Dell Inc.`). It would add ~2 MB to the image and make every build depend on
`iana.org`. If you want the lookups, download
<https://www.iana.org/assignments/enterprise-numbers.txt> to
`~/.local/share/misc/enterprise-numbers` on the host - ipmitool checks that
location before the one in `/usr/share/misc`.

Note that ipmitool's own build fetches that registry from a URL that has served
an HTML page instead of the data for years (distros carry a patch for this), so
a stock `make install` silently installs a useless lookup table. The bakery
build script deletes it.

## Usage

Download and merge the sysext at provisioning time using the below butane
snippet. It is for the x86-64 version of ipmitool 1.8.19; adjust version and
architecture as needed.

```yaml
variant: flatcar
version: 1.0.0

storage:
  files:
    - path: /opt/extensions/ipmitool/ipmitool-1.8.19-x86-64.raw
      mode: 0644
      contents:
        source: https://github.com/hirnidrin/sysext-bakery/releases/download/ipmitool-1.8.19/ipmitool-1.8.19-x86-64.raw
    # Only needed for talking to the local BMC (see below).
    - path: /etc/modules-load.d/ipmi.conf
      mode: 0644
      contents:
        inline: |
          ipmi_devintf
          ipmi_si
  links:
    - target: /opt/extensions/ipmitool/ipmitool-1.8.19-x86-64.raw
      path: /etc/extensions/ipmitool.raw
      hard: false
```

### Remote access

Nothing beyond the extension itself is required to manage other machines' BMCs
over the network:

```
ipmitool -I lanplus -H bmc.example.org -U admin -P '...' sensor list
ipmitool -I lanplus -H bmc.example.org -U admin -P '...' chassis power status
```

### Local access

Talking to the BMC of the machine ipmitool runs on (`-I open`, the default)
goes through `/dev/ipmi0`, which requires the OpenIPMI kernel modules. They are
present in the Flatcar kernel but are not loaded automatically, hence the
`/etc/modules-load.d/ipmi.conf` file in the snippet above. It is written to
`/etc` on purpose: `systemd-modules-load.service` is not ordered against
`systemd-sysext.service`, so a `modules-load.d` file shipped inside the sysext
would not reliably be picked up at boot.

Some platforms need `ipmi_ssif` instead of `ipmi_si`; check `dmesg` if
`/dev/ipmi0` does not appear.

### Event daemon

To also log BMC events (fan failures, thermal trips, power events) to the
journal, enable `ipmievd.service` by adding this to the snippet:

```yaml
  links:
    - path: /etc/systemd/system/multi-user.target.wants/ipmievd.service
      target: /usr/lib/systemd/system/ipmievd.service
      overwrite: true
```

The service defaults to the `open` event interface. Set
`IPMIEVD_OPTIONS=sel` in `/etc/sysconfig/ipmievd` to poll the system event log
instead. The unit `modprobe`s the IPMI modules itself, so it works without the
`modules-load.d` file above.

## Automatic updates

Updates are served straight from this repository's GitHub releases - no
redirecting web server is involved, unlike the upstream bakery with its
`extensions.flatcar.org` hub.

`systemd-sysupdate` needs its source URL to be a directory holding a
`SHA256SUMS` manifest plus the files that manifest lists. A GitHub release
serves its assets at exactly that layout, so the rolling
[`ipmitool`](https://github.com/hirnidrin/sysext-bakery/releases/tag/ipmitool)
release - which carries every published image alongside the aggregated
manifest - works as a sysupdate source as-is. That URL is what
`bakery.sh create ... --sysupdate true` writes into `ipmitool.conf`, via
`bakery_base` in `lib/libbakery.sh` (override it in `.env` to serve from
somewhere else).

`Verify=false` in the generated config only disables the GPG signature check on
the manifest; the downloaded images are always verified against the SHA256
hashes it lists.

Add this to the snippet above to update automatically. Note that sysupdate only
*stages* a new image - the drop-in below flags a reboot when the symlink
changed, and the extension starts being used after that reboot:

```yaml
storage:
  files:
    - path: /etc/sysupdate.ipmitool.d/ipmitool.conf
      contents:
        source: https://github.com/hirnidrin/sysext-bakery/releases/download/ipmitool/ipmitool.conf
    # sysupdate refuses to run without at least one transfer in the default
    #  directory, so give it one that never matches anything.
    - path: /etc/sysupdate.d/noop.conf
      contents:
        inline: |
          [Source]
          Type=regular-file
          Path=/
          MatchPattern=invalid@v.raw
          [Target]
          Type=regular-file
          Path=/
          MatchPattern=invalid@v.raw

systemd:
  units:
    - name: systemd-sysupdate.timer
      enabled: true
    - name: systemd-sysupdate.service
      dropins:
        - name: ipmitool.conf
          contents: |
            [Service]
            ExecStartPre=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/ipmitool.raw > /tmp/ipmitool"
            ExecStartPre=/usr/lib/systemd/systemd-sysupdate -C ipmitool update
            ExecStartPost=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/ipmitool.raw > /tmp/ipmitool-new"
            ExecStartPost=/usr/bin/sh -c "if ! cmp --silent /tmp/ipmitool /tmp/ipmitool-new; then touch /run/reboot-required; fi"
```

This requires the symlink form of `/etc/extensions/ipmitool.raw` used in the
snippet above - sysupdate updates the image in `/opt/extensions/ipmitool/` and
repoints the symlink at it. Check for updates by hand with:

```
systemd-sysupdate -C ipmitool list
systemd-sysupdate -C ipmitool update
```

## Building

```
./bakery.sh list ipmitool                      # available upstream versions
./bakery.sh create ipmitool 1.8.19             # x86-64
./bakery.sh create ipmitool 1.8.19 --arch arm64
```
