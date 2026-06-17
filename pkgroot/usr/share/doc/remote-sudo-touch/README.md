# remote-sudo-touch

`remote-sudo-touch` is the Ubuntu-side PAM helper for the RemoteSudoTouch
system. It connects to a root-owned Unix socket at
`/run/remote-sudo-touch.sock`. A socket-activated local bridge forwards each
request through the reverse SSH tunnel to the macOS RemoteSudoTouchAgent
process.

## Installed files

- `/usr/lib/remote-sudo-touch/remote-sudo-touch`
- `/usr/lib/remote-sudo-touch/remote-sudo-touch-bridge`
- `/usr/sbin/remote-sudo-touch-setup`
- `/usr/sbin/remote-sudo-touch-disable`
- `/etc/remote-sudo-touch/config.env`
- `/usr/lib/systemd/system/remote-sudo-touch.socket`
- `/usr/lib/systemd/system/remote-sudo-touch@.service`
- `/usr/share/remote-sudo-touch/pam/sudo-snippet`

## Expected tunnel topology

- Ubuntu PAM helper connects to `/run/remote-sudo-touch.sock`
- Local bridge connects to `127.0.0.1:9876`
- Reverse SSH tunnel sends that to Mac `127.0.0.1:8765`
- The Mac Touch ID agent prompts the user and returns JSON approval

## Recommended rollout

1. Confirm the Mac app has already installed and started its agent and SSH tunnel.
2. Install this package on Ubuntu.
3. Run `sudo remote-sudo-touch-setup`.
4. Test the helper manually:
   `sudo PAM_USER=$USER PAM_SERVICE=sudo /usr/lib/remote-sudo-touch/remote-sudo-touch --dry-run`
5. Keep a root shell open while testing PAM changes.

The setup command is reversible:

```bash
sudo remote-sudo-touch-disable
```

## PAM snippet

```pam
# RemoteSudoTouch sudo approval
auth sufficient pam_exec.so quiet seteuid /usr/lib/remote-sudo-touch/remote-sudo-touch
```

## Config

Edit `/etc/remote-sudo-touch/config.env`:

- `REMOTE_SUDO_TOUCH_SOCKET=/run/remote-sudo-touch.sock`
- `REMOTE_SUDO_TOUCH_TUNNEL_HOST=127.0.0.1`
- `REMOTE_SUDO_TOUCH_TUNNEL_PORT=9876`
- `REMOTE_SUDO_TOUCH_CONNECT_TIMEOUT=2`
- `REMOTE_SUDO_TOUCH_RESPONSE_TIMEOUT=15`
- `REMOTE_SUDO_TOUCH_SELF_HEAL=1`
- `REMOTE_SUDO_TOUCH_TIMEOUT=30` legacy setting that applies to both timeouts

When `REMOTE_SUDO_TOUCH_SELF_HEAL=1`, the local bridge will try to clear a
stale reverse-forward listener on `127.0.0.1:<port>` if a request times out or
returns an empty response, then retry once.

## Exit behavior

- exit `0`: approved
- exit `1`: denied or error
