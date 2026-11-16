# Network Attack Lab

Hands-on network security lab: **layer-by-layer attack simulation, traffic
analysis, and mitigation** — from L2 ARP spoofing up to L7 DNS exfiltration —
run entirely inside isolated Docker networks.

Each scenario follows the same shape: **reproduce the attack → capture the
evidence → explain the mechanism → document the mitigation**. Nothing here
touches a real host; every lab network is `internal` (no egress) so the
experiments are safe and reproducible anywhere Docker runs.

## Scenarios

| # | Scenario | Layer | Attack | Mitigation covered |
|---|----------|-------|--------|--------------------|
| 01 | [Docker volume persistence](cases/01-docker-volume/) | — | Data leak via misconfigured volume | Isolated volumes, `down -v` |
| 02 | [Cryptography with OpenSSL](cases/02-cryptography/) | L7 | Data-at-rest exposure | AES-256-CBC + PBKDF2, X.509 |
| 03 | [ARP spoofing / MITM](cases/03-arp-spoofing/) | L2 | ARP cache poisoning | Static ARP, DAI |
| 04 | [WPA2 handshake analysis](cases/04-wpa2-handshake/) | L2 | Offline PSK cracking | Strong passphrase, WPA3-SAE |
| 05 | [ICMP analysis with Scapy](cases/05-icmp-scapy/) | L3 | Smurf / ICMP amplification | ICMP rate-limit, no directed broadcast |
| 06 | [SYN flood](cases/06-syn-flood/) | L4 | TCP half-open exhaustion | SYN cookies, backlog tuning |
| 07 | [DNS exfiltration](cases/07-dns-exfiltration/) | L7 | Data tunnelling over DNS | DNS logging, response policy zones |

## Repo layout

```
.
├── cases/                  # one directory per scenario: method + findings
├── docs/evidence/          # screenshots + raw terminal transcripts
├── lab/                    # setup and teardown scripts for the lab images
└── README.md
```

Each `cases/<n>-<name>/README.md` contains the objective, the exact commands,
the observed result, and the mitigation note. Screenshots referenced in the
report live in `docs/evidence/<n>-<name>/`, with the matching raw terminal
transcript beside them in `transcripts/` so the evidence is auditable.

## Lab setup

Requires Docker with Compose v2. Build the three lab images once:

```bash
cd lab
./setup.sh build
```

Images built:

- `uts-openssl` — OpenSSL toolchain (scenario 02)
- `uts-kali-tools` — hping3, arpspoof, dig, tcpdump, scapy, aircrack-ng (03–07)
- `uts-dnsmasq` — lab DNS resolver (07)

## Ethics

All attacks are executed against containers on Docker `internal` networks on
the author's own machine. No external host is ever scanned or attacked.
