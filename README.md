<div align="center">

# T3 Code in Docker

[![Release](https://img.shields.io/github/v/release/neurekadev/t3-code?style=flat-square&label=Release&color=F43F5E&logo=github&logoColor=F43F5E)](https://github.com/neurekadev/t3-code/releases)
[![CI](https://img.shields.io/github/actions/workflow/status/neurekadev/t3-code/CI.yaml?branch=main&style=flat-square&label=CI&color=8B5CF6&logo=githubactions&logoColor=8B5CF6)](https://github.com/neurekadev/t3-code/actions/workflows/CI.yaml)
[![License](https://img.shields.io/github/license/neurekadev/t3-code?style=flat-square&label=License&color=14B8A6&logo=opensourceinitiative&logoColor=14B8A6)](./LICENSE.md)
[![AI](https://img.shields.io/badge/AI-assisted-5786FE?style=flat-square&logo=deepseek&logoColor=5786FE)](https://github.com/neurekadev/t3-code)
[![Stars](https://img.shields.io/github/stars/neurekadev/t3-code?style=flat-square&label=Stars&color=EAB308&logo=googlegemini&logoColor=EAB308)](https://github.com/neurekadev/t3-code)

An always-on T3 Code server with Claude Code, Codex, OpenCode and every common
toolchain installed. Connect from the desktop and mobile apps; agents keep
working on the server.

</div>

## Quickstart

Download [`compose.yaml`](./compose.yaml) and [`.env.example`](./.env.example).

## Usage

1. Create `.env` and set `T3CODE_DOCKER_BIND_ADDRESS` (see [Bind address](#bind-address)):

   ```bash
   cp .env.example .env
   ```

2. Optional: add your SSH key and git config to `import/` (see [Import your setup](#import-your-setup)).

3. Start the server:

   ```bash
   docker compose up -d
   ```

4. Sign in to the agents you use:

   ```bash
   docker exec -it t3code claude auth login
   docker exec -it t3code codex login --device-auth
   docker exec -it t3code opencode auth login
   ```

5. Connect your apps, either directly or through T3 Connect:

   ```bash
   docker exec -it t3code t3code-pair   # QR code and link for your network
   docker exec -it t3code t3 connect    # T3 Connect: works from anywhere, no open ports
   ```

   Scan the QR code with the mobile app, or paste the link into the desktop app
   under **Settings → Connections → Add environment**. The link uses
   `T3CODE_DOCKER_BIND_ADDRESS`; with `0.0.0.0`, name the server yourself:
   `docker exec -it t3code t3code-pair --host 192.168.1.10`. (Plain `t3 pair`
   shows the container's private `172.x.x.x` address.)

6. In the app, turn on **Settings → General → Continue threads after restarts**.

## Features

| Feature | Details |
|---|---|
| Agents | Claude Code, Codex and OpenCode, ready to sign in |
| Toolchains | Go, Node.js, Bun, Deno, .NET, Java, Python, Rust and everyday CLIs ([full list](TOOLS.md)) |
| Your setup | SSH keys, git config and T3 Code settings imported on every start |
| Shared skills | One skills repository for every agent, synced every 5 minutes |
| Web previews | Dev servers on ports 3000-3010, 4200, 5173-5180, 8000-8010 and 8080-8090 |
| Persistent | Projects, threads, logins and keys survive updates |

## Bind address

`T3CODE_DOCKER_BIND_ADDRESS` in `.env` decides who can reach the server. It is
required, because Docker opens these ports past the server's firewall.

| Value | Reachable from |
|---|---|
| `0.0.0.0` | Every network. Only for servers not exposed to the internet. |
| `100.x.y.z` | Your Tailscale network (the server's Tailscale IP) |
| `192.168.x.y` | Your home network (the server's LAN IP) |

<details>
<summary>Using a Tailscale or LAN IP? Run this once so the server comes back after a reboot.</summary>

```bash
printf 'net.ipv4.ip_nonlocal_bind = 1\nnet.ipv6.ip_nonlocal_bind = 1\n' \
  | sudo tee /etc/sysctl.d/90-t3code-bind.conf
sudo sysctl --system

# Tailscale only: start Docker after Tailscale
sudo mkdir -p /etc/systemd/system/docker.service.d
printf '[Unit]\nAfter=tailscaled.service\nWants=tailscaled.service\n' \
  | sudo tee /etc/systemd/system/docker.service.d/10-after-tailscale.conf
sudo systemctl daemon-reload
```

</details>

## Import your setup

Create an `import` folder next to `compose.yaml`, drop your files in, then run
`docker compose restart`.

```text
import/
├── gitconfig          your .gitconfig
├── ssh/
│   ├── config         optional
│   ├── id_ed25519     private key, no passphrase
│   └── id_ed25519.pub
└── t3/
    ├── settings.json
    ├── keybindings.json
    └── themes/
```

Files in `import/ssh/` are copied into `~/.ssh/` under the same name, so
`IdentityFile ~/.ssh/id_ed25519` and `signingkey = ~/.ssh/id_ed25519.pub` just
work. Start from the examples:

| Example | Copy to |
|---|---|
| [`import/ssh/config.example`](./import/ssh/config.example) | `import/ssh/config` |
| [`import/gitconfig.example`](./import/gitconfig.example) | `import/gitconfig` |

Every start logs what was imported and what was skipped, with the reason. A
misplaced `import/gitconfig`, or one with syntax errors or invalid core
settings, is skipped rather than breaking git. Check with
`docker compose logs t3code`. Adding or fixing `import/gitconfig` takes a
restart. Edits to one that was valid at start apply right away but are only
checked on the next start, so an edit that breaks it breaks git until you fix
it or restart.

Windows paths in your own `.gitconfig` for `core.sshCommand` and
`gpg.ssh.program` are fixed automatically. Provider secrets are not stored in
`settings.json`; enter them again under **Settings → Providers**.

## Skills

Set `T3CODE_DOCKER_SKILLS_REPO` in `.env` to a git repository of skills. Every
agent in every project sees them, and the server pulls changes every 5 minutes.
Push from your own machine; nothing is added to your projects.

## Updating

| What | How |
|---|---|
| T3 Code | In the app: **Update server**. Rolls back if it fails. |
| Claude Code, Codex, OpenCode | In the app: **Settings → Providers → Update now** |
| Toolchains and system packages | `docker compose pull && docker compose up -d` |

Nothing updates on its own. Pulling a new image restarts the container and
stops running agents, so pick a quiet moment. Your data is kept.

## Good to know

- **Data** (projects in `~`, threads, logins, keys) lives in the `data` volume.
  Back it up; deleting it is a full reset. The `cache` volume is safe to delete.
- **Web previews** need a dev server on `0.0.0.0` and a published port, e.g.
  `vite --host --port 5173`. Use a LAN or Tailscale address, not T3 Connect.
- **"Port is already allocated"** means another service uses one of those
  ports; change the list in `compose.yaml`.
- **Logs:** `docker compose logs -f`

## Why Use T3 Code in Docker?

- ✅ **Always on.** Agents run on the server, so threads keep going when your
  laptop sleeps or the app is closed.
- ✅ **Never interrupted.** Nothing updates on its own; you decide when.
- ✅ **Ready to build.** Every toolchain is installed, so agents can build and
  test most projects right away.
