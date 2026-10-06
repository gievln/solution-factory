# Solution Factory — AI-Assisted Pre-Sales Architecture & POC Delivery

**Status:** Proposal / discussion draft
**Audience:** Leadership, pre-sales, solution architects, engineering leads
**Tooling baseline:** Claude Code (CLI, plugins, skills, subagents, hooks, MCP), Claude via AWS Bedrock

---

## 1. Executive summary

We want to answer a prospect's request with a **credible architecture, a cost estimate and a working POC** in days, not weeks. We also want each pitch to take less architect and developer time than the last one.

The proposal: build a **central "Solution Factory"**. It is a versioned, company-owned package of:

1. **Knowledge**: what our teams actually know, our reference architectures, real cost cards, and compliance profiles.
2. **Rules**: how we decide. This covers client tiering, hosting choice (self-hosted vs. PaaS vs. AWS), stack selection that puts team experience first, and guardrails.
3. **Skills**: repeatable AI workflows: `discover → architect → estimate → scaffold-poc → pitch → harden → record-case`.
4. **Memory**: a searchable registry of every past discussion and solution, so each pitch reuses what we already learned.
5. **Human gates**: architects and engineers must approve at fixed checkpoints. The AI drafts; people sign off.

We ship all of this as a **Claude Code plugin from an internal plugin marketplace** (a git repo). Every architect and developer gets the same behaviour with one install. Updating the factory then works like any code change: PR, review, release.

**What success looks like (targets to validate in the pilot):**

| Metric | Today (estimate) | Target after 6 months |
|---|---|---|
| Time from first call to architecture + estimate | 1–3 weeks | 1–3 days |
| Time to demo-able POC | 3–6 weeks | 1–2 weeks |
| Senior architect hours per pitch | 30–60 h | 8–15 h (mostly review) |
| POC code reused in production after a win | low / ad hoc | ≥ 50 % of scaffold kept |

---

## 2. The problem we are solving

- Pre-sales architecture depends on a few senior people. It is slow and it doesn't scale.
- Every pitch starts from a blank page, even when we've solved the same problem three times before.
- Cost estimates are inconsistent. Proposals are either over-engineered for small clients or under-engineered for enterprises.
- POCs are throwaway code. After a win, the team often rebuilds from scratch.
- Knowledge about past deals lives in people's heads, slide decks and Slack threads.

---

## 3. Core idea: "decide with rules, generate with skills, remember with memory"

```mermaid
flowchart LR
    A[Client brief / call notes] --> B[/discover/]
    B --> P[(client-profile.yaml)]
    P --> C[/architect/]
    K[(Knowledge base:<br/>team capabilities,<br/>reference archs,<br/>cost cards)] --> C
    M[(Case memory:<br/>past solutions)] --> C
    R[[Rules:<br/>tiering, hosting,<br/>stack selection]] --> C
    C --> O[2–3 options<br/>Lean / Balanced / Enterprise]
    O --> G1{Architect<br/>review gate}
    G1 -- approved --> E[/estimate/]
    E --> S[/scaffold-poc/]
    T[(Golden templates)] --> S
    S --> G2{Engineering<br/>validation gate}
    G2 -- approved --> PI[/pitch/]
    PI --> W{Won?}
    W -- yes --> H[/harden/ → production]
    W -- either way --> RC[/record-case/]
    RC --> M
```

Key design choices:

- **Always several options, never one.** Each proposal shows *Lean*, *Balanced* and *Enterprise* variants side by side. The same engine then serves a 10-person company and a bank. The rules choose which option to **recommend**, and the client sees the trade-off.
- **Team experience is a hard input, not an afterthought.** The stack-selection rule scores each technology against our live capability matrix. If the best-fit technology is something we don't know well, the AI still proposes it. It flags a **capability gap** and gives a mitigation (pairing, training, partner, extra contingency).
- **Numbers come from data, not from the model's memory.** Cost and effort estimates must use the cost cards and historical cases. The model may interpolate, but it must cite which card or case each number came from.
- **POCs are built from golden templates.** The AI fills in and wires up templates our engineers already trust. It doesn't invent a project structure from scratch. That is what makes "POC → production" realistic.

---

## 4. Architecture of the Solution Factory

### 4.1 Components

| Layer | What it is | Implementation (Claude Code primitive) |
|---|---|---|
| **Distribution** | One install for everyone, versioned | Internal **plugin marketplace** git repo (`.claude-plugin/marketplace.json`) containing the `solution-factory` plugin |
| **Rules** | Decision logic in plain language plus tables | Markdown rule files loaded by skills (and optionally by CLAUDE.md in client workspaces) |
| **Skills** | Repeatable workflows triggered by `/name` | `skills/<name>/SKILL.md` with supporting files (questionnaires, output templates) |
| **Specialist agents** | Independent reviewers with narrow focus | `agents/*.md` subagents: architecture reviewer, cost auditor, security reviewer |
| **Guardrails** | Things that must be enforced, not just suggested | **Hooks**: e.g. block `/scaffold-poc` until `approvals/architecture.approved` exists, and block client PII in case records |
| **Knowledge base** | Team capability matrix, reference architectures, cost cards, compliance profiles | YAML/Markdown in the plugin repo (reviewed via PR) |
| **Case memory** | Past opportunities, decisions, outcomes, lessons | Postgres + `pgvector`, exposed through a small **MCP server** (`search_cases`, `get_case`, `record_case`) |
| **Golden templates** | Production-grade starter repos per stack | Separate template repos (cookiecutter / copier / plain git templates) |
| **Model hosting** | Where inference runs | **AWS Bedrock in our own account** (already in use). Client data stays inside our AWS boundary, which helps with enterprise clients and NDAs |

### 4.2 Repository layout (example included in this folder)

```
solution-factory/
├── .claude-plugin/
│   ├── marketplace.json            # internal marketplace definition
│   └── plugin.json                 # plugin manifest
├── rules/
│   ├── client-tiering.md           # S / M / L / Enterprise classification
│   ├── hosting-decision.md         # self-hosted vs PaaS vs AWS
│   ├── stack-selection.md          # team-experience-first scoring
│   └── delivery-guardrails.md      # what AI must never do / always do
├── skills/
│   ├── discover/SKILL.md           # intake → client-profile.yaml
│   ├── architect/SKILL.md          # profile → 3 options + recommendation + ADRs
│   ├── scaffold-poc/SKILL.md       # approved option → runnable repo from templates
│   └── record-case/SKILL.md        # write anonymised case to memory
├── agents/
│   └── architecture-reviewer.md    # adversarial reviewer subagent
├── hooks/
│   ├── hooks.json
│   └── require-approval.sh         # gate enforcement
├── knowledge/
│   ├── team-capabilities.yaml      # who knows what, how well
│   ├── cost-cards/                 # priced building blocks per hosting tier
│   └── reference-architectures/    # proven blueprints
├── memory/
│   ├── schema.sql                  # case registry (Postgres + pgvector)
│   └── example-case.yaml
└── docs/PROPOSAL.md                # this document
```

### 4.3 Workspace per opportunity

Each prospect gets its own git repo (or folder) created from an *opportunity template*:

```
opp-2026-017-acme-logistics/
├── CLAUDE.md                 # "This is a pre-sales workspace. Use solution-factory skills."
├── brief/                    # raw notes, RFP, call transcripts (never leave our boundary)
├── client-profile.yaml       # output of /discover
├── architecture/
│   ├── options.md            # Lean / Balanced / Enterprise
│   ├── diagrams/*.mmd
│   └── adr/*.md
├── estimate/estimate.md
├── approvals/                # architecture.approved, poc.approved (signed by humans)
├── poc/                      # generated from golden template
└── pitch/                    # one-pager, deck outline, demo script
```

Everything is in git. That gives a full audit trail of what the AI proposed and what humans changed, and that history feeds back into memory.

---

## 5. Decision framework

### 5.1 Client tiering

Classify each prospect from the discovery data. The tier sets which option we **recommend** and how much we gold-plate.

| Signal | **S — Small** | **M — Mid** | **L — Large** | **E — Enterprise / Regulated** |
|---|---|---|---|---|
| Infra budget / month | < €300 | €300 – €3k | €3k – €30k | > €30k or "whatever compliance needs" |
| Build budget | < €30k | €30k – €150k | €150k – €750k | > €750k |
| Users / load | < 1k users, low traffic | 1k – 50k | 50k – 1M | > 1M or critical SLAs |
| Availability need | business hours ok | 99.5 % | 99.9 % | 99.95 %+ with DR |
| Compliance | none / GDPR basics | GDPR, basic audit | ISO 27001 / SOC 2 expected | PCI, HIPAA, DORA, NIS2, data residency |
| Client ops capability | none, wants "it just runs" | 1–2 devs | platform team | dedicated cloud / security teams |
| Existing cloud | none | maybe | usually AWS/Azure/GCP | mandated cloud + landing zone |

When signals conflict, **the highest compliance or availability requirement wins**. Budget only pulls the tier *down* when there are no hard constraints. Example: a small company with medical data is at least M for hosting decisions.

### 5.2 Hosting decision

| Option | Typical shape | Indicative infra cost / month* | Best for | Watch-outs |
|---|---|---|---|---|
| **H1 Self-hosted lean** | 1–2 VPS (Hetzner / OVH / DO), Docker Compose, managed or self-run Postgres, Caddy/Traefik, nightly backups | €20 – €200 | Tier S, MVPs, internal tools | Single point of failure; we or the client own patching; limited scale |
| **H2 Managed PaaS** | Render / Fly.io / Railway / Vercel + managed DB (Neon/Supabase) | €50 – €1,000 | Tier S–M, fast time-to-market | Vendor lock-in, egress cost at scale, weaker enterprise compliance story |
| **H3 AWS pragmatic** | ECS Fargate or App Runner, RDS single-AZ → Multi-AZ, S3, CloudFront, managed auth (Cognito) | €300 – €5,000 | Tier M–L, growth expected, client already on AWS | Needs IaC and cost monitoring from day one |
| **H4 AWS well-architected / enterprise** | Multi-account (Control Tower), EKS or ECS, Multi-AZ RDS/Aurora, WAF, GuardDuty, centralised logging, DR region | €5,000 – €50,000+ | Tier L–E, regulated, strict SLAs | Higher build cost; needs platform expertise |
| **H5 Client's own cloud / on-prem** | Whatever the client mandates | n/a | When mandated | Our templates must be cloud-agnostic where possible (containers + Terraform modules) |

\* Ranges are placeholders. They must be replaced with numbers from our own `knowledge/cost-cards/` before the pilot, and refreshed quarterly (the AWS Pricing API can be automated for this).

**Rules of thumb that the rule file encodes:**
1. Default to the cheapest option that meets **all** hard constraints. Present one option above it as the "growth path".
2. Always show the **migration path** (H1 → H3 → H4). Small clients don't fear lock-in into a VPS. They fear a rewrite later. Containers + IaC + Postgres keep every path open.
3. If the client already runs on AWS, H3 is the floor unless they explicitly want otherwise.
4. Never recommend H1 for regulated data or for > 99.5 % availability.

### 5.3 Stack selection: team experience first

For each architectural slot (backend, frontend, data store, messaging, IaC, auth, analytics…), we score candidate technologies:

```
score = 0.35 * team_experience     (from team-capabilities.yaml, 0–5 normalised)
      + 0.25 * fit_for_requirement (model judgement, must be justified in text)
      + 0.15 * cost_efficiency     (from cost cards)
      + 0.15 * ecosystem_maturity  (tech radar status: adopt / trial / assess / hold)
      + 0.10 * client_alignment    (client's existing stack / preferences)
```

Hard filters run first. Anything on our tech radar `hold`, anything the client forbids, and anything that fails compliance gets removed. A client-mandated stack skips scoring entirely, and the gap analysis is still produced.

Outputs per slot:
- **Recommended**: highest score.
- **Capability gap flag** if the recommended tech has team experience < 3 or fewer than 2 people. It comes with a mitigation and an extra contingency on the estimate (e.g. +15 %).
- **Alternative** if a tech with a much better fit lost only because of team experience. This is how we stay honest ("best for you would be X; we deliver Y with high confidence").

### 5.4 Confidence levels

Every option, estimate and POC carries an explicit confidence rating:

| Level | Meaning | Allowed in client-facing material? |
|---|---|---|
| **High** | Built this ≥ 2 times (case memory), team experience ≥ 4, cost from cost cards | Yes |
| **Medium** | Similar case exists, or minor capability gap with mitigation | Yes, with assumptions listed |
| **Low** | Novel, large capability gap, or numbers extrapolated | Only after architect review and explicit sign-off |

This keeps our proposals *confident in delivery*: we only sound confident where the data backs it up.

---

## 6. The workflow in practice

| Step | Skill | Input | Output | Human role | Typical time |
|---|---|---|---|---|---|
| 1 | `/discover` | RFP, call notes, transcripts | `client-profile.yaml` + list of open questions | Sales/architect answers gaps | 30–60 min |
| 2 | `/architect` | Profile + rules + knowledge + memory | `options.md`, Mermaid diagrams, ADRs, recommended tier | **Gate 1**: architect approves or edits | 1–2 h AI+review |
| 3 | `/estimate` | Approved option | Effort (by role), infra cost by option, assumptions, risks | Delivery lead validates | 1 h |
| 4 | `/scaffold-poc` | Approved option + golden templates | Running repo: IaC, CI, auth, 1–3 demo use cases, seed data | **Gate 2**: engineer reviews, runs, fixes | 1–3 days |
| 5 | `/pitch` | All of the above | One-pager, deck outline, demo script, FAQ / objections | Sales polishes | 2–4 h |
| 6 | `/harden` (after win) | POC repo | Production-readiness checklist and gap backlog (security, observability, scaling, DR, tests) as tickets | Tech lead plans | 0.5–1 day |
| 7 | `/record-case` | Whole workspace + outcome | Anonymised case record in memory | Architect confirms anonymisation | 15 min |

The review gates are **enforced by hooks**, not left to discipline. For example, `/scaffold-poc` refuses to run unless `approvals/architecture.approved` exists and names the approving architect.

### What can realistically be automated vs. not

| Highly automatable (80–95 %) | Partially (40–70 %) | Human-owned |
|---|---|---|
| Turning notes into a structured profile | Architecture trade-off reasoning | Final architecture sign-off |
| Diagrams, ADR drafts, option tables | Effort estimation (needs history) | Commercial pricing & margin |
| Repo scaffolding from templates, CI, IaC wiring | Domain-specific business logic in POC | Security sign-off for production |
| Demo seed data, README, demo script | Non-standard integrations (legacy SOAP, mainframe…) | Client relationship, negotiation |
| Production-readiness gap analysis | Performance tuning | Contractual commitments |
| Case recording & retrieval | | |

---

## 7. Case memory: the long-term advantage

The rules and skills can be copied by anyone. Our **accumulated case memory** can't be, and it is what makes each pitch faster and more accurate than the last.

**What we store per case** (see `memory/schema.sql`):
- Context: industry, domain, tier, region, compliance needs, problem summary (anonymised).
- Options proposed, option chosen, and **why** (including why the client rejected the others).
- Stack and hosting used, estimated vs. actual cost and effort (filled in after delivery).
- Outcome: won / lost / no-decision, and the reason.
- Lessons learned, reusable assets (template versions, modules), and links to repos.

**How it is used:**
- `/architect` calls `search_cases` (semantic + filters: domain, tier, compliance). It cites similar cases: "We delivered a comparable logistics tracking platform for an M-tier client in 2025; actual infra cost €1.1k/month vs. €900 estimated."
- `/estimate` calibrates effort using estimated-vs-actual ratios from similar cases.
- Quarterly, a reporting query shows which domains we win, which stacks overrun, and which templates are worth investing in.

**Implementation path:**
1. **Start simple:** case records as YAML files in a `cases/` git repo, searched by Claude with grep. That's good enough for the first 20–30 cases.
2. **Then:** Postgres + `pgvector` (RDS or a single VPS), embeddings via Bedrock, and a ~200-line MCP server with `search_cases / get_case / record_case`. Register it in the plugin's `.mcp.json` so every user gets it.
3. **Later (optional):** link to CRM (HubSpot/Salesforce) for outcomes, and to Jira for actual effort.

**Confidentiality:** case records must be anonymised (no client names, no personal data, no secrets). A hook scans `record_case` payloads for obvious identifiers before writing. Raw client material stays in the opportunity workspace with normal access controls.

---

## 8. Governance & quality

- **The factory is a product.** It has an owner (e.g. a principal architect), a backlog, and releases. Changes to rules or cost cards go through PR review by at least one architect.
- **Golden templates are maintained by engineering.** Each has CI, security scanning and a named owner. Templates that aren't maintained get removed from the catalogue.
- **Quarterly refresh:** capability matrix (from skills surveys / HR), cost cards (pricing API), tech radar.
- **Evaluation set:** keep 5–10 historical briefs with "known good" architectures. Re-run `/architect` on them after every rule change and compare. This is our regression test for the AI's judgement.
- **Transparency to clients:** we say AI-assisted, engineer-validated. The confidence levels and assumptions are part of the deliverable.

---

## 9. Risks & mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| AI invents costs or capabilities | Lost margin, credibility | Numbers only from cost cards / cases with citations; cost-auditor subagent; Gate 1 |
| Over-promising in pitches | Delivery failure | Confidence levels; low confidence never client-facing without sign-off; capability gap flags + contingency |
| Client data leakage | Legal / trust | Inference on Bedrock in our AWS account; anonymised memory; PII-scan hook; per-opportunity access control |
| Template rot | Broken POCs, security issues | Template owners, CI, dependency bots, catalogue pruning |
| "Rubber-stamp" reviews | Bad architectures pass | Adversarial reviewer subagent produces a challenge list that the architect must answer in the approval file |
| Engineers distrust generated code | Low adoption | AI fills our own templates; engineers own templates; start with pilot volunteers |
| Rules become outdated | Wrong recommendations | Evaluation set + quarterly refresh + owner |
| Licence / IP of generated code | Contract issues | Templates under our licence; dependency licence scanning in template CI |

---

## 10. Rollout plan

| Phase | Duration | Scope | Exit criteria |
|---|---|---|---|
| **0. Foundations** | 2–3 weeks | Capability matrix, tech radar, 3 reference architectures (one per H1/H3/H4), first cost cards, 5 historical cases written up | Data reviewed by 2 architects |
| **1. Paper pipeline** | 3–4 weeks | `/discover`, `/architect`, `/estimate`, reviewer subagent, Gate 1 hook. Plugin published to internal marketplace | Used on 3 real or replayed opportunities; architects rate output ≥ 4/5 |
| **2. POC pipeline** | 4–6 weeks | 2–3 golden templates (e.g. Python/FastAPI + React on H1 and H3), `/scaffold-poc`, Gate 2 | POC demo-ready in ≤ 3 days on a pilot opportunity |
| **3. Memory** | 3–4 weeks | Postgres + pgvector + MCP server, `/record-case`, back-fill past cases | `/architect` cites relevant cases in ≥ 70 % of runs |
| **4. Production path** | ongoing | `/harden`, estimate-vs-actual tracking, CRM/Jira linkage, more templates per demand | ≥ 50 % of won POCs reused in production |

**Pilot team:** 1 principal architect (owner), 1–2 senior engineers (templates), 1 pre-sales person (brief → pitch feedback). Roughly 1.5–2 FTE for the first quarter.

---

## 11. Why Claude Code (and alternatives)

- **Claude Code fits because** the output is *code and documents in git*: diagrams as code, IaC, repos. Skills, subagents, hooks and MCP map directly onto "workflow, reviewer, guardrail, memory". Plugins plus a marketplace give central distribution and versioning for free, and our engineers already use it daily.
- **Headless mode** (`claude -p`) and the **Claude Agent SDK** let us later expose the same skills to non-technical sales staff, through a small internal web form or a Slack bot that runs `/discover` and `/architect` on the server.
- **Alternatives considered:** a custom LLM app (more control, but much more to build and maintain); generic low-code AI builders (fast, but weak on producing real repos and IaC); no automation, only templates (low risk, but doesn't remove the architect bottleneck). The plugin approach gets ~80 % of the value of a custom app for ~20 % of the effort, and doesn't block building the app later on the same rules and memory.

---

## 12. Decisions needed from leadership

1. Approve a pilot (Phases 0–2, ~10–13 weeks, ~1.5–2 FTE).
2. Name the factory owner (principal architect).
3. Confirm the policy on client data with AI (Bedrock in our account, anonymised memory).
4. Pick 2–3 target domains for the first reference architectures and templates, based on our pipeline (e.g. data platforms, B2B portals, logistics/ops tooling).
5. Decide how we tell clients about AI assistance.

---

## Appendix A: Example files in this folder

| File | Illustrates |
|---|---|
| `rules/client-tiering.md`, `rules/hosting-decision.md`, `rules/stack-selection.md`, `rules/delivery-guardrails.md` | Decision logic the AI must follow |
| `skills/discover/SKILL.md` | Turning messy input into a structured profile |
| `skills/architect/SKILL.md` | Main skill: multi-option architecture with scoring, gaps, confidence |
| `skills/scaffold-poc/SKILL.md` | Template-based POC generation behind a gate |
| `skills/record-case/SKILL.md` | Feeding case memory |
| `agents/architecture-reviewer.md` | Adversarial reviewer subagent |
| `hooks/hooks.json`, `hooks/require-approval.sh` | Enforcing human gates |
| `knowledge/team-capabilities.yaml` | Capability matrix format |
| `knowledge/cost-cards/aws-pragmatic.yaml` | Cost card format |
| `memory/schema.sql`, `memory/example-case.yaml` | Case memory structure |
