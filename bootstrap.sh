#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${1:-https://github.com/your-org/debian-system-config}"
CONFIG_DIR="/root/.config/system-manager"

echo "=== Installing Nix (Determinate Nix) ==="
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm

echo "=== Sourcing Nix ==="
. /nix/var/nix/profiles/default/etc/profile.d/nix.sh

echo "=== Cloning system config ==="
if [ -d "$CONFIG_DIR" ]; then
  echo "Config already exists, pulling latest..."
  cd "$CONFIG_DIR" && git pull
else
  git clone "$REPO_URL" "$CONFIG_DIR"
fi

cd "$CONFIG_DIR"

echo "=== Applying system-manager configuration ==="
nix run github:numtide/system-manager --accept-flake-config -- switch --flake .

echo "=== Setting 1Panel password ==="
# First start auto-generates DB and default credentials
sleep 2
script -q -c '1pctl update password' /dev/null << 'EOF'
toor12345
toor12345
EOF

echo "=== Done ==="
echo "Login: ssh toor@<host>"
echo "1Panel UI: https://<host>:37490"
echo "Username: f8792f7deb (check /opt/1panel/db/core.db for current)"
