# Rule: Client tiering

Classify every opportunity into exactly one tier: **S**, **M**, **L**, **E**. Write the tier and the signals that justify it into `client-profile.yaml` under `tier:`.

## Signals

| Signal | S | M | L | E |
|---|---|---|---|---|
| Infra budget / month | < €300 | €300–3k | €3k–30k | > €30k |
| Build budget | < €30k | €30k–150k | €150k–750k | > €750k |
| Users | < 1k | 1k–50k | 50k–1M | > 1M |
| Availability | business hours | 99.5 % | 99.9 % | ≥ 99.95 % + DR |
| Compliance | none / GDPR basic | GDPR + audit log | ISO 27001 / SOC 2 | PCI / HIPAA / DORA / NIS2 / residency |
| Client ops team | none | 1–2 devs | platform team | dedicated cloud + security |

## Procedure

1. Compute a tier for each signal that is **known**. Mark unknown signals as `unknown` and add a discovery question for each.
2. **Hard-constraint tier** = max(tier from compliance, tier from availability).
3. **Soft tier** = median of the remaining known signals.
4. Final tier = max(hard-constraint tier, soft tier).
5. If more than 3 signals are unknown, set `tier_confidence: low` and do not produce client-facing material until the gaps are closed.

## Never

- Never downgrade a tier because of budget when a hard constraint applies. Instead, flag the budget conflict as a risk: "Requirements imply tier L; stated budget implies S."
