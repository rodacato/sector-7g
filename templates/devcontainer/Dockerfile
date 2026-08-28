# Sector 7-G template — the image half of the standard Dev Container.
#
# Copy to the app repo as .devcontainer/Dockerfile, then tailor:
#   - Swap the base image for the stack's (see the table in ./README.md).
#   - Keep this file THIN: language toolchains belong in devcontainer.json
#     features, not here. Only the search/edit utilities live in the image.
# Delete this header block when done.
FROM mcr.microsoft.com/devcontainers/base:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    neovim \
    ripgrep \
    fd-find \
    && rm -rf /var/lib/apt/lists/*

# Debian ships fd as fdfind; give it the name every doc and muscle memory uses.
RUN ln -sf "$(which fdfind)" /usr/local/bin/fd
