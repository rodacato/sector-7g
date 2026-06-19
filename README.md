# Sector 7-G

> Springfield Nuclear Power Plant, Sector 7-G — Homer's safety-inspection post.
> Here, every rodacato project passes the same safety + quality inspection before it ships.

The goal isn't just to **centralize** CI — it's to **standardize** it: every project
follows the same shape, runs the same checks, and pins the same versions. Shared logic
lives in **reusable workflows**; each app calls in with a thin caller. Update here →
every repo inherits it.

Companion to **andys-room**:
- **andys-room** = the *host* substrate (the VPS + services like SonarQube, GlitchTip).
- **sector-7g** = the *CI / quality* substrate (this repo).

## Catalog

### Available — reusable workflows
| Workflow | What it runs | Languages |
|---|---|---|
| `security.yml` | Semgrep (SAST) · Trivy (deps/secrets/IaC) · Gitleaks (secrets) | any |
| `sonar.yml` | SonarQube scan | any (multi-language) |

### Planned
- **`kamal-deploy`** — a *composite action* wrapping the shared Kamal deploy
  boilerplate (the 8 conventions: `setup`/`deploy`/`redeploy` dispatch, ssh-agent,
  accessory boot, pinned tool versions). A composite action, **not** a reusable
  workflow, because each app's `env:` set and service topology are its own — the
  action standardizes the *steps*, the app keeps its env. Shrinks every `deploy.yml`.
- **`release`** — changelog / release tagging.

## Onboard a repo

Copy `templates/` into the app and follow `templates/CONFIGURE.md`:

```
.github/workflows/quality.yml   ← caller (security + sonar)
.github/dependabot.yml          ← dependency updates
sonar-project.properties        ← project key + sources
```

Then set `SONAR_HOST_URL` (variable) and `SONAR_TOKEN` (secret) in the repo. Full
procedure in [docs/onboarding.md](docs/onboarding.md).

## Conventions (so every flow looks the same)

- **Reusable workflows** live in `.github/workflows/*.yml` with `on: workflow_call`
  (required location for `uses:` references).
- **Pin actions** to a fixed tag; Dependabot bumps them (`.github/dependabot.yml`).
- Provide a **`blocking` input** where it makes sense, so repos can adopt in
  report-only mode first, then enforce.
- **Name by purpose** (`security`, `sonar`, `kamal-deploy`), one tool per job.
- **Callers stay thin** — they pass inputs/secrets, nothing else.

## Add or update a flow

**Update an existing flow:** edit the reusable workflow here and push. Every caller
that references `@master` gets it on its next run — no per-repo change. (Pin a caller
to a tag/SHA instead of `@master` if you want a repo to opt out of auto-updates.)

**Add a new flow:**
1. Add `.github/workflows/<name>.yml` with `on: workflow_call` (+ inputs/secrets).
2. List it in the **Catalog** above.
3. If repos call it directly, add a job to `templates/quality.yml` (or a new template)
   and document it in `templates/CONFIGURE.md`.

## What belongs here vs. stays per-repo

**Here (identical across repos):** secret/dependency/SAST scanning, SonarQube, and
(soon) the Kamal deploy boilerplate.

**Per-repo (stack-specific — forcing it central would leak):** tests, lint/typecheck,
framework audits (Brakeman, bundler-audit, importmap audit), app smoke/liveness checks.
