#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/im-BowenGu/RoboconOxonServer-Nix.git"
CONFIG_DIR="/root/.config/system-manager"

echo "=== Installing Nix (Determinate Nix) ==="
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm

echo "=== Sourcing Nix ==="
. /nix/var/nix/profiles/default/etc/profile.d/nix.sh

echo "=== Installing git for bootstrap ==="
nix profile install nixpkgs#git

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

echo "=== Adding system-manager to PATH ==="
cat > /etc/profile.d/system-manager.sh << 'SHEOF'
export PATH=/run/system-manager/sw/bin:$PATH
SHEOF

echo "=== Setting 1Panel password ==="
sleep 2
export PATH="/run/system-manager/sw/bin:$PATH"
script -q -c '1pctl update password' /dev/null << 'EOF'
toor12345
toor12345
EOF

echo "=== Done ==="
echo "1Panel default username is printed above in the 1panel-core service logs"
echo "Check it with: sqlite3 /opt/1panel/db/core.db \"SELECT key,value FROM settings;\""
echo "1Panel UI: https://<host>:37490"
