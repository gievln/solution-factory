# Solution Factory: First-time usage guide

## How it fits together

- **`solution-factory/`** is the toolbox (rules, skills, knowledge). You install it once as a Claude Code plugin and don't work inside it.
- **One folder per prospect** (e.g. `~/coding/opportunities/opp-2026-001-demo/`) is the workspace. That's where you run Claude.

## Prerequisites

- Claude Code installed (`which claude`)
- `jq` installed (`which jq`), used by the approval-check hook
- Git

## Step 0: Create an opportunity workspace

```bash
mkdir -p ~/coding/opportunities/opp-2026-001-demo/{brief,approvals}
cd ~/coding/opportunities/opp-2026-001-demo
git init
```

Put the raw client material in `brief/`: call notes, RFP, transcripts. Add a short `CLAUDE.md`:

```markdown
# Pre-sales opportunity workspace

This folder is one pre-sales opportunity. Use the solution-factory plugin skills
(discover → architect → scaffold-poc → record-case) and follow the plugin's rules.
Raw client material is in `brief/`. Never copy it into case memory without anonymising.
```

## Step 1: Install the plugin (once per machine)

In a terminal (in VS Code: `` Ctrl+` ``):

```bash
cd ~/coding/opportunities/opp-2026-001-demo
claude
```

Inside Claude:

```
/plugin marketplace add ~/coding/solution-factory
/plugin install solution-factory@company-internal
```

Then quit Claude (`/exit` or Ctrl+C twice) and run `claude` again so it loads the plugin. Type `/` and look for `discover` and `architect`. Plugin commands may show up as `/solution-factory:discover`. Both forms work.

## Step 2: Discovery

```
/discover
```

Claude reads `brief/` and creates:

- `client-profile.yaml`: structured client facts and a tier (S / M / L / E)
- `discovery-questions.md`: what to ask the client next

Read both files. Correct anything wrong in plain words, e.g. *"The budget is 60k, not unknown. Update the profile."*

## Step 3: Architecture

```
/architect
```

Creates:

- `architecture/options.md`: three options (Lean / Balanced / Enterprise), a recommendation, cost ranges, capability gaps and confidence ratings
- `architecture/diagrams/*.mmd`: Mermaid diagrams
- `architecture/adr/*.md`: decision records
- "Reviewer challenges": questions from the adversarial reviewer subagent

To view a diagram, use a Mermaid preview extension. Alternatively, ask Claude to put the diagram into `options.md` as a mermaid block and open the Markdown preview with `Cmd+Shift+V`.

## Step 4: Gate 1, architect approval

`/scaffold-poc` is blocked until a human approves the architecture. Run it now to see the block message ("Gate 1 not passed").

Approve by creating `approvals/architecture.approved` (write it yourself or ask Claude to):

```yaml
approved_by: <name>
date: YYYY-MM-DD
option: balanced
changes_requested: []
reviewer_challenges_answered: true
approved_low_confidence: []
```

In real use, the architect writes this only after answering the reviewer's challenges.

## Step 5: POC

```
/scaffold-poc
```

Generates a runnable POC in `poc/`, plus `DEMO.md`, `INTEGRATIONS.md` (mocked systems) and `PRODUCTION-GAPS.md`.

> Golden templates (`knowledge/templates.yaml`) don't exist yet, so Claude builds from scratch and lists the deviations in `poc/DEVIATIONS.md`.

`/pitch` is likewise blocked until `approvals/poc.approved` exists (Gate 2: an engineer has run and checked the POC). The `/pitch` skill itself isn't built yet.

## Step 6: Record the case

```
/record-case
```

Tell Claude the outcome (won / lost / no decision, and why). The memory database (MCP server) doesn't exist yet, so it writes `cases/<opportunity_id>.yaml`. Check that no client names, personal data or exact figures are in it.

After delivery, run `/record-case` again with actual costs and effort so future estimates improve.

## Tips

- **Commit after every step** (`git add -A && git commit -m "after architect"`). Then you can compare what the AI produced with what humans changed.
- **If Claude can't find the rules:** tell it *"The rules are in ~/coding/solution-factory/rules/"*.
- **To change how decisions are made:** edit files in `solution-factory/` (e.g. put your real people in `knowledge/team-capabilities.yaml` and real prices in `knowledge/cost-cards/`). Then run `/plugin` and update or reinstall the plugin.
- **For a new real client:** create a new opportunity folder (Step 0), put the notes in `brief/`, and start from Step 2.

## Not built yet

- `/estimate`, `/pitch`, `/harden` skills
- `knowledge/templates.yaml` and golden template repos
- `knowledge/reference-architectures/`
- Case-memory MCP server (Postgres + pgvector, schema in `memory/schema.sql`)
