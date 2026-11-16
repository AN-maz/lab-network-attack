# 02 — Cryptography with OpenSSL

**Layer:** L7 / data-at-rest · **Objective:** encrypt a report with AES-256 in
CBC mode, verify the round-trip is bit-identical by hash, and issue a
self-signed X.509 certificate.

## Lab parameters

| Parameter | Value |
|---|---|
| Plaintext | `laporan-k9.txt` |
| Ciphertext | `laporan-k9.enc` |
| Passphrase | `kunci-k9-2026` |
| Cert CN | `k9.uts.local` |
| Validity | 30 days |

## Method

```bash
# 1. Symmetric encryption + integrity check
docker run --rm -v "$PWD":/work uts-openssl sh -c '
  echo isi laporan k9 > laporan-k9.txt &&
  openssl enc -aes-256-cbc -pbkdf2 -salt -in laporan-k9.txt -out laporan-k9.enc -pass pass:kunci-k9-2026 &&
  sha256sum laporan-k9.txt &&
  openssl enc -d -aes-256-cbc -pbkdf2 -in laporan-k9.enc -out hasil-k9.txt -pass pass:kunci-k9-2026 &&
  sha256sum hasil-k9.txt'

# 2. Self-signed certificate
docker run --rm -v "$PWD":/work uts-openssl sh -c '
  openssl req -x509 -newkey rsa:2048 -nodes -keyout key-k9.pem -out cert-k9.pem \
    -days 30 -subj /CN=k9.uts.local &&
  openssl x509 -in cert-k9.pem -noout -subject -issuer -dates'
```

## Result

Diukur di lab ini (kasus k9):

- Kedua digest SHA-256 — plaintext sebelum enkripsi dan hasil dekripsi —
  **identik**: `4bd9129aa11a7d2d2296b1e0ec1120dd9d8d929b789375edf87198a475162a93`.
  Jadi ciphertext terdekripsi tanpa kehilangan data.
- `openssl x509` melaporkan `subject=CN = k9.uts.local`,
  `issuer=CN = k9.uts.local` (self-signed: penanda tangan = subjek), dengan
  masa berlaku 30 hari (`notBefore=Nov 16 08:34:32 2026 GMT`,
  `notAfter=Dec 16 08:34:32 2026 GMT`).

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
