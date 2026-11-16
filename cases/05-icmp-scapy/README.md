# 05 — ICMP Analysis with Scapy

**Layer:** L3 · **Objective:** craft an ICMP echo request in Python, read the
reply, and connect the result to the smurf amplification attack.

## Lab parameters

| Parameter | Value |
|---|---|
| Network | `lab-arp-k9` |
| Target | `korban-k9` (`<ip-korban>`) |
| Script | `kirim_icmp.py` |

## Method

```bash
docker run --rm --network lab-arp-k9 \
  -v "$PWD/lab/kasus/k5-scapy:/work" uts-kali-tools \
  python3 /work/kirim_icmp.py <ip-korban>
```

A short reading test of the script — the feasibility check *before* scanning a
subnet:

```python
from scapy.all import ICMP, IP, sr1

paket = IP(dst=target) / ICMP()          # echo request, type 8
balasan = sr1(paket, timeout=2, verbose=False)
print("TTL balasan:", balasan[IP].ttl)   # hop count remaining
print("Tipe ICMP balasan:", balasan[ICMP].type)  # 0 = echo reply
```

A fast, quiet sweep for which hosts are up:

```python
from scapy.all import ICMP, IP, sr

ans, _ = sr(IP(dst="<subnet>/24") / ICMP(), timeout=2, verbose=False)
for sent, received in ans:
    print(received.src, "hidup")
```

## Result

Diukur di lab ini (kasus k9):

- Balasan datang dengan **ICMP type 0** (echo reply) dan **TTL 64** — bukti
  target hidup dan paketnya terbentuk dengan benar.
- TTL 64 = nilai TTL awal minus hop yang dilewati. Di network Docker yang sama
  (tanpa router), hop = 0 sehingga TTL tetap 64. Inilah cara `traceroute`
  memperkirakan jarak.
- Sweep menemukan **3 host hidup** (`172.18.0.2`, `.3`, `.4` — korban,
  gateway, penyerang), semuanya `ttl=64 type=0`; alamat lain dilewati tanpa
  noise.

![ICMP reply with TTL and type](docs/evidence/05-icmp-scapy/01-icmp-reply.png)
![Subnet sweep listing live hosts](docs/evidence/05-icmp-scapy/02-subnet-scan.png)

## Smurf attack explained

Smurf abuses two things together: ICMP echo *and* the directed broadcast
address. The attacker spoofs the **source IP as the victim** and sends echo
requests to a network's broadcast address. Every host on that segment replies
— but each reply goes to the **victim**, not the attacker. One packet becomes
N replies, so the attacker gets a large amplification factor for a small
uplink cost, and the victim is flooded by its own neighbours.

The key insight is that ICMP echo is *not the attack*: it is a legitimate
diagnostic. The attack is the combination of a **spoofable source address** and
a **broadcast amplification** that multiplies replies toward a third party.

## Mitigation

- **Disable directed broadcast forwarding** on routers (`no ip directed-broadcast`
  on Cisco). Without it, the amplification multiplier does not exist.
- **Rate-limit ICMP** (`icmp rate-limit`, policers) so a flood cannot consume
  the whole link or control plane.
- **Ingress/egress filtering (BCP 38 / uRPF):** drop spoofed source addresses
  at the network edge — this removes the spoofing half of the attack.
- **Drop ICMP to broadcast addresses** at the perimeter; allow ordinary echo
  to specific hosts if monitoring needs it.

## Evidence

| File | Shows |
|---|---|
| `01-icmp-reply.png` | Reply TTL and ICMP type (0 = echo reply) |
| `02-subnet-scan.png` | Live hosts from the `/24` sweep |
