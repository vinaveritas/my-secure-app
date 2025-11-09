CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  user_id       TEXT PRIMARY KEY,
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name     TEXT
);

CREATE TABLE IF NOT EXISTS domains (
  domain_id   TEXT PRIMARY KEY,
  domain_name TEXT NOT NULL,
  domain_type TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS casbin_rule (
  ptype TEXT,
  v0    TEXT,
  v1    TEXT,
  v2    TEXT,
  v3    TEXT,
  v4    TEXT,
  v5    TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS casbin_rule_unique_idx
  ON casbin_rule (ptype, v0, v1, v2, v3, v4, v5);

CREATE INDEX IF NOT EXISTS casbin_rule_ptype_idx ON casbin_rule (ptype);
CREATE INDEX IF NOT EXISTS casbin_rule_v0_idx     ON casbin_rule (v0);
CREATE INDEX IF NOT EXISTS casbin_rule_v1_idx     ON casbin_rule (v1);
CREATE INDEX IF NOT EXISTS casbin_rule_v2_idx     ON casbin_rule (v2);
CREATE INDEX IF NOT EXISTS casbin_rule_v3_idx     ON casbin_rule (v3);

CREATE TABLE IF NOT EXISTS product_ledger (
  ledger_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_lot_id  TEXT NOT NULL,
  status          TEXT NOT NULL,
  actor_domain_id TEXT REFERENCES domains(domain_id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS products (
  product_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_name       TEXT NOT NULL,
  traceability_level TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS pet_owner_clinic_links (
  link_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_owner_domain_id  TEXT REFERENCES domains(domain_id),
  clinic_domain_id     TEXT REFERENCES domains(domain_id),
  status               TEXT NOT NULL DEFAULT 'PENDING'
);
