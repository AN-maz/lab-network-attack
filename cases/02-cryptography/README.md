# 02 — Cryptography with OpenSSL

**Layer:** L7 / data-at-rest · **Objective:** encrypt a report with AES-256 in
CBC mode, verify the round-trip is bit-identical by hash, and issue a
self-signed X.509 certificate.

## Lab parameters

| Parameter | Value |
|---|---|
| Plaintext | `laporan-k10.txt` |
| Ciphertext | `laporan-k10.enc` |
| Passphrase | `kunci-k10-2026` |
| Cert CN | `k10.uts.local` |
| Validity | 30 days |

## Method

```bash
# 1. Symmetric encryption + integrity check
docker run --rm -v "$PWD":/work uts-openssl sh -c '
  echo isi laporan k10 > laporan-k10.txt &&
  openssl enc -aes-256-cbc -pbkdf2 -salt -in laporan-k10.txt -out laporan-k10.enc -pass pass:kunci-k10-2026 &&
  sha256sum laporan-k10.txt &&
  openssl enc -d -aes-256-cbc -pbkdf2 -in laporan-k10.enc -out hasil-k10.txt -pass pass:kunci-k10-2026 &&
  sha256sum hasil-k10.txt'

# 2. Self-signed certificate
docker run --rm -v "$PWD":/work uts-openssl sh -c '
  openssl req -x509 -newkey rsa:2048 -nodes -keyout key-k10.pem -out cert-k10.pem \
    -days 30 -subj /CN=k10.uts.local &&
  openssl x509 -in cert-k10.pem -noout -subject -issuer -dates'
```

## Result

Diukur di lab ini (kasus k10):

- Kedua digest SHA-256 — plaintext sebelum enkripsi dan hasil dekripsi —
  **identik**: `9380747e3287df06dd3de21689d77100edba5e21676683acaf5f4bca3628aff4`.
  Jadi ciphertext terdekripsi tanpa kehilangan data.
- `openssl x509` melaporkan `subject=CN = k10.uts.local`,
  `issuer=CN = k10.uts.local` (self-signed: penanda tangan = subjek), dengan
  masa berlaku 30 hari (`notBefore=Nov 16 07:32:41 2026 GMT`,
  `notAfter=Dec 16 07:32:41 2026 GMT`).

![AES round-trip hashes match](docs/evidence/02-cryptography/01-aes-roundtrip.png)
![Certificate subject/issuer/dates](docs/evidence/02-cryptography/02-certificate.png)

## Why it matters

`-pbkdf2` derives the key from the passphrase with a deliberately slow KDF and
a random salt, so the same passphrase produces different ciphertext every run
and brute force costs real time. `-salt` (on by default) defeats precomputed
rainbow tables. Without `-pbkdf2`, OpenSSL falls back to a single MD5 pass —
fast to crack, which is the classic weakness in "encrypted" shell scripts.

Self-signed certificates encrypt but do not authenticate: the issuer is the
subject, so no third party vouches for the identity. That is fine for a lab or
internal service, and dangerous for anything a user reaches from the internet.

## Mitigation

- Encrypt with `-pbkdf2 -iter <high>` (or `-argon2` where available) and a
  high-entropy passphrase; store the passphrase in a secret manager, never in
  the script or the repo.
- Pair encryption with a MAC (GCM mode) for authenticated encryption — CBC
  alone gives confidentiality but no integrity.
- In production, use a CA-issued certificate; self-signed certs belong behind
  an explicit trust anchor or pinned in the client.
- Gitignore `*.pem`, `*.key`, `*.enc` — this repo does.

## Evidence

| File | Shows |
|---|---|
| `01-aes-roundtrip.png` | Both `sha256sum` lines, identical |
| `02-certificate.png` | Subject, issuer, notBefore/notAfter |
