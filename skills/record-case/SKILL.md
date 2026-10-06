---
name: record-case
description: Write an anonymised case record of this opportunity (context, options, decision, outcome, lessons) to case memory. Use when an opportunity is won, lost, or paused, and again after delivery to add actuals.
---

# /record-case

1. Gather: `client-profile.yaml`, `architecture/options.md`, `approvals/*`, `estimate/estimate.md`, and the outcome from the user (won / lost / no-decision + reason).
2. Build a record following `${CLAUDE_PLUGIN_ROOT}/memory/example-case.yaml`.
3. **Anonymise:** replace the client name with `<industry>-<region>-<size>` (e.g. `logistics-baltics-mid`). Remove people's names, emails, URLs, internal hostnames, and exact contract values (use bands). Show the user the final record and ask them to confirm.
4. Write it with the `record_case` MCP tool if available, otherwise as `cases/<opportunity_id>.yaml` in the cases repo, and open a PR.
5. If this is an update after delivery, fill `actuals` and compute `estimate_accuracy` (actual / estimated) for infra and effort.
