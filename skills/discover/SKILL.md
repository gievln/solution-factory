---
name: discover
description: Turn a client brief, RFP, call notes or transcript into a structured client-profile.yaml with tier classification and open questions. Use at the start of every pre-sales opportunity.
---

# /discover

## Inputs
Everything in `brief/` of the current opportunity workspace, plus any text the user pastes.

## Steps

1. Read all files in `brief/`. Do not invent facts. Anything not stated is `unknown`.
2. Fill `client-profile.yaml` using the schema below.
3. Apply `${CLAUDE_PLUGIN_ROOT}/rules/client-tiering.md` to set `tier`.
4. Search case memory (`search_cases` MCP tool if available, else grep `cases/`) for 3 similar cases by domain + problem. List them under `similar_cases`.
5. Write `discovery-questions.md`: at most 12 questions, ordered by how much the answer would change the architecture. Phrase them so a salesperson can ask them on a call.
6. Summarise for the user in 5 lines: domain, tier (+confidence), top 3 requirements, top 3 unknowns, similar cases.

## client-profile.yaml schema

```yaml
opportunity_id: opp-YYYY-NNN
client:
  industry: ""
  size_employees: unknown
  region: ""               # drives data residency
  existing_cloud: unknown  # aws | azure | gcp | on-prem | none
  existing_stack: []
  ops_capability: unknown  # none | small | platform-team | dedicated
problem:
  summary: ""              # 2–3 sentences, in business terms
  use_cases: []            # each: {name, actor, value}
  integrations: []         # each: {system, direction, protocol, known: bool}
non_functional:
  users: unknown
  peak_rps: unknown
  availability: unknown
  data_sensitivity: unknown  # public | internal | personal | special-category | payment
  compliance: []
budget:
  build_eur: unknown
  infra_month_eur: unknown
  timeline: unknown
constraints:
  mandated_tech: []
  forbidden_tech: []
tier: { value: unknown, confidence: low, signals: {} }
similar_cases: []
```
