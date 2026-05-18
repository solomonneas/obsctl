#!/usr/bin/env bash
# Install obsctl to ~/.local/bin/ (no sudo needed).
# https://github.com/solomonneas/obsctl
set -euo pipefail

DEST="${OBSCTL_INSTALL_DIR:-$HOME/.local/bin}"
mkdir -p "$DEST"

SRC="$(cd "$(dirname "$0")" && pwd)/obsctl"
if [[ ! -f "$SRC" ]]; then
    echo "install.sh: cannot find obsctl next to this script" >&2
    exit 1
fi

install -m 0755 "$SRC" "$DEST/obsctl"
echo "installed: $DEST/obsctl"

case ":$PATH:" in
    *":$DEST:"*) ;;
    *) echo "note: $DEST is NOT on your PATH yet. Add this to your shell rc:"
       echo "    export PATH=\"$DEST:\$PATH\"" ;;
esac

echo
echo "Next steps:"
echo "  1. Make sure 'obs-cmd' is on PATH (https://github.com/grigio/obs-cmd)"
echo "  2. Run: obsctl init"
echo "  3. Edit ~/.config/obsctl/hosts.env with your OBS hosts + passwords"
echo "  4. Try: obsctl <alias> info"
