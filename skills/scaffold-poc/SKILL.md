---
name: scaffold-poc
description: Generate a runnable POC repository for the approved architecture option from golden templates, with IaC, CI, auth and 1–3 demo use cases. Requires approvals/architecture.approved.
---

# /scaffold-poc

A hook blocks this skill if `approvals/architecture.approved` is missing. If it was blocked, tell the user who must approve. Do not work around it.

## Steps

1. Read `approvals/architecture.approved` → selected option. Read `architecture/options.md` for that option's stack and hosting.
2. Look up the matching golden template(s) in `${CLAUDE_PLUGIN_ROOT}/knowledge/templates.yaml` (by stack + hosting). If there's no exact match, use the closest template and list every deviation in `poc/DEVIATIONS.md`.
3. Instantiate the template into `poc/` (the template's own generator, e.g. `copier copy <template> poc/`).
4. Implement **only** the top 1–3 use cases from `client-profile.yaml`, chosen for demo value. Use fake but realistic seed data. Never use real client data.
5. Integrations to client systems are **stubbed** behind an interface with a mock, documented in `poc/INTEGRATIONS.md`.
6. Make it run with one command (`make demo` / `docker compose up`). Run it, plus its tests and linters. Fix failures.
7. Write `poc/DEMO.md` (demo script: 5–8 steps, what to click and what to say) and `poc/PRODUCTION-GAPS.md` (what a production version needs; this is the input for `/harden`).
8. Report: what's real, what's mocked, what was deviated from the template, and how to run it. The next step is Gate 2: an engineer runs it and creates `approvals/poc.approved`.
