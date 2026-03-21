# remote-sudo-touch

`remote-sudo-touch` is the Ubuntu-side PAM helper for the RemoteSudoTouch system.
It connects to `127.0.0.1:<port>` and expects a reverse SSH tunnel to forward that
traffic to the macOS RemoteSudoTouchAgent process.

## Installed files

- `/usr/lib/remote-sudo-touch/remote-sudo-touch`
- `/etc/remote-sudo-touch/config.env`
- `/usr/share/remote-sudo-touch/pam/sudo-snippet`

## Expected tunnel topology

- Ubuntu PAM helper connects to `127.0.0.1:9876`
- Reverse SSH tunnel sends that to Mac `127.0.0.1:8765`
- The Mac Touch ID agent prompts the user and returns JSON approval

## Recommended rollout

1. Confirm the Mac app has already installed and started its agent and SSH tunnel.
2. Install this package on Ubuntu.
3. Test the helper manually:
   `sudo PAM_USER=$USER PAM_SERVICE=sudo /usr/lib/remote-sudo-touch/remote-sudo-touch --dry-run`
4. Only then add the PAM snippet to `/etc/pam.d/sudo`.
5. Keep a root shell open while testing PAM changes.

## PAM snippet

```pam
# RemoteSudoTouch sudo approval
auth sufficient pam_exec.so quiet /usr/lib/remote-sudo-touch/remote-sudo-touch
```

## Config

Edit `/etc/remote-sudo-touch/config.env`:

- `REMOTE_SUDO_TOUCH_PORT=9876`
- `REMOTE_SUDO_TOUCH_TIMEOUT=30`

## Exit behavior

- exit `0`: approved
- exit `1`: denied or error
