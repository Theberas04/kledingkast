#!/usr/bin/env bash
# Kledingkast installeren als Debian LXC op Proxmox VE, rechtstreeks vanaf GitHub.
# Uitvoeren op de Proxmox-host als root:
#   bash <(curl -fsSL https://raw.githubusercontent.com/Theberas04/kledingkast/main/deploy/proxmox/install.sh)
# Alleen ophalen/controleren zonder LXC aan te maken:
#   FETCH_ONLY=1 bash <(curl -fsSL https://raw.githubusercontent.com/Theberas04/kledingkast/main/deploy/proxmox/install.sh)
set -euo pipefail
REPO="${REPO:-Theberas04/kledingkast}"
BRANCH="${BRANCH:-main}"
RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/${REPO}/${BRANCH}}"
TARGET_DIR="${TARGET_DIR:-/root/kledingkast-proxmox}"
FETCH_ONLY="${FETCH_ONLY:-0}"
FILES=(
  "deploy/proxmox/create-kledingkast-lxc.sh"
  "deploy/proxmox/provision-kledingkast.sh"
  "deploy/proxmox/nginx-kledingkast.conf"
  "deploy/proxmox/update-from-github.sh"
  "deploy/proxmox/README.md"
  "server.js"
  "package.json"
  "public/index.html"
  "public/favicon.svg"
  "public/manifest.webmanifest"
  "public/sw.js"
  "public/icon-192.png"
  "public/icon-512.png"
  "public/icon-512-maskable.png"
  "public/apple-touch-icon.png"
  "public/social-card.png"
)
log(){ printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31m[fout]\033[0m %s\n' "$*" >&2; exit 1; }
if [ "$FETCH_ONLY" != 1 ]; then
  [ "$(id -u)" -eq 0 ] || die "Draai dit als root op de Proxmox-host."
  command -v pct >/dev/null 2>&1 || die "pct niet gevonden: dit is geen Proxmox VE-host."
  [ -e /etc/pve ] || die "/etc/pve ontbreekt: dit is geen Proxmox VE-host."
fi
command -v curl >/dev/null 2>&1 || die "curl ontbreekt; installeer curl en probeer opnieuw."
mkdir -p "$TARGET_DIR/deploy/proxmox" "$TARGET_DIR/public"
log "Bestanden ophalen uit GitHub ($REPO, $BRANCH)…"
for f in "${FILES[@]}"; do
  out="$TARGET_DIR/$f"; mkdir -p "$(dirname "$out")"
  curl -fsSL --retry 3 --max-time 60 "$RAW_BASE/$f" -o "$out" || die "Download mislukt: $f. Is de repository openbaar?"
  [ -s "$out" ] || die "Leeg bestand ontvangen: $f"
  log "  $f ($(wc -c <"$out") bytes)"
done
grep -q "Kledingkast" "$TARGET_DIR/public/index.html" || die "index lijkt geen Kledingkast-app."
grep -q '"display"' "$TARGET_DIR/public/manifest.webmanifest" || die "manifest lijkt geen geldig webapp-manifest."
grep -q 'pct create' "$TARGET_DIR/deploy/proxmox/create-kledingkast-lxc.sh" || die "LXC-script lijkt onvolledig."
for f in "$TARGET_DIR"/deploy/proxmox/*.sh; do bash -n "$f" || die "Syntaxfout in $f"; done
chmod +x "$TARGET_DIR"/deploy/proxmox/*.sh
if [ "$FETCH_ONLY" = 1 ]; then log "FETCH_ONLY=1: bestanden staan in $TARGET_DIR; er is niets geïnstalleerd."; exit 0; fi
cd "$TARGET_DIR/deploy/proxmox"
exec ./create-kledingkast-lxc.sh
