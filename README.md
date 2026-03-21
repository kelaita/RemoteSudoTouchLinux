# remote-sudo-touch

`remote-sudo-touch` is the Linux-side helper and Debian package for the
RemoteSudoTouch system.

It is intended for Ubuntu or other Debian-based hosts where `sudo` is wired
through PAM. When `sudo` runs, `pam_exec` calls the helper, the helper connects
to `127.0.0.1:<port>`, and a reverse SSH tunnel forwards that request to the
macOS RemoteSudoTouch agent. The Mac prompts with Touch ID and returns an
approval or denial response.

The macOS manager app lives here:
[RemoteSudoTouch](https://github.com/kelaita/RemoteSudoTouch)

## What this repo contains

- `pkgroot/`: package payload and Debian control scripts
- `scripts/build-deb.sh`: build script for the `.deb`
- `dist/`: local output directory for built packages

## Installed files

The package installs:

- `/usr/lib/remote-sudo-touch/remote-sudo-touch`
- `/etc/remote-sudo-touch/config.env`
- `/usr/share/remote-sudo-touch/pam/sudo-snippet`
- `/usr/share/doc/remote-sudo-touch/README.md`

## Expected topology

- The Linux helper connects to `127.0.0.1:9876`
- A reverse SSH tunnel exposes that port on the Linux host
- The tunnel forwards traffic to the Mac at `127.0.0.1:8765`
- The macOS `RemoteSudoTouchAgent` receives the JSON request and prompts with
  Touch ID

## Build

Build on Ubuntu or another Debian-based environment with packaging tools
installed:

```bash
sudo apt-get update
sudo apt-get install -y dpkg-dev fakeroot
./scripts/build-deb.sh 0.1.0
```

The built package is written to `dist/`.

## Install

```bash
sudo dpkg -i dist/remote-sudo-touch_0.1.0_all.deb
```

## Strong warning

Editing `sudo` PAM files can break administrative access to the machine.

Before changing `/etc/pam.d/sudo`:

- keep an existing root shell open
- make one change at a time
- verify the helper works manually first
- be prepared to revert the PAM change immediately if `sudo` stops working

Do not blindly paste or automate PAM edits on a machine you cannot recover
easily.

## Manual verification

Before touching PAM, verify the helper itself:

```bash
sudo PAM_USER="$USER" PAM_SERVICE=sudo /usr/lib/remote-sudo-touch/remote-sudo-touch --dry-run
sudo PAM_USER="$USER" PAM_SERVICE=sudo /usr/lib/remote-sudo-touch/remote-sudo-touch
```

The first command only prints the request payload. The second should succeed
only if the reverse tunnel and the Mac agent are both reachable.

## PAM integration

After the manual helper test works, add the packaged snippet near the top of
`/etc/pam.d/sudo`, before the password-based auth line:

```pam
auth sufficient pam_exec.so quiet /usr/lib/remote-sudo-touch/remote-sudo-touch
```

The packaged reference snippet is also installed at:

```text
/usr/share/remote-sudo-touch/pam/sudo-snippet
```

Keep a root shell open while testing PAM changes so you do not lock yourself out
of administrative access.

## Configuration

Edit:

```text
/etc/remote-sudo-touch/config.env
```

Supported settings:

- `REMOTE_SUDO_TOUCH_PORT=9876`
- `REMOTE_SUDO_TOUCH_TIMEOUT=30`

The helper always connects to `127.0.0.1`, so the transport path is expected to
be provided by the reverse SSH tunnel.

## Exit behavior

- `0`: approved
- `1`: denied or transport / protocol failure

## Notes

- This package does not auto-edit `/etc/pam.d/sudo`
- This package does not create the reverse SSH tunnel
- The macOS side must already be configured and running through the
  RemoteSudoTouch app

## Release flow

Typical release flow:

1. Update the package contents under `pkgroot/`
2. Build a new `.deb` with `./scripts/build-deb.sh <version>`
3. Upload the artifact from `dist/` to a GitHub release or APT repository
