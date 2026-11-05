FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# Tools required to build sysexts (see README.md / upstream README):
# curl, git, jq, squashfs-tools (or erofs-utils), xz-utils, bzip2, yq, docker (via feature).
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        jq \
        squashfs-tools \
        erofs-utils \
        xz-utils \
        bzip2 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# yq (mikefarah/yq, go binary) - apt's "yq" package is a different (python) tool.
RUN curl -fsSL -o /usr/local/bin/yq \
        https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq
