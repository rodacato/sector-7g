# Onboarding this repo to Sector 7-G

The three template files are now in place (`quality.yml`, `dependabot.yml`,
`sonar-project.properties`). Finish the per-repo bits — most of this an in-repo
LLM session can do, since it knows this project's stack:

## 1. SonarQube
- [ ] Set `sonar.projectKey` / `sonar.projectName` in `sonar-project.properties`.
- [ ] Keep the block for this stack; set sources/tests/coverage paths; delete the rest.
- [ ] In SonarQube, create or import the project; generate an analysis token.
- [ ] Repo → **Settings → Secrets and variables → Actions**:
  - Variable `SONAR_HOST_URL` = `https://sonarqube.notdefined.dev`
  - Secret `SONAR_TOKEN` = the token.

## 2. Dependabot
- [ ] In `.github/dependabot.yml`, uncomment the ecosystems this repo uses
  (bundler / npm / gomod / pip / cargo / docker). `github-actions` is already on.

## 3. Security gate
- [ ] First run: set `blocking: false` in `quality.yml` (report-only) to see the noise.
- [ ] Triage, then set `blocking: true` (or remove the override) to enforce.
- [ ] (Optional) branch protection requiring the `security` + `sonar` checks.

## 4. Retire duplicates (standardize on Sector 7-G)
- [ ] Remove this repo's own Gitleaks/Trivy steps if any — Sector 7-G covers them,
  pinned and consistent. (E.g. stockerly's `security.yml` and the `scan_vulnerabilities`
  job in its `ci.yml`.)
- [ ] **Keep** the stack-specific jobs that don't belong centrally: tests,
  lint/typecheck, framework audits (Brakeman, bundler-audit), app smoke/liveness.
