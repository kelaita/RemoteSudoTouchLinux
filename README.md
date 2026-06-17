# remote-sudo-touch

`remote-sudo-touch` is the Linux-side helper and Debian package for the
RemoteSudoTouch system.

It is intended for Ubuntu or other Debian-based hosts where `sudo` is wired
through PAM. When `sudo` runs, `pam_exec` calls the helper, the helper connects
to a root-owned Unix socket at `/run/remote-sudo-touch.sock`, and a
socket-activated local bridge forwards that request through a reverse SSH
tunnel on `127.0.0.1:9876` to the macOS RemoteSudoTouch agent. The Mac prompts
with Touch ID and returns an approval or denial response.

The macOS manager app lives here:
[RemoteSudoTouch](https://github.com/kelaita/RemoteSudoTouch)

## Platform support

This package has been tested on Ubuntu only.

It may work on other Debian-based distributions, but that has not been verified.

## What this repo contains

- `pkgroot/`: package payload and Debian control scripts
- `scripts/build-deb.sh`: build script for the `.deb`
- `dist/`: local output directory for built packages

## Installed files

The package installs:

- `/usr/lib/remote-sudo-touch/remote-sudo-touch`
- `/usr/lib/remote-sudo-touch/remote-sudo-touch-bridge`
- `/usr/sbin/remote-sudo-touch-setup`
- `/usr/sbin/remote-sudo-touch-disable`
- `/etc/remote-sudo-touch/config.env`
- `/usr/lib/systemd/system/remote-sudo-touch.socket`
- `/usr/lib/systemd/system/remote-sudo-touch@.service`
- `/usr/share/remote-sudo-touch/pam/sudo-snippet`
- `/usr/share/doc/remote-sudo-touch/README.md`

## Expected topology

- The Linux helper connects to `/run/remote-sudo-touch.sock`
- A local socket-activated bridge connects to `127.0.0.1:9876`
- A reverse SSH tunnel exposes that TCP port on the Linux host
- The tunnel forwards traffic to the Mac at `127.0.0.1:8765`
- The macOS `RemoteSudoTouchAgent` receives the JSON request and prompts with
  Touch ID

## Build

Build on Ubuntu or another Debian-based environment with packaging tools
installed:

```bash
sudo apt-get update
sudo apt-get install -y dpkg-dev fakeroot
./scripts/build-deb.sh
```

Package version is read from the top-level `VERSION` file by default.

Current version:

```bash
cat VERSION
```

If you need to override it for a one-off build:

```bash
./scripts/build-deb.sh 1.0.1
```

The built package is written to `dist/`.

## Install

```bash
sudo dpkg -i dist/remote-sudo-touch_$(cat VERSION)_all.deb
sudo remote-sudo-touch-setup
```

## Strong warning

Editing `sudo` PAM files can break administrative access to the machine.

Before running `remote-sudo-touch-setup`:

- keep an existing root shell open
- make sure the Mac side is already configured
- make sure the reverse SSH tunnel is ready or can be started
- be prepared to run `sudo remote-sudo-touch-disable` if you want to roll back

## Manual verification

Before touching PAM, verify the helper itself:

```bash
sudo PAM_USER="$USER" PAM_SERVICE=sudo /usr/lib/remote-sudo-touch/remote-sudo-touch --dry-run
sudo PAM_USER="$USER" PAM_SERVICE=sudo /usr/lib/remote-sudo-touch/remote-sudo-touch
```

The first command only prints the request payload. The second should succeed
only after the local socket bridge is enabled and the reverse tunnel and Mac
agent are both reachable.

## Setup and rollback

Run:

```bash
sudo remote-sudo-touch-setup
```

The setup command:

- enables `remote-sudo-touch.socket`
- verifies `/run/remote-sudo-touch.sock`
- performs an end-to-end `health_check` through the bridge and tunnel
- inserts a managed PAM block into `/etc/pam.d/sudo`
- saves a backup under `/var/lib/remote-sudo-touch/backups/`

To disable it and remove the managed PAM block:

```bash
sudo remote-sudo-touch-disable
```

## Configuration

Edit:

```text
/etc/remote-sudo-touch/config.env
```

Supported settings:

- `REMOTE_SUDO_TOUCH_SOCKET=/run/remote-sudo-touch.sock`
- `REMOTE_SUDO_TOUCH_TUNNEL_HOST=127.0.0.1`
- `REMOTE_SUDO_TOUCH_TUNNEL_PORT=9876`
- `REMOTE_SUDO_TOUCH_CONNECT_TIMEOUT=2`
- `REMOTE_SUDO_TOUCH_RESPONSE_TIMEOUT=15`
- `REMOTE_SUDO_TOUCH_SELF_HEAL=1`
- `REMOTE_SUDO_TOUCH_TIMEOUT=30` legacy setting that applies to both timeouts

The helper connects to the Unix socket in `/run`. The local bridge behind that
socket connects to the reverse SSH tunnel endpoint on `127.0.0.1:<port>`.

When `REMOTE_SUDO_TOUCH_SELF_HEAL=1`, the local bridge will try to clear a
stale reverse-forward listener on `127.0.0.1:<port>` if a request times out or
returns an empty response, then retry once.

## Exit behavior

- `0`: approved
- `1`: denied or transport / protocol failure

## Notes

- This package does not create the reverse SSH tunnel
- The macOS side must already be configured and running through the
  RemoteSudoTouch app

## Release flow

Typical release flow:

1. Update the package contents under `pkgroot/`
2. Update `VERSION` if needed
3. Build a new `.deb` with `./scripts/build-deb.sh`
4. Upload the artifact from `dist/` to a GitHub release or APT repository
