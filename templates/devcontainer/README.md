# Dev Container — the Sector 7-G baseline

Standardizes the **"reopen in container and everything is there"** half of local dev.
Companion to [`../GETTING_STARTED.md`](../GETTING_STARTED.md) (which documents the run
paths) and [`../bin-setup`](../bin-setup) (the bare-metal path).

Unlike the CI flows, this is **not** consumed by GitHub reference — a devcontainer is
per-repo by nature. What's shared is a small, exact baseline; the rest is yours.

## What's baseline vs. yours

Measured across the four onboarded repos, the invariant part is small and the rest is
genuinely stack-specific. Don't fight that — copy the baseline, tailor the rest.

**Baseline — identical everywhere, copy verbatim:**

| Item | Why it's standard |
|---|---|
| `git` · `github-cli` features | `gh auth`, `gh pr` work the same in every repo |
| `sshd` feature | attach from a terminal / another machine without VS Code |
| `shell-history` feature **+ volume at `/dc/shellhistory`** | history survives rebuilds — see the trap below |
| `claude-code` feature + `anthropic.claude-code` extension | the agent workflow is the same everywhere |
| `init: true` on the workspace service | tini reaps zombies; `sleep infinity` as PID 1 never does |
| `ripgrep` · `fd` · `neovim` in the Dockerfile | what the agent workflow greps and edits with |

**Yours — tailor per repo, no standard is possible:** base image, service name,
workspace path, forwarded ports, datastore services, language features and versions,
stack extensions, and the whole body of `post-create.sh`.

## The `/dc/shellhistory` trap

The `shell-history` feature writes to **`/dc/shellhistory`**, per its
[`devcontainer-feature.json`](https://github.com/stuartleeks/dev-container-features/blob/main/src/shell-history/devcontainer-feature.json).
It is **not** `/commandhistory` — that path belongs to the hand-rolled
`HISTFILE`-in-the-Dockerfile setup you'll find in older repos and in various blog posts.

The failure is silent and easy to ship: add the feature, mount a volume at
`/commandhistory`, and everything *looks* right — the feature works, the volume exists,
and history still evaporates on every rebuild because the two never meet. It shipped that
way in more than one repo here before anyone checked the feature's source.

The feature does declare its own `${devcontainerId}-shellhistory` mount, so an
image/Dockerfile-based container persists with no extra config. **Declare the volume
explicitly anyway when the repo uses `dockerComposeFile`** — it costs one line, it's
reviewable, and it doesn't depend on how the CLI merges feature mounts into a compose
service.

**Migrating a repo off `/commandhistory`:** retarget the *same* named volume to
`/dc/shellhistory`. The filenames match (`.bash_history`, `.zsh_history`), so the existing
history carries over instead of being orphaned.

## Adopt it

```bash
SECTOR=~/Workspace/rodacato/sector-7g
mkdir -p .devcontainer
cp "$SECTOR"/templates/devcontainer/{devcontainer.json,docker-compose.yml,Dockerfile,post-create.sh} .devcontainer/
chmod +x .devcontainer/post-create.sh
# Kamal repos only:
cp "$SECTOR"/templates/devcontainer/{kamal-env.sh,local.env.example} .devcontainer/
```

Then work the checklist:

- [ ] Fill every `<PLACEHOLDER>` in all four files; delete the template header blocks.
- [ ] `service` in `devcontainer.json` matches the service name in `docker-compose.yml`.
- [ ] `workspaceFolder` matches the workspace mount path in compose.
- [ ] Base image swapped for the stack's; the Dockerfile stays thin (toolchains are features).
- [ ] Stack features and extensions replaced; **the baseline block untouched**.
- [ ] `post-create.sh` runs clean **twice in a row** (it re-runs on every rebuild).
- [ ] Container opens, and `claude`, `gh`, `rg`, `fd` all resolve on `PATH`.
- [ ] History survives: run a command, rebuild, press ↑.

Pin nothing by hand — commit the `devcontainer-lock.json` the CLI writes on first build.

## Kamal repos

The devcontainer can run Kamal's **read-only** commands (`config`, `app details`,
`app logs`, `app versions`, `accessory details`, `audit`) while holding no secret. This is
the local counterpart to the [`kamal-deploy`](../../docs/usage.md#kamal-deploy--one-kamal-deploy-step)
action — same config files, no credentials.

It needs three things:

1. **The `ruby` feature** in `devcontainer.json`, and the `gem install kamal` block in
   `post-create.sh` (pin to the deploy workflow's `KAMAL_VERSION`).
2. **`kamal-env.sh` + `local.env`** — CI gets `GITHUB_REPOSITORY`, `HOST_IP` and friends
   for free; locally they must come from somewhere or the ERB renders empty.
3. **`.devcontainer/local.env` in `.gitignore`** — commit that in the same change.

**Also harden the deploy config while you're there.** ERB that reads env directly breaks
in two ways once the vars aren't guaranteed:

```erb
<%# breaks: NoMethodError on nil when the var is unset %>
host: <%= ENV["API_URL"].sub(/^https?:\/\//, '') %>
<%# breaks quietly: renders a YAML nil, not a string %>
SENTRY_TRACES_SAMPLE_RATE: <%= ENV["SENTRY_TRACES_SAMPLE_RATE"] %>

<%# both fixed %>
host: "<%= ENV["API_URL"].to_s.sub(%r{^https?://}, "") %>"
SENTRY_TRACES_SAMPLE_RATE: "<%= ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0") %>"
```

Give a default only where one is genuinely safe. Values that decide *where* a deploy
lands — `HOST_IP`, the proxy hosts, the registry account — get **no** default: an empty
render aborts loudly, which is what you want over a deploy pointed somewhere wrong.

Verify a render without leaving the repo:

```bash
ruby -rerb -ryaml -e 'p YAML.safe_load(ERB.new(File.read(ARGV[0])).result(binding))' config/deploy.yml
```

Run it with the env unset (must not raise) and with `local.env` loaded (must produce the
real hosts).
