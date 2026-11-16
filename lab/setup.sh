#!/bin/bash
#
# Build the lab images used by every scenario in this repo.
#
#   ./setup.sh build     build uts-openssl, uts-kali-tools, uts-dnsmasq
#   ./setup.sh verify    show which images and networks exist
#   ./setup.sh cleanup   remove the lab images and any leftover lab networks
#
# The images are private to this lab and derived from public bases
# (alpine, kalilinux/kali-rolling, nginx:alpine). Nothing here touches the host
# network: lab scenarios use Docker networks marked `internal: true`.

set -euo pipefail

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES=(uts-openssl uts-kali-tools uts-dnsmasq)

need_docker() {
  command -v docker >/dev/null || { echo "${RED}docker not installed${NC}"; exit 1; }
  docker compose version >/dev/null 2>&1 || { echo "${RED}docker compose v2 not available${NC}"; exit 1; }
  echo "${GREEN}docker:${NC} $(docker --version)"
}

build() {
  need_docker
  for img in "${IMAGES[@]}"; do
    echo "${BLUE}==> building ${img}${NC}"
    docker build -t "$img" "$SCRIPT_DIR/images/$img"
  done
  echo "${BLUE}==> pulling base images${NC}"
  docker pull alpine:3.20
  docker pull nginx:alpine
  docker pull kalilinux/kali-rolling
  echo "${GREEN}done${NC}"
}

verify() {
  echo "${YELLOW}-- images --${NC}"
  for img in "${IMAGES[@]}"; do
    if docker image inspect "$img" >/dev/null 2>&1; then
      echo "${GREEN}ok${NC}   $img"
    else
      echo "${RED}miss${NC} $img"
    fi
  done
  echo "${YELLOW}-- lab networks --${NC}"
  docker network ls --filter name=lab- --format '{{.Name}}'
}

cleanup() {
  for img in "${IMAGES[@]}"; do
    docker image rm -f "$img" >/dev/null 2>&1 && echo "removed image $img" || true
  done
  for net in $(docker network ls --filter name=lab- --format '{{.Name}}'); do
    docker network rm "$net" >/dev/null 2>&1 && echo "removed network $net" || true
  done
  echo "${GREEN}cleanup done${NC}"
}

case "${1:-}" in
  build)   build ;;
  verify)  verify ;;
  cleanup) cleanup ;;
  *) echo "usage: $0 {build|verify|cleanup}"; exit 1 ;;
esac
