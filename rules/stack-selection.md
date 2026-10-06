# Rule: Stack selection (team experience first)

Source of truth for team experience: `knowledge/team-capabilities.yaml`.

## Slots

Decide one technology per slot that the solution actually needs: `backend`, `frontend`, `mobile`, `database`, `cache`, `messaging`, `search`, `auth`, `iac`, `ci_cd`, `observability`, `data_pipeline`, `ml_ai`.

## Procedure per slot

1. **Candidates:** 2–4 sensible technologies.
2. **Hard filters (remove):**
   - tech radar status `hold`
   - forbidden by client
   - fails a compliance requirement
   - client mandates a different tech for this slot (then the mandated tech is the only candidate)
3. **Score** remaining candidates (0–5 each):

   | Criterion | Weight | Source |
   |---|---|---|
   | team_experience | 0.35 | `team-capabilities.yaml`: `level` averaged over the top 3 people, capped at 2 if fewer than 2 people have level ≥ 3 |
   | fit_for_requirement | 0.25 | your reasoning; one sentence of justification required |
   | cost_efficiency | 0.15 | cost cards / licensing |
   | ecosystem_maturity | 0.15 | radar: adopt=5, trial=3, assess=1 |
   | client_alignment | 0.10 | client's existing stack and skills (important if they will maintain it) |

4. **Pick** the highest score.
5. **Capability gap:** if the pick has team_experience < 3, add a `capability_gap` entry with a mitigation (pairing / training / partner / hire) and a +15 % contingency on that slot's effort.
6. **Honest alternative:** if another candidate has a fit score ≥ 2 points higher but lost on team experience, list it as `alternative_if_capability_available`.

## Output format (per slot, in options.md)

```yaml
backend:
  pick: python-fastapi
  score: 4.35
  why: "Team level 4.7 (6 people); async I/O suits the event ingestion use case."
  alternative_if_capability_available: null
  capability_gap: null
```
