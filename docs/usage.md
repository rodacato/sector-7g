# Using Sector 7-G

Reference for every flow this repo offers: what it is, what it supports, and the
copy-paste caller to adopt it.

**No tooling required.** Each flow is consumed by GitHub reference
(`uses: rodacato/sector-7g/...@master`) plus, where noted, copying a file from
`templates/`. There is no CLI, no submodule, and no dependency on `kwik-e-mart` — that's
a separate, optional convenience layer (skills that automate adoption). A repo with none
of Adrian's personal tooling can still use everything here.

## Versioning

- `@master` — always the latest. Update here → every caller inherits it on next run.
- `@<tag>` or `@<sha>` — pin a caller to opt out of auto-updates. Dependabot
  (`github-actions` ecosystem) bumps the pin like any other action.

Pick `@master` for repos you want to track the standard automatically; pin when a repo
needs to freeze a known-good version.

---

## What we have

| Flow | Kind | Adopt by | Standardizes |
|---|---|---|---|
| `security.yml` | reusable workflow | reference | Semgrep · Trivy · Gitleaks |
| `sonar-scan` | composite action | reference (+ `sonar-project.properties`) | the SonarQube scan step |
| `kamal-deploy` | composite action | reference | the Kamal deploy steps |
| `sentry-release` | composite action | reference | release tagging on deploy |

**Reusable workflow vs composite action — why each is what it is:**
- A **reusable workflow** owns a whole job and runs identically everywhere (security
  scanning has no per-repo logic). The caller is one `uses:` line.
- A **composite action** owns a sequence of *steps* inside a job the caller defines, so
  the caller keeps its own `env:`, secrets, and surrounding steps. Used when the shape is
  shared but the inputs are per-repo (Sonar coverage, Kamal env/topology).

---

## `security.yml` — secret / dependency / SAST scanning

Reusable workflow. Runs Semgrep (SAST), Trivy (deps/secrets/IaC), and Gitleaks (secrets).
No per-repo config; supports a `blocking` input so you can adopt in report-only mode first.

```yaml
jobs:
  security:
    uses: rodacato/sector-7g/.github/workflows/security.yml@master
    # with:
    #   blocking: false   # report-only; flip to true (or remove) to enforce
```

---

## `sonar-scan` — SonarQube scan

Composite action. The **caller** checks out with `fetch-depth: 0` and generates coverage
first (coverage is stack-specific); the action standardizes the scan step against one
pinned scanner version. Needs a `sonar-project.properties` in the repo (or per workspace),
plus `SONAR_HOST_URL` (variable) and `SONAR_TOKEN` (secret).

```yaml
jobs:
  sonar:
    if: ${{ github.event_name == 'workflow_dispatch' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      # ...install deps + run tests so coverage lands where sonar-project.properties expects...
      - uses: rodacato/sector-7g/actions/sonar-scan@master
        with:
          host_url: ${{ vars.SONAR_HOST_URL }}
          token: ${{ secrets.SONAR_TOKEN }}
          # project_base_dir: apps/api          # monorepo: one Sonar project per workspace
          # project_version: ${{ github.ref_name }}   # default is the commit SHA
```

| Input | Default | Notes |
|---|---|---|
| `host_url` | — (required) | `vars.SONAR_HOST_URL` |
| `token` | — (required) | `secrets.SONAR_TOKEN` |
| `project_base_dir` | `.` | per-workspace dir for monorepos |
| `project_version` | `${{ github.sha }}` | report a tag/semver instead |

---

## `kamal-deploy` — one Kamal deploy step

Composite action. The **caller** checks out and sets the app's `env:`/secrets at job level
(Kamal reads them from `deploy.yml` via ERB/ENV). The action standardizes the steps only:
Ruby + Kamal install, Buildx, ssh-agent, `known_hosts`, accessory boot/reboot, and the
`kamal <action>` command. **One config file per call** — multi-service apps call it once
per service.

### Inputs

| Input | Default | Notes |
|---|---|---|
| `action` | `deploy` | `deploy` \| `setup` \| `redeploy` |
| `config-file` | `config/deploy.yml` | one service per call |
| `ssh-private-key` | — (required) | `secrets.SSH_PRIVATE_KEY` |
| `host` | `""` | added to `known_hosts`; skip with empty |
| `ruby-version` | `3.3` | Ruby that runs Kamal |
| `kamal-version` | `~> 2.7` | gem constraint; **`bundled`** = use the app's Gemfile Kamal via `bin/kamal` (Rails apps) |
| `boot-accessories` | `true` | skipped on `setup`; set `false` for a service with no accessories |
| `reboot-accessories` | `""` | space-separated names to reboot after deploy (picks up accessory config drift) |
| `dockerhub-username` / `dockerhub-token` | `""` | optional Docker Hub login to dodge base-image pull limits |

### Single service (Rails app, Kamal in the Gemfile)

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    env:
      ACTION: ${{ inputs.action || 'deploy' }}
      KAMAL_REGISTRY_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
      # ...all the app secrets/vars Kamal reads from config/deploy.yml...
    steps:
      - uses: actions/checkout@v7
      - uses: rodacato/sector-7g/actions/kamal-deploy@master
        with:
          action: ${{ env.ACTION }}
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
          host: ${{ secrets.HOST_IP }}
          ruby-version: "3.3.6"
          kamal-version: bundled
      - uses: rodacato/sector-7g/actions/sentry-release@master
        with:
          sentry-auth-token: ${{ secrets.SENTRY_AUTH_TOKEN }}
          org: ${{ vars.SENTRY_ORG }}
          project: ${{ vars.SENTRY_PROJECT }}
```

### Multi-service (one job per service, with an accessory reboot)

```yaml
jobs:
  deploy-api:
    runs-on: ubuntu-latest
    environment: production
    env: { ACTION: "${{ inputs.action || 'deploy' }}", KAMAL_REGISTRY_PASSWORD: "${{ secrets.GITHUB_TOKEN }}" }
    steps:
      - uses: actions/checkout@v7
      - uses: rodacato/sector-7g/actions/kamal-deploy@master
        with:
          action: ${{ env.ACTION }}
          config-file: config/deploy.api.yml
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
          host: ${{ vars.HOST_IP }}
          reboot-accessories: piston      # reboot Piston after deploy to pick up config drift

  deploy-web:
    needs: deploy-api
    runs-on: ubuntu-latest
    environment: production
    env: { ACTION: "${{ inputs.action || 'deploy' }}", KAMAL_REGISTRY_PASSWORD: "${{ secrets.GITHUB_TOKEN }}" }
    steps:
      - uses: actions/checkout@v7
      - uses: rodacato/sector-7g/actions/kamal-deploy@master
        with:
          action: ${{ env.ACTION }}
          config-file: config/deploy.web.yml
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
          host: ${{ vars.HOST_IP }}
          boot-accessories: "false"       # web has no accessories
```

A ready-to-tailor caller lives in [`templates/deploy.yml`](../templates/deploy.yml).

**What stays per-repo (the action does not touch):** the `env:` block (your app's
secrets/vars), the `config/deploy.*.yml` files, the image build if you build outside Kamal,
and the `workflow_dispatch`/`push` triggers.

---

## `sentry-release` — release tagging on deploy

Composite action. Creates a Sentry/GlitchTip release and marks the deploy. **No-op when
`sentry-auth-token` is empty**, so you can drop it into every deploy flow and it activates
only once the token exists. Not Kamal-specific — an EAS or Pages deploy can call it too.

```yaml
- uses: rodacato/sector-7g/actions/sentry-release@master
  with:
    sentry-auth-token: ${{ secrets.SENTRY_AUTH_TOKEN }}
    org: ${{ vars.SENTRY_ORG }}
    project: ${{ vars.SENTRY_PROJECT }}
    # environment: production            # default
    # version: ${{ github.sha }}         # default — matches the image's SENTRY_RELEASE
```

Scope note: this is **release tracking** (post-deploy). **Source-map upload** happens at
build time (in the Dockerfile / build step) and stays there — don't move it here.

---

## What stays per-repo (by design)

Forcing these central would leak (a Rails Brakeman step is meaningless in a Node repo):
tests, lint/typecheck, framework audits (Brakeman, bundler-audit, importmap audit), the
smoke-test specs themselves, and app `deploy.*.yml` topology. See the root README's
"What belongs here vs. stays per-repo".
