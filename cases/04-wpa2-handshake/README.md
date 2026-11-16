# 04 — WPA2 Handshake Analysis

**Layer:** L2 (wireless) · **Objective:** recover a WPA2-PSK passphrase from a
captured 4-way handshake by offline dictionary attack, and explain why the
handshake is crackable at all.

## Lab parameters

| Parameter | Value |
|---|---|
| Capture | `handshake-k9.cap` |
| Wordlist | `wordlist-k9.txt` |

## Method

```bash
docker run --rm -v "$PWD":/work uts-kali-tools \
  aircrack-ng -w wordlist-k9.txt handshake-k9.cap
```

## Result

`aircrack-ng` reports the recovered key (`KEY FOUND! [ <passphrase> ]`) when the
passphrase is in the wordlist, or `KEY NOT FOUND` after exhausting it.

![aircrack-ng output](docs/evidence/04-wpa2-handshake/01-aircrack.png)

## The 4-way handshake, step by step

The AP and the client derive a **Pairwise Master Key (PMK)** independently —
`PMK = PBKDF2(passphrase, SSID, 4096, 256)`. The handshake proves both sides
already hold the *same* PMK without ever sending it:

1. **AP → Client (EAPOL msg 1):** the AP sends a random value, **ANonce**.
2. **Client → AP (msg 2):** the client generates its own random **SNonce**,
   computes the PMK from the passphrase + SSID, derives the **PTK** (pairwise
   transient key) from PMK + ANonce + SNonce + both MACs, and replies with
   SNonce plus a **MIC** (message integrity code) computed over the frame with
   the PTK.
3. **AP → Client (msg 3):** the AP derives the same PTK and verifies the MIC.
   It then sends the **GTK** (group key) and its own MIC.
4. **Client → AP (msg 4):** the client installs the keys and confirms. Both
   sides now hold the PTK; encrypted data can flow.

## Why it is crackable

An eavesdropper records msgs 1 and 2 — **ANonce, SNonce, both MACs, and the
MIC**. Those four inputs plus a *guessed* passphrase are everything needed to
recompute the PTK and check whether the resulting MIC matches the captured one.
The guess is validated **entirely offline**, at the attacker's own speed, with
no packets sent to the AP — so there is no lockout, no rate limit, and no log
entry. Security reduces to the entropy of the passphrase.

## Mitigation

- **Passphrase entropy is the control.** A long, randomly generated passphrase
  (or a diceware phrase) puts the offline attack out of reach; a dictionary
  word does not, no matter how the network is configured.
- **WPA3-SAE** (Dragonfly handshake) replaces the PSK handshake with a
  password-authenticated key exchange that resists offline dictionary attack —
  a captured exchange cannot be attacked without interacting with the AP.
- **802.1X / EAP-TLS** for enterprise: per-user credentials, no shared PSK to
  crack.
- Turn off **WPS** (PIN brute force) and disable **PMKID/passive handshake
  capture conveniences** where the hardware allows.
- Monitor for deauth floods — forced re-handshakes are how the capture is
  usually provoked.

## Evidence

| File | Shows |
|---|---|
| `01-aircrack.png` | `aircrack-ng` result line (KEY FOUND or KEY NOT FOUND) |
