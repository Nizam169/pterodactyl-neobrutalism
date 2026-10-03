#!/usr/bin/env bash
# =============================================================================
# remote-install.sh — Pasang tema Pterodactyl Neobrutalism sekali jalan
#
# One-liner (seperti installer pterodactyl):
#   curl -fsSL https://raw.githubusercontent.com/Nizam169/pterodactyl-neobrutalism/main/remote-install.sh | bash
#
# Dengan opsi:
#   curl -fsSL https://raw.githubusercontent.com/Nizam169/pterodactyl-neobrutalism/main/remote-install.sh | bash -s -- --full
#   curl -fsSL https://raw.githubusercontent.com/Nizam169/pterodactyl-neobrutalism/main/remote-install.sh | bash -s -- -d /var/www/pterodactyl
#   curl -fsSL https://raw.githubusercontent.com/Nizam169/pterodactyl-neobrutalism/main/remote-install.sh | bash -s -- --uninstall
#
# Bootstrap ini men-download repo ke temp sementara lalu menjalankan install.sh.
# Backup file asli disimpan permanen di /var/tmp/pterodactyl-neobrutalism/backups
# agar uninstall tetap bisa dilakukan meski folder sumber sudah dihapus.
# =============================================================================
set -euo pipefail

REPO="Nizam169/pterodactyl-neobrutalism"
BRANCH="main"
TMPDIR="$(mktemp -d /tmp/ptero-neobrutalism.XXXXXX)"
INSTALL_DIR="$TMPDIR/pterodactyl-neobrutalism"
PERSISTENT_BACKUP="/var/tmp/pterodactyl-neobrutalism/backups"

# Warna
C_RESET='\033[0m'; C_GREEN='\033[0;32m'; C_RED='\033[0;31m'; C_CYAN='\033[0;36m'
ok()   { printf "${C_GREEN}✓${C_RESET} %s\n" "$1"; }
err()  { printf "${C_RED}✗${C_RESET} %s\n" "$1" >&2; }
info() { printf "${C_CYAN}→${C_RESET} %s\n" "$1"; }

cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

# ── download repo ────────────────────────────────────────────────────────────
info "Download tema dari GitHub..."
if command -v git >/dev/null 2>&1; then
  git clone -q --depth 1 -b "$BRANCH" "https://github.com/${REPO}.git" "$INSTALL_DIR"
else
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    err "Butuh git, curl, atau wget untuk download. Install salah satunya dulu."
    exit 1
  fi
  TARBALL="$TMPDIR/theme.tar.gz"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz" -o "$TARBALL"
  else
    wget -q "https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz" -O "$TARBALL"
  fi
  tar -xzf "$TARBALL" -C "$TMPDIR"
  mv "$TMPDIR/${REPO#*/}-${BRANCH}" "$INSTALL_DIR"
fi
ok "Tema terdownload"

# ── jalankan installer asli, teruskan semua argumen ──────────────────────────
chmod +x "$INSTALL_DIR/install.sh"
export NB_BACKUP_DIR="$PERSISTENT_BACKUP"
mkdir -p "$PERSISTENT_BACKUP"

info "Menjalankan installer..."
"$INSTALL_DIR/install.sh" "$@"

printf "\n${C_DIM}Backup file asli tersimpan permanen di: $PERSISTENT_BACKUP${C_RESET}\n"
printf "${C_DIM}Folder sementara otomatis dibersihkan.${C_RESET}\n"
