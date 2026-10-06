# Rule: Delivery guardrails

## Always

- Cite the source of every number: `[cost-card: aws-pragmatic/ecs-fargate-small]`, `[case: 2025-031]`, or `[assumption]`.
- Attach a confidence level (high / medium / low) to every option, estimate and POC, as defined in `docs/PROPOSAL.md` §5.4.
- List assumptions and open questions at the end of every artefact.
- Build POCs from golden templates in `knowledge/templates.yaml`. Only add domain-specific code on top.
- Keep POC secrets out of git (`.env.example` only).

## Never

- Never quote prices, SLAs or delivery dates that do not come from knowledge files or case memory.
- Never commit to a delivery date or fixed price. That is a human commercial decision.
- Never put client names, personal data, credentials or confidential figures into case memory.
- Never skip a review gate. If a gate file is missing, stop and tell the user who has to approve.
- Never present a `low` confidence item in client-facing material (`pitch/`) without an `approved_low_confidence:` entry in `approvals/architecture.approved`.
