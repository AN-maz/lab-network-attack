# Evidence — cara ambil screenshot

Semua bukti di folder ini dihasilkan dari **eksekusi nyata**, bukan mockup.
Setiap PNG punya transkrip mentah pasangannya di `transcripts/<nama>.txt` supaya
isi gambar bisa diverifikasi ulang tanpa perlu melihat gambarnya.

## Alur per kasus

1. Buka terminal di folder `lab/`, jalankan setup sekali:
   ```bash
   cd lab && ./setup.sh build
   ```
2. Jalankan perintah di bagian **Method** pada `cases/<n>-<nama>/README.md`.
3. Ambil screenshot output-nya dengan salah satu cara di bawah.
4. Simpan ke `docs/evidence/<n>-<nama>/` dengan nama file **persis** seperti yang
   dirujuk di README kasus (lihat tabel per kasus).
5. Simpan transkrip teksnya ke `docs/evidence/<n>-<nama>/transcripts/<nama>.txt`.
6. Commit: `git add docs cases && git commit -m "add evidence for case <n>"`.

## Cara screenshot

### A. GNOME/desktop screenshot (paling cepat)
```bash
# area tertentu
gnome-screenshot -a -f docs/evidence/06-syn-flood/01-syn-recv.png
# atau jendela terminal
gnome-screenshot -w -f docs/evidence/06-syn-flood/01-syn-recv.png
```
Alternative di Cinnamon (desktop kamu): `cinnamon-screenshot -a`.

### B. Headless render dari transkrip (hasil konsisten, tanpa GUI)
Pakai `lab/shot.sh`, yang membungkus `script(1)` + renderer PIL. Cocok kalau
kamu mau gambar rapi dengan semua ukuran sama:

```bash
./lab/shot.sh cases/06-syn-flood <<'CMDS'
docker compose -p k10 -f lab/b3-syn-flood/docker-compose.yml up -d
docker compose -p k10 -f lab/b3-syn-flood/docker-compose.yml exec target netstat -ant | grep -c SYN_RECV
CMDS
```

Script akan menulis `cases/06-syn-flood/transcript.txt` — pindahkan PNG hasilnya
ke path di tabel bawah.

### C. Terminal recording → GIF (bonus portfolio)
`asciinema rec docs/demo.cast` lalu `agg docs/demo.cast docs/demo.gif`. Satu GIF
untuk seluruh SYN flood membuat repo jauh lebih meyakinkan.

## Nama file yang diharapkan per kasus

| Kasus | File yang harus ada di `docs/evidence/<dir>/` |
|---|---|
| 01-docker-volume | `01-volume-survives.png`, `02-attacker-to-target.png` |
| 02-cryptography | `01-aes-roundtrip.png`, `02-certificate.png` |
| 03-arp-spoofing | `01-static-arp.png` — disarankan: `00-before.png`, `01-poisoned.png`, `02-static-arp.png` |
| 04-wpa2-handshake | `01-aircrack.png` |
| 05-icmp-scapy | `01-icmp-reply.png`, `02-subnet-scan.png` |
| 06-syn-flood | `01-syn-recv.png`, `02-tcpdump-handshake.png` |
| 07-dns-exfiltration | `01-detect.png`, `02-decode.png` |

> Untuk kasus 03, tiga gambar (before / poisoned / after) lebih kuat daripada
> satu — README-nya sudah menjelaskan ketiga kondisi, jadi buktinya juga
> sebaiknya tiga.

## Checklist sebelum push

- [ ] Tiap PNG < 1 MB, lebar konsisten dalam satu kasus
- [ ] Transkrip `.txt` ada untuk setiap PNG
- [ ] Tidak ada isi file credential/`.env` yang ikut ter-screenshot
- [ ] Angka di README kasus (jumlah `SYN_RECV`, TTL, panjang label) **sama**
      dengan yang terlihat di gambar — jangan tulis angka yang tidak ada di bukti
- [ ] `git status` bersih dari artefak lab (`*.cap`, `*.pem`, `dns-*.log` sudah
      di-gitignore)
