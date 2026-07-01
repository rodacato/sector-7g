<!--
  Sector 7-G template — the canonical "run it locally" doc.
  Copy to the app repo root as GETTING_STARTED.md, then tailor:
    - Keep the run paths that apply to this stack; delete the rest.
    - Fill every <PLACEHOLDER>.
    - VERIFY each command against the repo before shipping — a documented path
      that doesn't run is worse than no doc (the whole reason this template exists).
  Rules of the doc:
    - It answers ONE question: "how do I run this locally, fast."
    - It LINKS OUT to architecture/vision docs; it never duplicates them.
    - The README keeps only a short pointer here.
  Delete this comment block when done.
-->
# Getting Started

Run <APP> locally. For what it is, see <LINK to vision/README>; for how it's built, see
<LINK to architecture doc>.

<One or two lines on setup behavior a newcomer needs up front — e.g. "the backend runs
migrations on boot, no manual step" / "the LLM defaults to mock, no key needed" / "every
integration is optional; defaults work". State what is the ONE required step, if any.>

## Prerequisites

- **Docker** (for the container paths), or
- **<runtime + version>** + **<datastore + version>** (for the bare-metal path)

<!-- Order the paths so the RECOMMENDED one is first. Typical choices:
     TS/JS monorepo → Docker Compose first. Rails → Dev Container first. -->

## Path 1 — <Docker Compose | Dev Container> (recommended)

```bash
git clone <REPO_URL>
cd <APP>
cp .env.example .env      # <optional if defaults work | edit the required vars>
<docker compose up --build | reopen in container, then the run command>
```

Open **`http://localhost:<PORT>`**. <One line on ports / proxying if non-obvious.>

## Path 2 — <the other container path>

<Steps.>

## Path 3 — Bare metal

Requires <runtime> and a <datastore> reachable on `localhost`.

```bash
bin/setup        # install deps, prepare the DB, seed; see templates/bin-setup
<run command>
```

Open **`http://localhost:<PORT>`**.

## First run / sign-in

<How the first user is created: setup wizard? seeded admin (give the credentials)? OAuth
required (link to create the app + the callback URL)? Be exact — this is where people stall.>

## First-run check

1. <Log line that means the server is up, and on which port.>
2. `http://localhost:<PORT>` loads — <what you should see>.
3. <Any second process needed, e.g. a background worker.>

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| <e.g. can't reach DB on bare metal> | <e.g. DATABASE_URL points at a Docker-only host; override to localhost> |
| <wrong-port confusion> | <the dev server runs on <PORT>, not <the port people assume>> |
| <feature silently mocked/off> | <the flag/var that gates it> |

## More

<LINK architecture> · <LINK deployment> · [CONTRIBUTING.md](CONTRIBUTING.md)

<!--
  .env.example convention (keep the app's file, don't copy a header wholesale):
    - The top comment states the MINIMUM required to run, separated from optional vars.
      If nothing is required (defaults work), say exactly that.
    - Mark production-only secrets clearly (e.g. `# SECRET (prod)`).
    - Point to this GETTING_STARTED.md for the full guide.
-->
