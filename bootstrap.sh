#!/usr/bin/env bash
set -euo pipefail

SCRIPT_VERSION="1.1.0"
REPO_URL="https://github.com/im-BowenGu/RoboconOxonServer-Nix.git"
CONFIG_DIR="/root/.config/system-manager"
VERSION_FILE="/opt/robocon-version"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

cleanup() { local ec=$?; if [ $ec -ne 0 ] && [ $ec -ne 130 ]; then error "Bootstrap failed."; fi; }
trap cleanup EXIT

if [ "$(id -u)" -ne 0 ]; then
  error "Must be run as root. Try: curl -fsSL https://raw.githubusercontent.com/im-BowenGu/RoboconOxonServer-Nix/master/bootstrap.sh | sudo bash"
  exit 1
fi

if [ "${1:-}" = "--version" ] || [ "${1:-}" = "-v" ]; then
  echo "RoboconOxonServer-Nix bootstrap v${SCRIPT_VERSION}"
  exit 0
fi

if ! command -v curl &>/dev/null; then
  error "curl is required."
  exit 1
fi

# Nix check
if command -v nix &>/dev/null && nix --version &>/dev/null 2>&1; then
  info "Nix already installed: $(nix --version 2>/dev/null)"
  . /nix/var/nix/profiles/default/etc/profile.d/nix.sh 2>/dev/null || true
else
  info "Installing Nix via Determinate Nix installer..."
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
  . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
fi

# Git check
if ! command -v git &>/dev/null; then
  info "Installing git..."
  nix profile install nixpkgs#git
fi

# Clone or pull config
if [ -d "$CONFIG_DIR" ]; then
  info "Existing config found, pulling updates..."
  cd "$CONFIG_DIR"
  git remote set-url origin "$REPO_URL" 2>/dev/null || true
  git pull
else
  info "Cloning config repository..."
  git clone "$REPO_URL" "$CONFIG_DIR"
  cd "$CONFIG_DIR"
fi

# Version tracking
if [ -f VERSION ]; then
  DESIRED_VER=$(cat VERSION)
  echo "$DESIRED_VER" > "$VERSION_FILE"
  info "System version: $DESIRED_VER"
fi

# Apply system-manager
info "Applying system-manager configuration..."
nix run github:numtide/system-manager --accept-flake-config -- switch --flake .

# PATH setup for interactive use
if [ ! -f /etc/profile.d/system-manager.sh ]; then
  info "Adding /run/system-manager/sw/bin to PATH..."
  cat > /etc/profile.d/system-manager.sh << 'SHEOF'
export PATH=/run/system-manager/sw/bin:$PATH
SHEOF
fi

export PATH="/run/system-manager/sw/bin:$PATH"

# Set 1panel password if 1pctl is available and not already set
if command -v 1pctl &>/dev/null; then
  if ! 1pctl user-info &>/dev/null 2>&1; then
    info "Setting 1Panel password..."
    sleep 1
    script -q -c '1pctl update password' /dev/null << 'EOF'
toor12345
toor12345
EOF
  fi
fi

info "=== Bootstrap complete ==="
echo "  nginx:      http://<host>/ (proxies to 1panel backend)"
echo "  1panel:     http://<host>:37490"
echo "  Username:   sqlite3 /opt/1panel/db/core.db 'SELECT key,value FROM settings;'"
echo "  Re-run:     curl -fsSL https://raw.githubusercontent.com/im-BowenGu/RoboconOxonServer-Nix/master/bootstrap.sh | sudo bash"
