# Rule: Hosting decision

Hosting options (details and prices live in `knowledge/cost-cards/`, **never** quote prices from memory):

| ID | Name | Allowed tiers |
|---|---|---|
| H1 | Self-hosted lean (VPS + Docker Compose) | S, M (non-regulated only) |
| H2 | Managed PaaS (Render / Fly / Railway / Vercel + managed DB) | S, M |
| H3 | AWS pragmatic (ECS Fargate / App Runner, RDS, S3, CloudFront) | M, L |
| H4 | AWS well-architected / enterprise (multi-account, Multi-AZ, WAF, DR) | L, E |
| H5 | Client-mandated cloud / on-prem | any |

## Selecting the three options

Always produce exactly three options, named **Lean**, **Balanced**, **Enterprise**:

- **Balanced** = the cheapest hosting option allowed for the client's final tier that satisfies all hard constraints. This is normally the **recommended** option.
- **Lean** = one step cheaper. If that breaks a hard constraint, still show it but mark it `not viable: <reason>`. Clients like seeing why the cheap path doesn't work.
- **Enterprise** = one step more robust, showing the growth path.

If the client mandates a cloud or platform (H5), all three options use it and differ only in robustness.

## Hard rules

1. H1 is never allowed for regulated data (health, payment, financial under DORA) or availability > 99.5 %.
2. If the client already runs production workloads on AWS, the Balanced option is at least H3 unless the client explicitly asks otherwise.
3. Every option must use containers and IaC (Terraform/OpenTofu or CDK), plus Postgres-compatible storage where a relational DB is needed, so that the H1 → H3 → H4 migration path stays open. State this migration path explicitly.
4. Every option must show: monthly infra cost range (from cost cards, with the card ID cited), main single points of failure, and who operates it (us / client / managed).
