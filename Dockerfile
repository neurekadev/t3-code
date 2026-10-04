# syntax=docker/dockerfile:1.7

# T3 Code server plus a full development toolchain.
#
# Image-owned (refreshed only by a rebuild): OS packages from
# config/apt-packages.txt, mise, and every toolchain in config/mise.toml.
# Volume-owned (updated only from the T3 Code app): T3 Code, Claude Code,
# Codex and OpenCode.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
# Any new value re-runs every layer below, pulling the newest packages and the
# newest toolchain release within each pinned major.
ARG BUILD_REFRESH=initial

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY config/apt-packages.txt /app/config/apt-packages.txt
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
 && apt-get update \
 && apt-get upgrade -y \
 && sed -e 's/\r$//' -e 's/#.*//' /app/config/apt-packages.txt \
      | xargs apt-get install -y --no-install-recommends \
 && git lfs install --system \
 && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen

# SSH: trust GitHub's published host keys (fetched over HTTPS) and accept other
# hosts on first use, so agents never hang on a host-key prompt. A host whose
# key later changes is still refused. (GIT_TERMINAL_PROMPT=0 below does the same
# for git password prompts: they fail instead of waiting forever.)
#
# Git: the system config includes your import/gitconfig, then swaps Windows-only
# programs for their Linux equivalents. ~/.gitconfig (`git config --global`)
# is read later and overrides both.
RUN curl -fsSL https://api.github.com/meta \
      | jq -r '.ssh_keys[] | "github.com " + .' >/etc/ssh/ssh_known_hosts \
 && printf 'StrictHostKeyChecking accept-new\n' >/etc/ssh/ssh_config.d/10-t3code.conf \
 && printf '%s\n' \
      '[include]' '	path = /app/import/gitconfig' \
      '[core]' '	sshCommand = ssh' \
      '[gpg "ssh"]' '	program = ssh-keygen' >>/etc/gitconfig

RUN curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh

WORKDIR /app

ENV HOME=/app/data/home \
    T3CODE_HOME=/app/data/t3 \
    T3CODE_HOST=0.0.0.0 \
    T3CODE_PORT=3773 \
    T3CODE_CHANNEL=stable \
    T3CODE_DOCKER_SERVICE_LAUNCHER=true \
    T3CODE_DOCKER_SKILLS_PATH=skills \
    T3CODE_DOCKER_SKILLS_INTERVAL=300 \
    SSH_AUTH_SOCK=/run/t3code/ssh-agent.sock \
    GIT_TERMINAL_PROMPT=0 \
    MISE_DATA_DIR=/app/lib/mise \
    MISE_CACHE_DIR=/app/cache/mise \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    DOTNET_ROOT=/app/lib/mise/dotnet-root \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    RUSTUP_HOME=/app/lib/rustup \
    CARGO_HOME=/app/lib/cargo \
    NUGET_PACKAGES=/app/cache/nuget \
    GOMODCACHE=/app/cache/go-mod \
    NPM_CONFIG_PREFIX=/app/data/home/.local \
    NPM_CONFIG_CACHE=/app/cache/npm \
    XDG_CACHE_HOME=/app/cache \
    DISABLE_AUTOUPDATER=1 \
    IS_SANDBOX=1 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

ENV PATH=$HOME/.local/bin:/app/lib/corepack:$MISE_DATA_DIR/shims:$DOTNET_ROOT:$HOME/.dotnet/tools:$CARGO_HOME/bin:$HOME/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Root's passwd home must match HOME: OpenSSH resolves ~/.ssh from passwd, not $HOME.
# The passwd field is edited directly because usermod refuses to modify a user
# with running processes, and this RUN step itself runs as root.
# Docker seeds a new /app/data volume from this skeleton on first use.
RUN sed -i -E "s#^(root:([^:]*:){4})[^:]*#\1$HOME#" /etc/passwd \
 && [ "$(getent passwd root | cut -d: -f6)" = "$HOME" ] \
 && mkdir -p "$HOME/.local/bin" "$T3CODE_HOME" /app/import /app/cache /app/lib/corepack /etc/mise \
 && cp -a /etc/skel/. "$HOME/" \
 && chmod 700 "$HOME"

COPY config/mise.toml /app/config/mise.toml
# TEMP DIAGNOSTICS (issue #7)
RUN sed -i 's/$//' /app/config/mise.toml  && cp /app/config/mise.toml /etc/mise/config.toml  && export HOME=/tmp/diag-home  && set -x  && env | sort | grep -vE 'TOKEN|SECRET' ;     MISE_TRACE=1 mise config ls 2>&1 | head -150; echo "exit=$?";     mkdir -p /tmp/proj && cp /app/config/mise.toml /tmp/proj/mise.toml && (cd /tmp/proj && mise config ls; mise ls --missing | head);     curl -fsSL https://mise.run | MISE_VERSION=v2026.9.17 MISE_INSTALL_PATH=/tmp/mise-old sh; /tmp/mise-old --version; /tmp/mise-old config ls; /tmp/mise-old ls --missing | head;     rm -rf /tmp/diag-home /tmp/proj /tmp/mise-old /etc/mise/config.toml; true
# Toolchains install into the image, not the data volume, so a rebuild replaces
# them. A throwaway HOME keeps installers from writing into the volume skeleton.
# MISE_YES is set for this build step only: at runtime it would also auto-answer
# mise's trust prompt, letting any cloned project's mise.toml run commands.
RUN --mount=type=cache,target=/app/cache \
    sed -i 's/\r$//' /app/config/mise.toml \
 && ln -s /app/config/mise.toml /etc/mise/config.toml \
 && export HOME=/tmp/build-home MISE_YES=1 \
 && mise install node \
 && mise install \
 && mise exec -- corepack enable --install-directory /app/lib/corepack yarn pnpm \
 && mise ls --current \
 && rm -rf /tmp/build-home

COPY --chmod=0755 bin/t3code-entrypoint /app/bin/t3code-entrypoint
RUN sed -i 's/\r$//' /app/bin/t3code-entrypoint

ARG GIT_TAG=dev
ARG GIT_HASH=unknown
ENV GIT_TAG=$GIT_TAG
ENV GIT_HASH=$GIT_HASH

# T3 Code, then the web-preview ports published by compose.yaml.
EXPOSE 3773 3000-3010 4200 5173-5180 8000-8010 8080-8090
VOLUME ["/app/data", "/app/cache"]

# tini reaps the orphaned processes agents leave behind and forwards stop signals.
ENTRYPOINT ["/usr/bin/tini", "--", "/app/bin/t3code-entrypoint"]
