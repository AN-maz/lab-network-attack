# 03 — ARP Spoofing (L2 MITM)

**Layer:** L2 · **Objective:** poison a victim's ARP cache so it maps the
gateway IP to the attacker's MAC, then restore the correct mapping with a
static ARP entry.

## Lab parameters

| Parameter | Value |
|---|---|
| Network | `lab-arp-k9` |
| Victim | `korban-k9` |
| Gateway | `gateway-k9` |
| Attacker | `penyerang-k9` |

## Method

```bash
docker network create lab-arp-k9
docker run -d --name korban-k9   --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools
docker run -d --name gateway-k9  --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools
docker run -d --name penyerang-k9 --network lab-arp-k9 --cap-add NET_ADMIN uts-kali-tools

# Baseline
docker inspect -f '{{.NetworkSettings.Networks.lab-arp-k9.IPAddress}}' korban-k9 gateway-k9
docker exec korban-k9 arp -a

# Poison
docker exec -d penyerang-k9 timeout 20 arpspoof -i eth0 -t <ip-korban> <ip-gateway>
docker exec korban-k9 arp -a

# Mitigate: pin the real gateway MAC
docker exec korban-k9 arp -s <ip-gateway> $(docker exec gateway-k9 cat /sys/class/net/eth0/address)
docker exec korban-k9 arp -a
```

## Result

- **Baseline:** the victim's ARP table maps the gateway IP to the gateway's
  real MAC.
- **During the attack:** that mapping now points at the *attacker's* MAC —
  the victim's traffic to the gateway is being redirected, which is the MITM
  position.
- **After `arp -s`:** the entry is `PERM` and pinned to the gateway's real MAC.
  An ARP reply from the attacker no longer overwrites it while the process
  holds, because a static entry is not updated by unsolicited replies.

![Static ARP entry restored](docs/evidence/03-arp-spoofing/01-static-arp.png)

## Why it matters

ARP has no authentication: any host on the segment can claim any IP, and
victims accept the last reply they hear. ARP spoofing is the entry step for
credential capture, session hijacking, and traffic manipulation without any
exploit — it is pure protocol trust abuse.

## Mitigation

- **Static ARP entries** where practical (as above) — stops the overwrite but
  does not scale.
- **Dynamic ARP Inspection (DAI)** on the switch: validate ARP packets against
  the DHCP snooping binding table. This is the real fix in a managed network.
- **DHCP snooping** (DAI depends on it) and **port security** to limit MACs
  per port.
- **Encrypt the payload regardless of L2 trust** — TLS, SSH, VPN. ARP spoofing
  yields a traffic-manipulation position, not plaintext, if the upper layers
  are authenticated.
- Detect with **arpwatch** / repeated gratuitous ARP from one MAC.

## Evidence

| File | Shows |
|---|---|
| `01-static-arp.png` | `arp -a` with the gateway pinned (`PERM`) after the fix |
