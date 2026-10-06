-- Case memory registry. Postgres 16 + pgvector.
create extension if not exists vector;

create table cases (
    case_id             text primary key,                 -- e.g. 2026-017
    client_alias        text not null,                    -- anonymised: logistics-baltics-mid
    industry            text not null,
    domain_tags         text[] not null default '{}',     -- {fleet-tracking, iot, b2b-portal}
    region              text,
    tier                char(1) not null check (tier in ('S', 'M', 'L', 'E')),
    compliance          text[] not null default '{}',
    problem_summary     text not null,
    status              text not null check (status in ('discovery', 'proposed', 'won', 'lost', 'no_decision', 'delivered')),
    outcome_reason      text,
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now()
);

create table case_options (
    case_id             text references cases (case_id) on delete cascade,
    option_name         text not null check (option_name in ('lean', 'balanced', 'enterprise')),
    hosting_id          text not null,                    -- H1..H5
    stack               jsonb not null,                   -- {backend: python-fastapi, database: postgres, ...}
    infra_eur_month_low numeric,
    infra_eur_month_high numeric,
    build_effort_pd_low numeric,                          -- person-days
    build_effort_pd_high numeric,
    confidence          text check (confidence in ('high', 'medium', 'low')),
    recommended         boolean not null default false,
    chosen_by_client    boolean not null default false,
    rejection_reason    text,
    primary key (case_id, option_name)
);

create table case_actuals (
    case_id             text primary key references cases (case_id) on delete cascade,
    infra_eur_month     numeric,
    build_effort_pd     numeric,
    estimate_accuracy_infra  numeric,                     -- actual / estimated midpoint
    estimate_accuracy_effort numeric,
    poc_reuse_pct       numeric,                          -- share of POC code kept in production
    recorded_at         timestamptz not null default now()
);

create table case_lessons (
    lesson_id           bigint generated always as identity primary key,
    case_id             text references cases (case_id) on delete cascade,
    category            text not null,                    -- estimation | integration | stack | client | process
    lesson              text not null
);

create table case_assets (
    case_id             text references cases (case_id) on delete cascade,
    asset_type          text not null,                    -- template | terraform-module | adr | diagram | repo
    ref                 text not null,                    -- template name@version or internal repo URL
    primary key (case_id, asset_type, ref)
);

-- One embedding per case, built from problem_summary + domain_tags + lessons.
create table case_embeddings (
    case_id             text primary key references cases (case_id) on delete cascade,
    embedding           vector(1024) not null,
    source_text         text not null
);

create index on case_embeddings using hnsw (embedding vector_cosine_ops);
create index on cases using gin (domain_tags);
create index on cases (tier, status);

-- Used by the search_cases MCP tool: semantic similarity with hard filters.
-- select c.*, 1 - (e.embedding <=> $1) as similarity
-- from cases c join case_embeddings e using (case_id)
-- where ($2::char is null or c.tier = $2) and ($3::text[] is null or c.compliance @> $3)
-- order by e.embedding <=> $1
-- limit 5;
