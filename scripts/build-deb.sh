#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PKGROOT="$ROOT_DIR/pkgroot"
OUT_DIR="$ROOT_DIR/dist"
VERSION_FILE="$ROOT_DIR/VERSION"
PKG_NAME="remote-sudo-touch"
ARCH="all"
VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  if [[ ! -f "$VERSION_FILE" ]]; then
    echo "VERSION file not found at $VERSION_FILE" >&2
    exit 1
  fi

  VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
  if [[ -z "$VERSION" ]]; then
    echo "VERSION file is empty." >&2
    exit 1
  fi
fi

OUT_FILE="$OUT_DIR/${PKG_NAME}_${VERSION}_${ARCH}.deb"

if ! command -v dpkg-deb >/dev/null 2>&1; then
  echo "dpkg-deb is required to build the package." >&2
  echo "Run this script on Ubuntu or Debian with dpkg-dev installed." >&2
  exit 1
fi

if ! command -v fakeroot >/dev/null 2>&1; then
  echo "fakeroot is required to build the package." >&2
  echo "Run this script on Ubuntu or Debian with fakeroot installed." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

sed -i.bak -E "s/^Version: .*/Version: ${VERSION}/" "$PKGROOT/DEBIAN/control"
rm -f "$PKGROOT/DEBIAN/control.bak"

chmod 0755 "$PKGROOT/DEBIAN/postinst" "$PKGROOT/DEBIAN/prerm" "$PKGROOT/DEBIAN/postrm"
chmod 0755 "$PKGROOT/usr/lib/remote-sudo-touch/remote-sudo-touch"
chmod 0644 "$PKGROOT/DEBIAN/control" "$PKGROOT/etc/remote-sudo-touch/config.env"
chmod 0644 "$PKGROOT/usr/share/remote-sudo-touch/pam/sudo-snippet" "$PKGROOT/usr/share/doc/remote-sudo-touch/README.md"

fakeroot dpkg-deb --build "$PKGROOT" "$OUT_FILE"

echo "Built $OUT_FILE"
