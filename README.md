# Solution Factory

AI-assisted pre-sales architecture and POC delivery, packaged as a Claude Code plugin.

- **Start here:** [`docs/PROPOSAL.md`](docs/PROPOSAL.md), covering the analysis, decision framework, rollout plan and risks.
- **First time using it:** [`docs/USAGE.md`](docs/USAGE.md) is a step-by-step guide.
- **Example plugin:** `rules/`, `skills/`, `agents/`, `hooks/`, `knowledge/`, `memory/`. These are illustrative; numbers and people are placeholders.

## Try it locally

```bash
# inside Claude Code
/plugin marketplace add ~/coding/solution-factory
/plugin install solution-factory@company-internal
```

Then, in an opportunity workspace containing a `brief/` folder: `/discover` → `/architect` → (architect approves) → `/scaffold-poc` → `/record-case`.

Not included yet: `/estimate`, `/pitch`, `/harden` skills, `knowledge/templates.yaml`, `knowledge/reference-architectures/`, and the case-memory MCP server.
