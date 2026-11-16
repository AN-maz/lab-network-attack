#!/bin/bash
#
# shot.sh — jalankan perintah lab di dalam TTY, render hasilnya jadi PNG.
#
# Pakai:
#   ./lab/shot.sh <nama-output> <<'CMDS'
#   docker compose -p k10 -f lab/b3-syn-flood/docker-compose.yml up -d
#   ...
#   CMDS
#
# Hasil: lab/out/<nama-output>.png dan lab/out/<nama-output>.txt
# Pindahkan PNG-nya ke docs/evidence/<kasus>/ sesuai tabel di docs/evidence/README.md,
# dan TXT-nya ke docs/evidence/<kasus>/transcripts/.
#
# Kenapa begini: `terminal` biasa tidak bisa membuat screenshot. `script(1)`
# merekam semua yang lewat TTY (prompt, perintah, warna), lalu renderer PIL
# menggambarnya jadi tampilan terminal yang otentik. Karena perintahnya benar
# dikerjakan, buktinya asli.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$SCRIPT_DIR/out"

if [ $# -lt 1 ]; then
  echo "usage: $0 <nama-output>   (perintah dibaca dari stdin)"
  exit 1
fi

KEY="$1"
mkdir -p "$OUT_DIR"

# Prompt pendek & jelas dengan bentuk user@host — renderer memakai pola
# `user@host:path$` untuk mengenali baris prompt dan membuang echo mentah
# yang direkam script(1). Prompt tanpa `@` tidak dikenali dan akan tampil
# sebagai teks biasa di gambar.
PROMPT='lab@purwa:\W$ '
LOG="$OUT_DIR/$KEY.raw"
CMDFILE="$OUT_DIR/$KEY.cmds"
cat > "$CMDFILE"

# Rekam sesi. `bash --norc` supaya tidak ada noise dari .bashrc host.
# PS1 disuntikkan lewat environment, bukan `export` di dalam transcript,
# supaya baris setup tidak ikut terfoto.
cd "$REPO_DIR"
PS1="$PROMPT" TERM=xterm-256color COLUMNS=104 \
  script -qec "bash --norc" "$LOG" < "$CMDFILE" >/dev/null 2>&1 || true

python3 "$SCRIPT_DIR/render_shot.py" "$LOG" "$OUT_DIR/$KEY" "$KEY"

rm -f "$LOG" "$CMDFILE"
