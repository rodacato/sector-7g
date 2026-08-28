#!/usr/bin/env bash
# Sector 7-G template — the standard postCreateCommand.
#
# Copy to the app repo as .devcontainer/post-create.sh and `chmod +x` it, then tailor:
#   - Replace the install/migrate/seed block with this repo's real commands.
#   - Everything here must be IDEMPOTENT: it re-runs on every rebuild.
#   - VERIFY it runs clean twice in a row before shipping.
# Delete this header block when done.
set -euo pipefail
cd "$(dirname "$0")/.."

# --- This repo's setup -------------------------------------------------------
<PACKAGE_MANAGER_INSTALL>          # npm ci | pnpm install | bundle install
# <MIGRATE_COMMAND>
# <SEED_COMMAND>

# --- Kamal, for the read-only deploy commands (DELETE if this repo has no Kamal)
# `kamal config`, `app details`, `logs`, `audit` — deploys still run in CI, so
# nothing installed here holds a secret. Needs the ruby feature in
# devcontainer.json. Keep the version in step with the deploy workflow's
# KAMAL_VERSION. See ./README.md § Kamal.
if ! gem list -i '^kamal$' >/dev/null 2>&1; then
  gem install kamal -v '<KAMAL_VERSION>' --no-document
fi

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$rc" ] || continue
  grep -q 'devcontainer/kamal-env.sh' "$rc" && continue
  {
    echo ''
    echo 'export <APP_UPPER>_ROOT="/workspaces/<APP>"'
    echo '[ -r "$<APP_UPPER>_ROOT/.devcontainer/kamal-env.sh" ] && . "$<APP_UPPER>_ROOT/.devcontainer/kamal-env.sh"'
  } >> "$rc"
done
