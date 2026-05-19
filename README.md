# Batch-XMR

This repository now includes a Linux shell script that automates downloading and running the [XMRig](https://github.com/xmrig/xmrig) miner in the background.

## Features

- One-command setup for Linux using `bash`.
- Downloads a chosen XMRig release from GitHub.
- Optional SHA256 verification for the default version.
- Starts mining in the background with `nohup`.
- Enables huge pages flags (`--huge-pages` and `--randomx-1gb-pages`).
- Writes setup/runtime logs and stores a PID file for easy stop/restart.

## Usage (Linux)

```bash
chmod +x loudminer.sh
./loudminer.sh [WALLET] [POOL] [VERSION]
```

Defaults:
- `WALLET`: `45nvZgTEtE4j5WGwP6EuKWXM7KTYuNnc5hTYyPW7MQ9AX2SHLs3SeSAJNrrtUW4FLvMobFGcboXaLY4xtE1pnAmU63pTjwL`
- `POOL`: `pool.hashvault.pro:443`
- `VERSION`: `6.22.2`

### Paths used

- Install dir: `~/.local/share/xmrig`
- Setup log: `~/.local/share/xmrig/xmrig_setup.log`
- Runtime log: `~/.local/share/xmrig/xmrig_run.log`
- PID file: `~/.local/share/xmrig/xmrig.pid`

### Stop miner

```bash
kill $(cat ~/.local/share/xmrig/xmrig.pid)
```

## Files

- `loudminer.sh` – Linux shell script for download, verification and background execution.
- `loudminer.bat` – original Windows batch version.
- `README.md` – documentation.

> Only run miners on systems where you have explicit permission.
