<div align="center">

# T3 Code in Docker

[![Release](https://img.shields.io/github/v/release/neurekadev/t3-code?style=flat-square&label=Release&color=F43F5E&logo=github&logoColor=F43F5E)](https://github.com/neurekadev/t3-code/releases)
[![CI](https://img.shields.io/github/actions/workflow/status/neurekadev/t3-code/CI.yaml?branch=main&style=flat-square&label=CI&color=8B5CF6&logo=githubactions&logoColor=8B5CF6)](https://github.com/neurekadev/t3-code/actions/workflows/CI.yaml)
[![License](https://img.shields.io/github/license/neurekadev/t3-code?style=flat-square&label=License&color=14B8A6&logo=opensourceinitiative&logoColor=14B8A6)](./LICENSE.md)
[![AI](https://img.shields.io/badge/AI-assisted-5786FE?style=flat-square&logo=deepseek&logoColor=5786FE)](https://github.com/neurekadev/t3-code)
[![Stars](https://img.shields.io/github/stars/neurekadev/t3-code?style=flat-square&label=Stars&color=EAB308&logo=googlegemini&logoColor=EAB308)](https://github.com/neurekadev/t3-code)

A T3 Code server with Claude Code, Codex, OpenCode and a full set of development
tools. Your desktop and mobile apps connect to it, and agents do their work on
this server. Nothing updates on its own, so a running agent is never
interrupted by an update you didn't start.

</div>

## Quickstart

Download [`compose.yaml`](./compose.yaml) and [`.env.example`](./.env.example).

## Usage

Run these on the server, in the folder with the downloaded files.

1. **Settings.** Create your `.env` and read through it; every setting is
   explained inside. You must fill in `T3CODE_DOCKER_BIND_ADDRESS` (which
   network can reach T3 Code); also check the skills repository.

   ```bash
   cp .env.example .env
   ```

2. **Log in to the registry.** The image is private. Use a GitHub token with
   the `read:packages` scope:

   ```bash
   echo <token> | docker login ghcr.io -u <github-user> --password-stdin
   ```

3. **Your SSH key, git config and T3 Code settings** (optional): see
   [Import your setup](#import-your-setup).

4. **Start.** The first start downloads a large image:

   ```bash
   docker compose up -d
   docker compose logs -f        # Ctrl+C to stop watching
   ```

5. **Sign in to the agents** you use:

   ```bash
   docker exec -it t3code claude auth login
   docker exec -it t3code codex login --device-auth   # or in the app: Settings → Providers → Connect with ChatGPT
   docker exec -it t3code opencode auth login
   ```

6. **Connect your apps.** Scan the QR code with the mobile app, or paste the
   link into the desktop app under **Settings → Connections → Add environment**.
   The link shows the container's own address (`0.0.0.0` or `172.x.x.x`);
   replace it with the server's IP or hostname, keeping port `3773`.

   ```bash
   docker exec -it t3code t3 pair
   ```

7. In the app, turn on **Settings → General → Continue threads after restarts**.

Projects can live anywhere in the home folder (`~`); everything there is kept.

## Features

- T3 Code server for the desktop and mobile apps, with Claude Code, Codex and
  OpenCode ready to sign in.
- Go, Node.js, Bun, Deno, .NET, Java, Python and Rust toolchains plus everyday
  developer CLIs. Every tool is listed in [TOOLS.md](TOOLS.md).
- Your SSH keys, git config and T3 Code settings, imported on every start.
- One shared skills repository for every agent, kept in sync automatically.
- Projects, threads, logins and keys kept in a Docker volume across updates.

## Import your setup

Put files in an `import` folder next to `compose.yaml`, then run
`docker compose restart`. The folder is read-only to the container.

| Put this | Here | Effect |
|---|---|---|
| SSH private key(s), `.pub`, `config`, `known_hosts` | `import/ssh/` | Used for git clone and push, commit signing and `ssh`. Copied in on every start. |
| Your `.gitconfig` | `import/gitconfig` | Your name, email, signing and aliases. Read live. |
| T3 Code `settings.json`, `keybindings.json`, `themes/` | `import/t3/` | Your T3 Code settings. Applied when the file changes, so changes you make later in the app are kept. |

**From Windows**, in PowerShell (replace `server` and the folder path):

```powershell
scp $HOME\.gitconfig server:t3code-docker/import/gitconfig
scp $HOME\.t3\userdata\settings.json $HOME\.t3\userdata\keybindings.json server:t3code-docker/import/t3/
scp -r $HOME\.t3\userdata\themes server:t3code-docker/import/t3/
```

**SSH key.** The container needs a key *file* without a passphrase, because
agents can't type one. If your keys only live in the Windows SSH agent, make a
dedicated key for this server; you can revoke it on its own later:

```bash
ssh-keygen -t ed25519 -N "" -C "t3code-server" -f import/ssh/id_ed25519
docker compose restart
docker exec t3code git config --global user.signingkey /app/data/home/.ssh/id_ed25519.pub
cat import/ssh/id_ed25519.pub   # add to GitHub/GitLab as an authentication AND signing key
docker exec t3code ssh -T git@github.com   # check it works
```

Good to know:
- Windows-only git settings (`core.sshCommand`, `gpg.ssh.program` pointing at
  `.exe` files) are replaced automatically. The logs warn about any other
  Windows paths.
- Secret values in T3 Code provider settings (marked sensitive) are not in
  `settings.json`; enter them again under **Settings → Providers**.
- Appearance and other per-device preferences stay on each device.

## Skills

With `T3CODE_DOCKER_SKILLS_REPO` set in `.env`, skills are installed once, for
every agent and every project:

- `~/.claude/skills`: Claude Code (and OpenCode)
- `~/.agents/skills`: Codex (and OpenCode)

Both point at a single copy of your skills repository, kept at
`/app/data/skills` and pulled every 5 minutes (change it with
`T3CODE_DOCKER_SKILLS_INTERVAL` in `.env`). Nothing is added to the
projects you clone. Edit skills on your own machine and push; the server picks
them up.

## Updating

| What | How |
|---|---|
| T3 Code | In the app: **Update server** (mobile: **Settings → Environments → Check for updates**). Rolls back if the new version fails. |
| Claude Code, Codex, OpenCode | In the app: **Settings → Providers → Update now**. |
| Toolchains and system packages | Pull the newest image: `docker compose pull && docker compose up -d` |

`up -d` restarts the container and stops running agents, so pick a quiet
moment. Your projects, threads, logins, keys and app-updated tools are kept.

## Limit access to one network

To make T3 Code reachable only over Tailscale or your home network, set
`T3CODE_DOCKER_BIND_ADDRESS` in `.env` to the server's Tailscale or LAN IP.
At boot, Docker can start before that address exists, and the container would
then stay down. Run this once on the server so it always comes back:

```bash
# Let Docker bind the address before it exists (IPv4 and IPv6)
printf 'net.ipv4.ip_nonlocal_bind = 1\nnet.ipv6.ip_nonlocal_bind = 1\n' \
  | sudo tee /etc/sysctl.d/90-t3code-bind.conf
sudo sysctl --system

# Tailscale only: start Docker after Tailscale
sudo mkdir -p /etc/systemd/system/docker.service.d
printf '[Unit]\nAfter=tailscaled.service\nWants=tailscaled.service\n' \
  | sudo tee /etc/systemd/system/docker.service.d/10-after-tailscale.conf
sudo systemctl daemon-reload
```

After the next reboot, `docker port t3code` should list port 3773.

## Good to know

- **Web previews** in the desktop app open dev servers at the server's address.
  Connect through a LAN, Tailscale IP or `*.ts.net` address (not T3 Connect).
  Dev servers must listen on `0.0.0.0` and use a published port: 3000-3010,
  4200, 5173-5180, 8000-8010 or 8080-8090 (e.g. `vite --host --port 5173`).
  Change the list in `compose.yaml`.
- **The container has its own network**, so agents cannot reach services the
  server only exposes to itself (`127.0.0.1`). Its published ports bypass the
  server's firewall (ufw/firewalld); `T3CODE_DOCKER_BIND_ADDRESS` decides who
  can reach them.
- **"Port is already allocated" on start** means another service on the server
  uses one of those ports: remove or change that range in `compose.yaml`.
- **T3 Connect** works from anywhere without opening ports:
  `docker exec -it t3code t3 connect`.
- **Your data** lives in the `data` Docker volume: projects, threads, T3 Code
  settings, logins, keys, git config and skills. Back it up; deleting it is a
  full reset. The `cache` volume only holds downloads and is safe to delete.
- **Logs:** `docker compose logs -f`. Startup messages start with `[t3code]`.

## Why Use T3 Code in Docker?

- Agents work on a server that stays on, so threads keep running when your
  laptop sleeps.
- Every toolchain is already installed, so agents can build and test most
  projects right away.
- Updates happen only when you start them, so running work is never cut off.
