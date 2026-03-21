#!/usr/bin/env bash
# =============================================================================
# install-docker-dockhand.sh
# Installs Docker Engine, Docker Compose plugin, and Dockhand on Ubuntu
# Usage: bash -c "$(curl -fsSL https://raw.githubusercontent.com/liosmar123/proxmox-utils/main/install-docker-dockhand.sh)"
# Tested on: Ubuntu 22.04 LTS / 24.04 LTS
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${GREEN}[✔]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
info() { echo -e "${CYAN}[→]${RESET} $*"; }
die()  { echo -e "${RED}[✘] ERROR:${RESET} $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root: sudo bash $0"

DOCKHAND_PORT="${DOCKHAND_PORT:-3000}"
DOCKHAND_DATA="${DOCKHAND_DATA:-dockhand_data}"
TARGET_USER="${SUDO_USER:-${USER}}"
COMPOSE_DIR="/opt/dockhand"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Docker + Dockhand Installer for Ubuntu     ║${RESET}"
echo -e "${BOLD}║   github.com/liosmar123/proxmox-utils        ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""

# =============================================================================
# 1. UPDATE SYSTEM
# =============================================================================
echo -e "${BOLD}── 1/4 · Updating system ──────────────────────${RESET}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold"

apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common \
  apt-transport-https

log "System updated."

# =============================================================================
# 2. INSTALL DOCKER ENGINE
# =============================================================================
echo ""
echo -e "${BOLD}── 2/4 · Installing Docker Engine ─────────────${RESET}"

if command -v docker &>/dev/null; then
  warn "Docker already installed ($(docker --version)). Skipping."
else
  info "Adding Docker official GPG key and repository..."
  install -m 0755 -d /etc/apt/keyrings

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt-get update -y
  apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  log "Docker Engine installed."
fi

systemctl enable --now docker
log "Docker service enabled and running."

if [[ -n "$TARGET_USER" && "$TARGET_USER" != "root" ]]; then
  usermod -aG docker "$TARGET_USER"
  log "User '$TARGET_USER' added to docker group."
  warn "Log out and back in (or run 'newgrp docker') for group change to take effect."
fi

docker --version
docker compose version

# =============================================================================
# 3. INSTALL DOCKHAND
# =============================================================================
echo ""
echo -e "${BOLD}── 3/4 · Installing Dockhand ──────────────────${RESET}"

mkdir -p "$COMPOSE_DIR"
info "Writing docker-compose.yml to $COMPOSE_DIR ..."

cat > "$COMPOSE_DIR/docker-compose.yml" <<EOF
# Dockhand - Modern Docker Management UI
# https://dockhand.pro

services:
  dockhand:
    image: fnsys/dockhand:latest
    container_name: dockhand
    restart: unless-stopped
    ports:
      - "${DOCKHAND_PORT}:3000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${DOCKHAND_DATA}:/app/data
    environment:
      TZ: America/Chicago

volumes:
  ${DOCKHAND_DATA}:
EOF

info "Pulling and starting Dockhand..."
docker compose -f "$COMPOSE_DIR/docker-compose.yml" pull
docker compose -f "$COMPOSE_DIR/docker-compose.yml" up -d

log "Dockhand is running."

# =============================================================================
# 4. CLEANUP
# =============================================================================
echo ""
echo -e "${BOLD}── 4/4 · Cleanup ──────────────────────────────${RESET}"

apt-get -f install -y
apt-get autoremove -y
apt-get autoclean -y

log "Cleanup complete."

# =============================================================================
# SUMMARY
# =============================================================================
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║          INSTALLATION COMPLETE               ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${CYAN}Docker:${RESET}      $(docker --version)"
echo -e "  ${CYAN}Compose:${RESET}     $(docker compose version)"
echo ""
echo -e "  ${CYAN}Dockhand UI:${RESET}"
echo -e "    Local ->  ${GREEN}http://localhost:${DOCKHAND_PORT}${RESET}"
echo -e "    LAN   ->  ${GREEN}http://${SERVER_IP}:${DOCKHAND_PORT}${RESET}"
echo ""
echo -e "  ${CYAN}Compose file:${RESET} ${COMPOSE_DIR}/docker-compose.yml"
echo ""
echo -e "  ${YELLOW}Useful commands:${RESET}"
echo -e "    Logs:    docker compose -f ${COMPOSE_DIR}/docker-compose.yml logs -f"
echo -e "    Stop:    docker compose -f ${COMPOSE_DIR}/docker-compose.yml down"
echo -e "    Update:  docker compose -f ${COMPOSE_DIR}/docker-compose.yml pull && \\"
echo -e "             docker compose -f ${COMPOSE_DIR}/docker-compose.yml up -d"
echo ""
