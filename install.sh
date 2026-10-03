#!/usr/bin/env bash
# =============================================================================
# install.sh — Pterodactyl Neobrutalism Dark Theme installer
#
# Usage:
#   ./install.sh                     # pasang CSS inject ke panel (default)
#   ./install.sh -d /path/to/panel   # tentukan direktori panel
#   ./install.sh --full              # sekalian patch source React + rebuild
#   ./install.sh --uninstall         # kembalikan ke kondisi semula
#
# Aman & idempoten: file asli di-backup, menjalankan ulang tidak menduplikasi.
# =============================================================================
set -euo pipefail

# ── konfigurasi ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PANEL_DIR=""
DO_FULL=0
DO_UNINSTALL=0
# Backup disimpan di folder repo, kecuali di-override via env (dipakai oleh
# remote-install.sh yang berjalan dari temp sementara lalu dihapus).
BACKUP_DIR="${NB_BACKUP_DIR:-$SCRIPT_DIR/backups}"
TS="$(date +%Y%m%d-%H%M%S)"

# Warna
C_RESET='\033[0m'; C_BOLD='\033[1m'; C_GREEN='\033[0;32m'; C_RED='\033[0;31m'
C_YELL='\033[0;33m'; C_CYAN='\033[0;36m'; C_DIM='\033[2m'

ok()    { printf "${C_GREEN}✓${C_RESET} %s\n" "$1"; }
warn()  { printf "${C_YELL}!${C_RESET} %s\n" "$1"; }
err()   { printf "${C_RED}✗${C_RESET} %s\n" "$1" >&2; }
info()  { printf "${C_CYAN}→${C_RESET} %s\n" "$1"; }
step()  { printf "\n${C_BOLD}== %s ==${C_RESET}\n" "$1"; }

usage() {
  sed -n '3,12p' "${BASH_SOURCE[0]}" | sed 's/^#\s*//'
}

# ── argumen ──────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)   PANEL_DIR="${2:-}"; shift 2 ;;
    --full)     DO_FULL=1; shift ;;
    --uninstall) DO_UNINSTALL=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) err "Argumen tidak dikenal: $1"; usage; exit 1 ;;
  esac
done

# ── deteksi direktori panel ──────────────────────────────────────────────────
detect_panel() {
  local candidates=(
    "/var/www/pterodactyl" "/var/www/panel" "/var/www/html/panel"
    "/opt/pterodactyl" "/srv/pterodactyl" "$PWD"
  )
  for c in "${candidates[@]}"; do
    if [[ -f "$c/artisan" && -d "$c/public/themes/pterodactyl" ]]; then
      PANEL_DIR="$c"; return 0
    fi
  done
  return 1
}

if [[ -z "$PANEL_DIR" ]]; then
  if ! detect_panel; then
    err "Direktori panel tidak ditemukan otomatis."
    echo    "  Tentukan manual:  ./install.sh -d /path/to/pterodactyl"
    exit 1
  fi
fi

if [[ ! -f "$PANEL_DIR/artisan" ]]; then
  err "$PANEL_DIR bukan instalasi Pterodactyl (tidak ada artisan)."
  exit 1
fi

info "Panel: $PANEL_DIR"

THEME_CSS_SRC="$SCRIPT_DIR/public/themes/pterodactyl/css/neobrutalism.css"
THEME_CSS_DST="$PANEL_DIR/public/themes/pterodactyl/css/neobrutalism.css"

MARKER="neobrutalism.css"

# ── backup helper ────────────────────────────────────────────────────────────
backup_file() {
  local f="$1" base rel
  base="$(basename "$f")"
  rel="$(realpath --relative-to="$PANEL_DIR" "$f" 2>/dev/null || echo "$base")"
  mkdir -p "$BACKUP_DIR/$TS"
  cp -p "$f" "$BACKUP_DIR/$TS/$base"
  printf "${C_DIM}   backup: %s → backups/%s/%s${C_RESET}\n" "$rel" "$TS" "$base"
}

# ── insert helper: sisipkan $2 setelah baris pertama yang cocok literal $1 ─
# $1 dicocokkan sebagai substring literal (bukan regex) agar karakter seperti
# tanda kurung pada Theme::css(...) tidak merusak pola.
insert_after() {
  local needle="$1" line="$2" file="$3"
  awk -v l="$line" -v n="$needle" '
    index($0, n) > 0 && !done { print; print l; done=1; next }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# ── UNINSTALL ────────────────────────────────────────────────────────────────
if [[ $DO_UNINSTALL -eq 1 ]]; then
  step "Uninstall"

  latest_backup() { ls -dt "$BACKUP_DIR"/*/ 2>/dev/null | head -1; }

  # 1. hapus CSS tema
  if [[ -f "$THEME_CSS_DST" ]]; then
    rm -f "$THEME_CSS_DST"; ok "Dihapus: public/themes/pterodactyl/css/neobrutalism.css"
  else
    warn "File CSS tema tidak ada di panel"
  fi

  # 2. kembalikan file yang terpatch dari backup terbaru
  latest="$(latest_backup)"
  if [[ -n "$latest" ]]; then
    info "Memulihkan dari ${latest#$SCRIPT_DIR/}"
    for cand in \
      "resources/views/templates/wrapper.blade.php" \
      "resources/views/layouts/admin.blade.php" \
      "resources/scripts/tailwind.config.js" \
      "resources/scripts/assets/css/GlobalStylesheet.ts" \
      "resources/scripts/components/NavigationBar.tsx" \
      "resources/scripts/components/elements/button/style.module.css" \
      "resources/scripts/components/elements/dialog/style.module.css" \
      "resources/scripts/components/elements/dropdown/style.module.css" \
      "resources/scripts/components/elements/inputs/styles.module.css"; do
      base="$(basename "$cand")"
      bak="$latest$base"
      if [[ -f "$PANEL_DIR/$cand" && -f "$bak" ]]; then
        cp -p "$bak" "$PANEL_DIR/$cand"
        ok "Pulihkan: $cand"
      fi
    done
  else
    warn "Tidak ada backup — hanya file CSS yang dihapus"
  fi

  # 3. bersihkan cache
  if [[ -f "$PANEL_DIR/artisan" ]]; then
    (cd "$PANEL_DIR" && php artisan view:clear >/dev/null 2>&1 && php artisan cache:clear >/dev/null 2>&1) || true
    ok "Cache dibersihkan"
  fi

  printf "\n${C_GREEN}Tema dihapus. Panel kembali ke tema default.${C_RESET}\n"
  exit 0
fi

# ── VALIDASI SUMBER ──────────────────────────────────────────────────────────
if [[ ! -f "$THEME_CSS_SRC" ]]; then
  err "File sumber tidak ditemukan: $THEME_CSS_SRC"
  err "Jalankan installer dari folder repo tema."
  exit 1
fi

# ── 1. Salin CSS tema ────────────────────────────────────────────────────────
step "1/4 — Salin CSS tema"
mkdir -p "$(dirname "$THEME_CSS_DST")"
cp -p "$THEME_CSS_SRC" "$THEME_CSS_DST"
ok "Terpasang: public/themes/pterodactyl/css/neobrutalism.css"

# ── 2. Patch wrapper.blade.php (auth + area klien) ───────────────────────────
step "2/4 — Patch wrapper (auth + area klien)"
WRAPPER="$PANEL_DIR/resources/views/templates/wrapper.blade.php"
if [[ ! -f "$WRAPPER" ]]; then
  warn "wrapper.blade.php tidak ditemukan (versi panel berbeda) — lewati"
else
  if grep -q "$MARKER" "$WRAPPER"; then
    ok "wrapper sudah terpatch — lewati"
  else
    backup_file "$WRAPPER"
    insert_after "@yield('assets')" \
      "<link media=\"all\" type=\"text/css\" rel=\"stylesheet\" href=\"/themes/pterodactyl/css/neobrutalism.css?v=1\"/>" \
      "$WRAPPER"
    ok "wrapper.blade.php di patch (tag <link> setelah @yield('assets'))"
  fi
fi

# ── 3. Patch admin.blade.php (area admin legacy — v1.x) ──────────────────────
step "3/4 — Patch admin (area admin legacy)"
ADMIN="$PANEL_DIR/resources/views/layouts/admin.blade.php"
if [[ ! -f "$ADMIN" ]]; then
  info "admin.blade.php tidak ada — panel v2 (area admin ikut tema client), lewati"
else
  if grep -q "$MARKER" "$ADMIN"; then
    ok "admin sudah terpatch — lewati"
  else
    backup_file "$ADMIN"
    insert_after "Theme::css('css/pterodactyl.css" \
      "            {!! Theme::css('css/neobrutalism.css?t={cache-version}') !!}" \
      "$ADMIN"
    ok "admin.blade.php di patch (Theme::css setelah pterodactyl.css)"
  fi
fi

# ── 4. Bersihkan cache ───────────────────────────────────────────────────────
step "4/4 — Bersihkan cache"
if command -v php >/dev/null 2>&1; then
  (cd "$PANEL_DIR" && php artisan view:clear >/dev/null 2>&1) || true
  (cd "$PANEL_DIR" && php artisan cache:clear >/dev/null 2>&1) || true
  ok "Cache view dibersihkan"
else
  warn "php tidak ditemukan — jalankan manual: php artisan view:clear && php artisan cache:clear"
fi

# ── OPSI: source patch + rebuild (hasil 100%) ────────────────────────────────
apply_full() {
  step "Mode FULL — patch source React"

  if ! command -v yarn >/dev/null 2>&1 && ! command -v npm >/dev/null 2>&1; then
    err "yarn/npm tidak tersedia — tidak bisa rebuild"
    return 1
  fi

  local src="$SCRIPT_DIR/resources/scripts"
  local dst="$PANEL_DIR/resources/scripts"

  # pemetaan file sumber → tujuan
  local files=(
    "tailwind.config.js:tailwind.config.js"
    "assets/css/GlobalStylesheet.ts:assets/css/GlobalStylesheet.ts"
    "components/NavigationBar.tsx:components/NavigationBar.tsx"
    "components/elements/button/style.module.css:components/elements/button/style.module.css"
    "components/elements/dialog/style.module.css:components/elements/dialog/style.module.css"
    "components/elements/dropdown/style.module.css:components/elements/dropdown/style.module.css"
    "components/elements/inputs/styles.module.css:components/elements/inputs/styles.module.css"
  )

  for pair in "${files[@]}"; do
    rel="${pair%%:*}"; dstrel="${pair##*:}"
    if [[ ! -f "$src/$rel" ]]; then
      warn "sumber tidak ada: resources/scripts/$rel — lewati"
      continue
    fi
    if [[ ! -f "$dst/$dstrel" ]]; then
      warn "tujuan tidak ada: resources/scripts/$dstrel (struktur panel berbeda) — lewati"
      continue
    fi
    if grep -q "$MARKER\|\[neobrutalism\]" "$dst/$dstrel"; then
      ok "sudah terpatch: $dstrel"
    else
      backup_file "$dst/$dstrel"
      cp -p "$src/$rel" "$dst/$dstrel"
      ok "dipatch: resources/scripts/$dstrel"
    fi
  done

  info "Rebuild aset (mungkin butuh beberapa menit)..."
  (cd "$PANEL_DIR" && {
    if command -v yarn >/dev/null 2>&1; then
      yarn build:production
    else
      npm run build:production
    fi
  }) || {
    err "Build gagal. Cek log di atas — panel tetap memakai CSS inject (mode A)."
    return 1
  }
  ok "Rebuild selesai — komponen React sekarang full neobrutalism"
}

if [[ $DO_FULL -eq 1 ]]; then
  apply_full || warn "Mode FULL tidak lengkap, tapi CSS inject sudah aktif."
else
  printf "\n${C_DIM}Untuk hasil 100%% pada komponen React (tombol/dialog/input ter-hash):${C_RESET}\n"
  printf "${C_DIM}  ./install.sh --full${C_RESET}\n"
fi

# ── selesai ──────────────────────────────────────────────────────────────────
printf "\n${C_GREEN}${C_BOLD}Selesai!${C_RESET} Tema neobrutalism dark sudah aktif.\n"
printf "  Buka panel di browser (hard refresh: Ctrl+Shift+R).\n"
if [[ $DO_FULL -eq 0 ]]; then
  printf "  Backup file asli: ${C_DIM}$BACKUP_DIR/$TS/${C_RESET}\n"
fi
printf "  Kembalikan semula: ${C_DIM}./install.sh --uninstall${C_RESET}\n"
