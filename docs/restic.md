# restic sysext

This sysext ships [restic](https://github.com/restic/restic), a backup program,
as the upstream static binary. The download is verified against upstream's
`SHA256SUMS` at build time.

It installs `/usr/bin/restic`, and no units.

## Usage

Download and merge the sysext at provisioning time using the below butane
snippet. It is for restic v0.19.1; adjust the version as needed. Only x86-64
images are published - see [Building](#building) for arm64.

```yaml
variant: flatcar
version: 1.0.0

storage:
  files:
    - path: /opt/extensions/restic/restic-v0.19.1-x86-64.raw
      mode: 0644
      contents:
        source: https://github.com/hirnidrin/sysext-bakery/releases/download/restic-v0.19.1/restic-v0.19.1-x86-64.raw
  links:
    - target: /opt/extensions/restic/restic-v0.19.1-x86-64.raw
      path: /etc/extensions/restic.raw
      hard: false
```

## Building

```
./bakery.sh list restic                      # available upstream versions
./bakery.sh create restic v0.19.1             # x86-64
./bakery.sh create restic v0.19.1 --arch arm64
```

The release pipeline only publishes x86-64 (`release_arches` in
`lib/libbakery.sh`). Building arm64 locally works fine; to publish it too, set
`release_arches="x86-64 arm64"`.