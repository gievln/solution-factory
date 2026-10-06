---
name: architect
description: Produce three architecture options (Lean / Balanced / Enterprise) with hosting choice, team-experience-weighted stack, cost ranges, capability gaps, confidence and ADRs from client-profile.yaml. Use after /discover.
---

# /architect

## Preconditions
- `client-profile.yaml` exists and `tier.confidence` is not `low`. If it is low, stop and point the user to `discovery-questions.md`.

## Load before reasoning
- `${CLAUDE_PLUGIN_ROOT}/rules/hosting-decision.md`
- `${CLAUDE_PLUGIN_ROOT}/rules/stack-selection.md`
- `${CLAUDE_PLUGIN_ROOT}/rules/delivery-guardrails.md`
- `${CLAUDE_PLUGIN_ROOT}/knowledge/team-capabilities.yaml`
- `${CLAUDE_PLUGIN_ROOT}/knowledge/cost-cards/*.yaml`
- `${CLAUDE_PLUGIN_ROOT}/knowledge/reference-architectures/` (pick the closest blueprint)
- Similar cases from `client-profile.yaml` → fetch with `get_case`

## Steps

1. **Pick a reference architecture** closest to the problem and name it. If none fits, say so. That drops confidence to medium at best.
2. **Hosting:** choose Lean / Balanced / Enterprise hosting per `hosting-decision.md`.
3. **Stack:** for each needed slot, run the scoring in `stack-selection.md`. The stack is usually the same across options; only differ where hosting forces it (e.g. Cognito vs Keycloak).
4. **Cost:** for each option, sum the cost-card line items into a monthly range. Cite card IDs. If a component has no card, mark it `[assumption]` and drop confidence.
5. **Learn from history:** for each similar case, state in one line what we reuse and what went wrong last time.
6. **Diagrams:** write `architecture/diagrams/<option>.mmd` (Mermaid C4 container level) for each option.
7. **ADRs:** write `architecture/adr/NNN-<title>.md` for each non-obvious decision (hosting, DB, auth, any capability-gap pick). Use the format: Context, Decision, Alternatives, Consequences.
8. **Write `architecture/options.md`** using the template below.
9. **Self-review:** invoke the `architecture-reviewer` subagent on `options.md`. Append its challenge list under "Reviewer challenges". Don't resolve them yourself. They are for the human architect.
10. Tell the user the next step: an architect creates `approvals/architecture.approved` (see the template at the end).

## options.md template

```markdown
# <Client domain> — Architecture options
Tier: <S/M/L/E> (<confidence>) · Reference architecture: <name> · Similar cases: <ids>

## Recommendation
<Balanced | other> — <2 sentences in business language>

## Comparison
| | Lean | Balanced ⭐ | Enterprise |
|---|---|---|---|
| Hosting | H? | H? | H? |
| Infra €/month | a–b [cards] | | |
| Build effort (rough) | | | |
| Availability | | | |
| Who operates | | | |
| Main risks | | | |
| Viable? | yes / not viable: reason | | |
| Confidence | | | |

## Stack (per slot)
<yaml blocks from stack-selection.md>

## Capability gaps & mitigations
## Migration path (Lean → Balanced → Enterprise)
## Lessons from similar cases
## Assumptions
## Open questions
## Reviewer challenges
```

## approvals/architecture.approved template (human-written)

```yaml
approved_by: <name>
date: YYYY-MM-DD
option: balanced
changes_requested: []
reviewer_challenges_answered: true
approved_low_confidence: []   # items allowed in client material despite low confidence
```
