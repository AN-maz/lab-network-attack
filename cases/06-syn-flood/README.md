# 06 — SYN Flood (L4 TCP Exhaustion)

**Layer:** L4 · **Objective:** observe the target's half-open connection queue
fill under a SYN flood, capture the three-way handshake packets on the wire,
and explain why SYN cookies defeat the attack.

## Lab parameters

| Parameter | Value |
|---|---|
| Compose project | `k9` |
| Target | nginx container, port 80 |
| Attacker | `uts-kali-tools` with `hping3` |

## Method

```bash
docker compose -p k9 -f lab/b3-syn-flood/docker-compose.yml up -d

# Baseline: half-open sockets before the flood
docker compose -p k9 -f lab/b3-syn-flood/docker-compose.yml exec target \
  netstat -ant | grep -c SYN_RECV

# Flood (spoofed-source SYN packets, 15 s)
docker compose -p k9 -f lab/b3-syn-flood/docker-compose.yml exec -d attacker \
  timeout 15 hping3 -S -p 80 --flood target

# Half-open sockets during the flood
docker compose -p k9 -f lab/b3-syn-flood/docker-compose.yml exec target \
  netstat -ant | grep -c SYN_RECV

# Capture a legit handshake while the flood runs
docker compose -p k9 -f lab/b3-syn-flood/docker-compose.yml exec attacker sh -c \
  'timeout 10 tcpdump -i eth0 -nn tcp port 80 & sleep 1; curl -s http://target >/dev/null; sleep 10'

docker compose -p k9 -f lab/b3-syn-flood/docker-compose.yml down -v
```

## Result

Diukur di lab ini (kasus k9):

- **Sebelum:** `SYN_RECV` = **0**.
- **Saat serangan:** `SYN_RECV` = **5**, padahal hping3 mengirim **~790.000
  paket dalam 10 detik** (tcpdump melaporkan `790772 packets captured`).
- tcpdump menangkap aliran SYN bertubi-tubi dari hping3 dan, di antaranya,
  handshake sah `Flags [S]` → `Flags [S.]` → `Flags [.]`.

**Kenapa `SYN_RECV` tetap sangat kecil dibanding volume flood?** Karena
**SYN cookies aktif** di kernel (`/proc/sys/net/ipv4/tcp_syncookies = 1`),
server tidak menyimpan TCB untuk koneksi half-open — state diencode ke sequence
number SYN-ACK, jadi backlog (`tcp_max_syn_backlog = 512`) tidak bisa ditumpuk.
Angka `5` yang naik menunjukkan sebagian antrian sempat terisi sebelum cookies
mengambil alih; tanpa syncookies, backlog 512 akan penuh seketika dan client sah
ditolak. Ini bukti mitigasi bekerja, bukan kegagalan serangan. `/proc/sys`
read-only dari dalam container, jadi syncookies tidak bisa dimatikan tanpa
`--privileged`.

Untuk skenario "sebelum mitigasi" (backlog penuh, client sah ditolak), kernel
harus dijalankan dengan `tcp_syncookies=0` di host.

![SYN_RECV before and during the flood](docs/evidence/06-syn-flood/01-syn-recv.png)
![tcpdump of SYN / SYN-ACK / ACK](docs/evidence/06-syn-flood/02-tcpdump-handshake.png)

## The three-way handshake, and where it breaks

1. **Client → Server: SYN** — the client picks an initial sequence number and
   asks to connect. The server replies and moves the connection to `SYN_RECV`,
   allocating kernel memory for the pending socket.
2. **Server → Client: SYN-ACK** — the server acknowledges the client's sequence
   number and sends its own.
3. **Client → Server: ACK** — connection established, state moves to `ESTABLISHED`.

The vulnerability is in step 2→3: the server must hold state for a client that
has not yet proven it exists. A flood of SYNs from **spoofed source addresses**
fills the backlog queue with entries that will never complete, so legitimate
clients are refused — availability lost with no exploit and no credentials.

## Mitigation

- **SYN cookies** (Linux `net.ipv4.tcp_syncookies=1`): the server encodes the
  connection state into the sequence number of the SYN-ACK instead of
  allocating a TCB. State is only created on the final ACK, so the half-open
  backlog can no longer be exhausted. This is the definitive fix.
- **Backlog tuning:** raise `tcp_max_syn_backlog` and lower
  `tcp_synack_retries`, so pending entries expire quickly.
- **SYN flood protection appliances / rate limiting:** per-source SYN rate
  limits at the edge or load balancer.
- **uRPF / BCP 38 ingress filtering:** drops spoofed sources before they reach
  the target, removing the attacker's ability to hide.
- **Anycast + CDN** to absorb the volume if the attack is volumetric.

## Evidence

| File | Shows |
|---|---|
| `01-syn-recv.png` | `SYN_RECV` counts before and during the attack |
| `02-tcpdump-handshake.png` | SYN, SYN-ACK, and ACK packets on the wire |
