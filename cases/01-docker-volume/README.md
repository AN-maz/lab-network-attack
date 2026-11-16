# 01 — Docker Volume Persistence

**Layer:** container / storage · **Objective:** show that data written to a
Docker named volume survives container deletion, and that a *misconfigured*
volume is the difference between leftover data and a leak.

## Lab parameters

| Parameter | Value |
|---|---|
| Volume | `vol-k9` |
| File | `laporan-k9.txt` |
| Compose project | `k9` |

## Method

```bash
docker volume create vol-k9
docker run --name w-k9 -v vol-k9:/data alpine sh -c 'echo 24552011027 > /data/laporan-k9.txt'
docker rm w-k9
docker run --rm -v vol-k9:/data alpine cat /data/laporan-k9.txt

docker compose -p k9 -f lab/b1-compose/docker-compose.yml up -d
docker compose -p k9 -f lab/b1-compose/docker-compose.yml exec attacker wget -qO- http://target
docker compose -p k9 -f lab/b1-compose/docker-compose.yml down -v
```

## Result

- Isi file `laporan-k9.txt` (`24552011027`) masih terbaca **setelah** container
  `w-k9` dihapus — volume, bukan container, yang memiliki data.
- From the `attacker` container, `wget http://target` returns the nginx default
  page, proving the two containers share an isolated bridge network and can
  reach each other by service name.
- `down -v` removes containers **and** volumes.

![Volume persistence](docs/evidence/01-docker-volume/01-volume-survives.png)
![Attacker reaches target](docs/evidence/01-docker-volume/02-attacker-to-target.png)

## Why it matters

A container is disposable; a volume is not. An operator who reuses a volume
across environments (dev → staging) carries the previous tenant's data with
it, and an operator who forgets `-v` on teardown leaves credentials or reports
on disk indefinitely. Volume ownership, mount scope, and teardown discipline
are the whole control.

## Mitigation

- Mount secrets read-only and only where needed: `-v vol:/data:ro`.
- Prefer `--tmpfs` or an ephemeral volume for anything that must not persist.
- Always `docker compose down -v` in lab/CI teardown; audit with
  `docker volume ls` and `docker volume prune`.
- Never mount the Docker socket or host paths into an untrusted container —
  volume mount is a container-escape path, not just a data path.

## Evidence

| File | Shows |
|---|---|
| `01-volume-survives.png` | `cat` succeeding after `docker rm w-k9` |
| `02-attacker-to-target.png` | nginx page served to the `attacker` container |
