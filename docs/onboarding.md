# Onboarding a repo to Sector 7-G

Standardize an app on the shared quality + security gate. ~10 minutes per repo;
an in-repo LLM session can do most of the per-stack tailoring.

## 1. Drop in the templates

From the app repo root:

```bash
SECTOR=~/Workspace/rodacato/sector-7g
cp "$SECTOR/templates/quality.yml"             .github/workflows/quality.yml
cp "$SECTOR/templates/dependabot.yml"          .github/dependabot.yml
cp "$SECTOR/templates/sonar-project.properties" sonar-project.properties
cp "$SECTOR/templates/CONFIGURE.md"            CONFIGURE.md   # delete after onboarding
```

## 2. Tailor to the stack (the CONFIGURE.md checklist)

- `sonar-project.properties`: set `sonar.projectKey` / `projectName`, keep the block
  for this stack, wire coverage paths.
- `.github/dependabot.yml`: uncomment the ecosystems in use.
- `quality.yml`: leave `blocking: false` for the first run, then enforce.

## 3. SonarQube side

- Create/import the project in SonarQube (`https://sonarqube.notdefined.dev`) and
  generate an analysis token. See andys-room → `docs/runbooks/sonarqube-setup.md`.
- Repo → Settings → Secrets and variables → Actions:
  - Variable `SONAR_HOST_URL` = `https://sonarqube.notdefined.dev`
  - Secret `SONAR_TOKEN` = the token.

## 4. Run + enforce

- Actions → **quality** → Run workflow (or push). Confirm `security` + `sonar` pass.
- Triage findings, flip `blocking: true`, and (optionally) add branch protection
  requiring those checks on the default branch.

## 5. Retire duplicates

Remove any pre-existing Gitleaks/Trivy steps the repo had — Sector 7-G now owns them,
pinned and consistent. Keep stack-specific jobs (tests, lint, framework audits, smoke).

---

## Migration status

| Repo | quality.yml | dependabot | sonar project | dropped dup scans |
|---|---|---|---|---|
| stockerly | ☑ | ☑ | ☑ | ☑ (Trivy → sector-7g; Brakeman/bundler-audit kept) |
| drawhaus | ☑ | ☑ | ☑ | ☑ |
| dojo | ☑ | ☑ | ☑ | ☑ |
| mi-feria | ☑ | ☑ | ☑ | ☑ |

All four are onboarded to the security + sonar gate. Keep this table updated as repos are
onboarded. (The *deploy* standardization — `kamal-deploy` / `sentry-release` — is tracked
separately; see [usage.md](usage.md).)
