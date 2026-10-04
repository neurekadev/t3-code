# Tools

Everything installed in the container, what it is for, and how it updates.

- **App**: lives in the data volume and updates only when you click update in
  the T3 Code app.
- **Image**: baked into the image and updates only when you pull a newer
  image (see README), within its pinned major.

## Coding agents

| Tool | What it is | Updates |
|---|---|---|
| T3 Code (`t3`) | The server your desktop and mobile apps connect to. | App: **Update server** |
| Claude Code (`claude`) | Anthropic's coding agent. | App: **Settings → Providers** |
| Codex (`codex`) | OpenAI's coding agent. | App: **Settings → Providers** |
| OpenCode (`opencode`) | Open-source coding agent that works with many model providers. | App: **Settings → Providers** |

## Languages and package managers

Installed by **mise**, a tool version manager. `config/mise.toml` lists each
tool and version; mise downloads them during the build and puts them on `PATH`.
A project that needs another version can install it with `mise install` in
that project. Such runtime installs, like `cargo install` binaries, last until
the container is recreated; to keep a tool, add it to `config/mise.toml`.
For safety, a project's `mise.toml` that runs commands or sets environment
variables is refused (mise reports it as untrusted) until you run `mise trust`
in that project; plain tool versions work without it.

| Tool | What it is | Pinned to |
|---|---|---|
| `go` | Go compiler and toolchain | 1.27 |
| `golangci-lint` | Runs many Go linters at once | 2 |
| `node`, `npm`, `npx` | Node.js JavaScript runtime and its package manager | 24 (LTS) |
| `yarn`, `pnpm` | Alternative JavaScript package managers, via **Corepack** (Node's official package-manager switcher). Each project gets the version in its `package.json` `packageManager` field. | Per project |
| `bun` | Fast JavaScript runtime, bundler and package manager | 1 |
| `deno` | Secure JavaScript/TypeScript runtime | 2 |
| `dotnet` | .NET SDK, including the ASP.NET Core runtime | 10 (LTS) |
| `java`, `javac` | Eclipse Temurin JDK | 25 (LTS) |
| `mvn` | Maven, a Java build tool | 3 |
| `gradle` | Gradle, a Java/Kotlin build tool | 9 |
| `python` | Python interpreter | 3.14 |
| `uv` | Fast Python package and project manager (replaces pip, venv, pipx) | 0.12 |
| `cargo`, `rustc` | Rust compiler and package manager | stable |

## Developer CLIs

Also installed by mise.

| Tool | What it is | Pinned to |
|---|---|---|
| `gh` | GitHub CLI: pull requests, issues, releases, Actions | 2 |
| `just` | Command runner for project tasks (a simpler `make`) | 1 |
| `rg` | ripgrep: very fast text search across files | 15 |
| `fd` | Fast, friendly replacement for `find` | 10 |
| `yq` | Query and edit YAML (and JSON, TOML) from the shell | 4 |
| `shellcheck` | Finds bugs in shell scripts | 0.11 |
| `lazygit` | Terminal UI for git | 0.65 |
| `delta` | Readable, syntax-highlighted `git diff` output | 0.19 |

## System packages

Ubuntu 24.04 packages from `config/apt-packages.txt`, refreshed with the image.

| Tool | What it is |
|---|---|
| `git`, `git-lfs` | Version control; LFS stores large files outside the repository |
| `ssh`, `ssh-agent`, `ssh-keygen` | Remote access, key management, git commit signing |
| `gpg` | GnuPG, for GPG-signed commits |
| `gcc`, `g++`, `make` | C and C++ compilers and make (`build-essential`) |
| `clang` | Alternative C/C++ compiler |
| `cmake`, `ninja` | C/C++ build system generator and fast build runner |
| `pkg-config`, `libssl-dev` | Help native modules find and link system libraries |
| `gdb`, `strace` | Debugger and system-call tracer |
| `psql` | PostgreSQL client |
| `mysql` | MySQL/MariaDB client |
| `redis-cli` | Redis client |
| `sqlite3` | SQLite client |
| `jq` | Query and edit JSON from the shell |
| `curl`, `wget` | Download files and call HTTP APIs |
| `tree`, `file`, `lsof`, `htop` | Show directory trees, file types, open files, processes |
| `tmux` | Keeps terminal sessions running |
| `nano`, `vim` | Text editors |
| `rsync`, `zip`, `unzip`, `xz`, `zstd` | Copying and compression |
| `dig`, `ip`, `ping` | Network diagnostics |
| `python3` | System Python, for scripts that expect `/usr/bin/python3` |

## Not included

Left out on purpose. Add any of them as described below.

| Tool | Why not | How to add |
|---|---|---|
| Docker (building and running containers) | Needs the host's Docker daemon. Mounting `/var/run/docker.sock` gives agents root on the server. | Uncomment `docker-cli` in `config/mise.toml` and mount the socket in `compose.yaml`, only if you accept that. |
| Playwright / browsers for end-to-end tests | About 1 GB of browsers and system libraries. | Projects can run `npx playwright install --with-deps chromium`; it lasts until the container is recreated. |
| Kotlin, protoc, Ruby, Terraform, kubectl, Helm | Less common; ready to enable. | Uncomment in `config/mise.toml`. |
| PHP | mise builds PHP from source, which is slow and fragile. | Add `php-cli` and `composer` to `config/apt-packages.txt`. |
| Cloud CLIs (`aws`, `az`, `gcloud`) | Large, and only useful with credentials. | `aws-cli` and `gcloud` are available in mise; add them to `config/mise.toml`. |
| Database servers (Postgres, Redis, ...) | Better run as separate containers next to this one. | Add services to `compose.yaml`. |
