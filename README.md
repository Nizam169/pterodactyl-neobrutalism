# Pterodactyl Neobrutalism — Dark Theme

Tema gelap neobrutalisme untuk **Pterodactyl Panel**: bidang hitam pekat, border tebal solid, hard offset shadow (tanpa blur), sudut tajam, dan aksen neon (lime, cyan, magenta).

Cakupan: **area klien, area admin (legacy AdminLTE), dan halaman auth** untuk Pterodactyl v1.x (stabil) dan v2 (develop).

---

## Cara pasang

### Opsi A — CSS inject saja (tanpa rebuild, cepat)

Dipakai untuk hasil instan. Menjangkau sebagian besar komponen (class utility global + admin legacy), tapi tidak mengubah komponen React yang memakai CSS module ter-hash.

1. Salin folder tema ke panel:

   ```bash
   cp -r public/themes/pterodactyl/css/neobrutalism.css /var/www/pterodactyl/public/themes/pterodactyl/css/
   ```

2. Pasang satu baris `<link>` di `resources/views/templates/wrapper.blade.php` (menjangkau halaman **auth + area klien**):

   ```html
   <link media="all" type="text/css" rel="stylesheet" href="/themes/pterodactyl/css/neobrutalism.css?v=1"/>
   ```

   Lihat file `resources/views/templates/wrapper.blade.php` di repo ini sebagai contoh (ditandai `{{-- [neobrutalism] --}}`).

3. Untuk **area admin** (v1.x, legacy AdminLTE), tambahkan di `resources/views/layouts/admin.blade.php` setelah baris `pterodactyl.css`:

   ```php
   {!! Theme::css('css/neobrutalism.css?t={cache-version}') !!}
   ```

   Lihat `resources/views/layouts/admin.blade.php` di repo ini.

4. Bersihkan cache view:

   ```bash
   php artisan view:clear && php artisan cache:clear
   ```

5. (Opsional) Naikkan `?v=1` pada tag wrapper untuk cache-bust setiap kali CSS diperbarui.

### Opsi B — Source patch + rebuild (hasil 100%)

Dipakai untuk menata komponen React yang memakai CSS module ter-hash (tombol, dialog, input, dropdown, navigasi).

1. Salin file dari folder `resources/scripts/` di repo ini ke folder panel yang sama (timpa):

   ```
   resources/scripts/tailwind.config.js
   resources/scripts/assets/css/GlobalStylesheet.ts
   resources/scripts/components/NavigationBar.tsx
   resources/scripts/components/elements/button/style.module.css
   resources/scripts/components/elements/dialog/style.module.css
   resources/scripts/components/elements/dropdown/style.module.css
   resources/scripts/components/elements/inputs/styles.module.css
   ```

   > **Catatan:** `tailwind.config.js` menambahkan warna neon + token shadow/radius neobrutal. Pastikan dependensi `tailwindcss/colors` tersedia (sudah bawaan panel).

2. Bangun ulang aset:

   ```bash
   yarn install        # sekali saja jika belum
   yarn build:production
   ```

3. Salin juga `public/themes/pterodactyl/css/neobrutalism.css` seperti pada Opsi A langkah 1–2 (masih dibutuhkan untuk utility class global & admin legacy).

### Opsi C — Gabungan (disarankan)

Pakai **Opsi A + Opsi B** bersamaan: CSS inject untuk utilitas global & admin, source patch untuk komponen React ter-hash.

---

## Palet

| Token | Nilai | Penggunaan |
|---|---|---|
| `--nb-bg` | `#0a0a0a` | Background utama |
| `--nb-surface` | `#161616` | Card / panel |
| `--nb-surface-2` | `#1c1c1c` | Secondary surface |
| `--nb-line-strong` | `#3d3d3d` | Border input/card |
| `--nb-lime` | `#a3e635` | Aksen utama (primary, scrollbar, logo) |
| `--nb-cyan` | `#22d3ee` | Aksen sekunder (focus, hover) |
| `--nb-magenta` | `#f472b6` | Aksen tersier (danger, indicator) |
| `--nb-yellow` | `#facc15` | Warning |

Mekanika: `border: 2px solid`, `border-radius: 3px`, `box-shadow: 5px 5px 0` (offset tanpa blur), hover `translate(-2px,-2px)` dengan shadow membesar — efek "angkat dan tekan".

---

## Preview

Buka `preview.html` di browser untuk melihat komponen utama (nav, tombol, input, card, tabel, terminal, modal) sebelum dipasang ke server.

---

## Catatan

- Uji build webpack & visual penuh harus dijalankan di server Anda; repo ini hanya berisi paket tema + preview statis.
- Semua perubahan ditandai komentar `/* [neobrutalism] */` (CSS) dan `// [neobrutalism]` (TS/TSX) supaya mudah dilacak dan dikembalikan.
- Font: sistem + IBM Plex bawaan panel (weight 800) — tanpa dependensi jaringan.
