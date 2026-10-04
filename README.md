# T3 Code in Docker

A T3 Code server with Claude Code, Codex, OpenCode and a full set of
development tools. Your desktop and mobile apps connect to it, and agents do
their work on this server. Nothing updates on its own, so a running agent is
never interrupted by an update you didn't start.

Every installed tool is listed in [TOOLS.md](TOOLS.md).

## First-time setup

Run these on the server, in this folder.

1. **Settings.** Create your `.env` and read through it; every setting is
   explained inside. Usually you only check `T3CODE_HOST` and the skills
   repository.

   ```bash
   cp .env.example .env
   ```

2. **Your SSH key, git config and T3 Code settings** (optional): see
   [Import your setup](#import-your-setup).

3. **Start.** The first build installs every toolchain and takes a while:

   ```bash
   docker compose up -d --build
   docker compose logs -f        # Ctrl+C to stop watching
   ```

4. **Sign in to the agents** you use:

   ```bash
   docker exec -it t3code claude auth login
   docker exec -it t3code codex login --device-auth   # or in the app: Settings → Providers → Connect with ChatGPT
   docker exec -it t3code opencode auth login
   ```

5. **Connect your apps.** Scan the QR code with the mobile app, or paste the
   link into the desktop app under **Settings → Connections → Add environment**.
   If the link shows `0.0.0.0`, replace it with the server's IP.

   ```bash
   docker exec -it t3code t3 pair
   ```

6. In the app, turn on **Settings → General → Continue threads after restarts**.

Projects can live anywhere in the home folder (`~`); everything there is kept.

## Import your setup

Put files in the `import` folder, then run `docker compose restart`. The folder
is read-only to the container and git-ignored, so keys can't be committed.

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
| Everything else | Refresh rebuild, below. |

The refresh rebuild installs the newest system packages and the newest release
of every tool within its pinned major version:

```bash
docker compose build --pull --build-arg BUILD_REFRESH=$(date +%s)
docker compose up -d
```

`up -d` restarts the container and stops running agents, so pick a quiet
moment. Your projects, threads, logins, keys and app-updated tools are kept.

## Adding dev dependencies

Toolchains are managed by **mise**, a tool version manager: `config/mise.toml`
lists each tool and its version, and mise installs them during the build.

| To add | Edit | Example |
|---|---|---|
| A language or CLI tool | `config/mise.toml` | `kotlin = "2"` (list: `docker exec t3code mise registry`) |
| A system package | `config/apt-packages.txt` | `php-cli` |
| A .NET global tool | Nothing: `docker exec t3code dotnet tool install -g dotnet-ef` | Kept in the data volume. |

Then run the refresh rebuild above. [TOOLS.md](TOOLS.md) lists optional tools
that are ready to uncomment.

## Good to know

- **Web previews** in the desktop app open dev servers at the server's address.
  Connect through a LAN, Tailscale IP or `*.ts.net` address (not T3 Connect),
  and have dev servers listen on `0.0.0.0` (e.g. `vite --host`).
- **T3 Connect** works from anywhere without opening ports:
  `docker exec -it t3code t3 connect`.
- **Your data** lives in the `data` Docker volume: projects, threads, T3 Code
  settings, logins, keys, git config and skills. Back it up; deleting it is a
  full reset. The `cache` volume only holds downloads and is safe to delete.
- **Logs:** `docker compose logs -f`. Startup messages start with `[t3code]`.
