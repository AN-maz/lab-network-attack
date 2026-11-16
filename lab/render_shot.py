#!/usr/bin/env python3
"""render_shot.py — bersihkan transkrip script(1) lalu render jadi PNG.

Dipakai oleh lab/shot.sh:

    python3 render_shot.py <typescript> <output-stem> <judul>

Menulis <output-stem>.png dan <output-stem>.txt. Transkrip teks disimpan
berdampingan dengan PNG — itu audit trail-nya, dan wajib ada: tanpa model
vision, satu-satunya cara memverifikasi isi gambar adalah membaca teksnya.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from term_shot import render_terminal, strip_ansi, tidy  # noqa: E402


def main() -> int:
    if len(sys.argv) < 4:
        print(__doc__)
        return 1
    raw_path, stem, title = sys.argv[1], sys.argv[2], sys.argv[3]

    raw = open(raw_path, encoding="utf-8", errors="replace").read()
    text = tidy(strip_ansi(raw))

    if not text.strip():
        print("ERROR: transkrip kosong — perintah tidak menghasilkan output.",
              file=sys.stderr)
        return 2

    render_terminal(text, stem + ".png", title="lab  —  " + title)
    with open(stem + ".txt", "w", encoding="utf-8") as fh:
        fh.write(text)

    print("PNG :", stem + ".png")
    print("TXT :", stem + ".txt")
    print("--- isi transkrip ---")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
