-- schema.sql — VinaVeritas Phase 0 (future-proof seed + indexes)
-- Safe to run multiple times. Creates core tables, indexes, and seed data.

-- 0) Extensions (for UUIDs)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1) Drop in dependency order (so re-runs are clean)
DROP TABLE IF EXISTS product_ledger         CASCADE;
DROP TABLE IF EXISTS pet_owner_clinic_links CASCADE;
DROP TABLE IF EXISTS products               CASCADE;
DROP TABLE IF EXISTS users                  CASCADE;
DROP TABLE IF EXISTS domains                CASCADE;
DROP TABLE IF EXISTS casbin_rule            CASCADE;

-- 2) Core tables
CREATE TABLE users (
  user_id       TEXT PRIMARY KEY,
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name     TEXT
);

CREATE TABLE domains (
  domain_id   TEXT PRIMARY KEY,
  domain_name TEXT NOT NULL,
  domain_type TEXT NOT NULL
);

-- Casbin policy store (table name/shape expected by casbin-pg-adapter)
CREATE TABLE casbin_rule (
  ptype TEXT,
  v0    TEXT,
  v1    TEXT,
  v2    TEXT,
  v3    TEXT,
  v4    TEXT,
  v5    TEXT
);

-- 3) App tables
CREATE TABLE product_ledger (
  ledger_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_lot_id   TEXT NOT NULL,
  status           TEXT NOT NULL,                     -- e.g. 'MANUFACTURED','RECEIVED_BY_CLINIC'
  actor_domain_id  TEXT REFERENCES domains(domain_id),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE products (
  product_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_name       TEXT NOT NULL,
  traceability_level TEXT NOT NULL                 -- 'VACCINE' or 'FAST_WIN'
);

CREATE TABLE pet_owner_clinic_links (
  link_id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_owner_domain_id   TEXT REFERENCES domains(domain_id),
  clinic_domain_id      TEXT REFERENCES domains(domain_id),
  status                TEXT NOT NULL DEFAULT 'PENDING'   -- 'PENDING','APPROVED'
);

-- 4) Indexes (performance + idempotency for Casbin rules)
-- Unique composite index enables ON CONFLICT (columns...) DO NOTHING
CREATE UNIQUE INDEX IF NOT EXISTS casbin_rule_unique_idx
  ON casbin_rule (ptype, v0, v1, v2, v3, v4, v5);

CREATE INDEX IF NOT EXISTS casbin_rule_ptype_idx ON casbin_rule (ptype);
CREATE INDEX IF NOT EXISTS casbin_rule_v0_idx     ON casbin_rule (v0);
CREATE INDEX IF NOT EXISTS casbin_rule_v1_idx     ON casbin_rule (v1);
CREATE INDEX IF NOT EXISTS casbin_rule_v2_idx     ON casbin_rule (v2);
CREATE INDEX IF NOT EXISTS casbin_rule_v3_idx     ON casbin_rule (v3);

-- 5) Seed data (safe to re-run)

-- Users (demo hashes; for real, register via /auth/register)
INSERT INTO users (user_id, email, password_hash, full_name) VALUES
  ('user-jane', 'jane@clinic.com', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAg3G2z9rPmqe6G8aoe4w9u1e5X.W', 'Dr. Jane'),
  ('user-joe',  'joe@clinic.com',  '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAg3G2z9rPmqe6G8aoe4w9u1e5X.W', 'Manager Joe'),
  ('user-sara', 'sara@other.com',  '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAg3G2z9rPmqe6G8aoe4w9u1e5X.W', 'Dr. Sara')
ON CONFLICT (user_id) DO NOTHING;

-- Root domain + admin user
INSERT INTO domains (domain_id, domain_name, domain_type) VALUES
  ('vina_root', 'vina_root', 'VINA_ROOT')
ON CONFLICT (domain_id) DO NOTHING;

INSERT INTO users (user_id, email, password_hash, full_name) VALUES
  ('user-root', 'root@vinaveritas.com', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAg3G2z9rPmqe6G8aoe4w9u1e5X.W', 'VinaVeritas Admin')
ON CONFLICT (user_id) DO NOTHING;

-- Demo clinic domains
INSERT INTO domains (domain_id, domain_name, domain_type) VALUES
  ('clinic-abc', 'clinic-abc', 'CLINIC'),
  ('clinic-xyz', 'clinic-xyz', 'CLINIC')
ON CONFLICT (domain_id) DO NOTHING;

-- Grouping rules (g): user -> role -> domain
INSERT INTO casbin_rule (ptype, v0, v1, v2) VALUES
  ('g','user-jane','clinic_doctor','clinic-abc'),
  ('g','user-joe', 'clinic_manager','clinic-abc'),
  ('g','user-sara','clinic_doctor','clinic-xyz'),
  ('g','user-root','vv_admin','vina_root')
ON CONFLICT (ptype, v0, v1, v2, v3, v4, v5) DO NOTHING;

-- Policy rules (p): role -> domain -> object -> action
INSERT INTO casbin_rule (ptype, v0,           v1,          v2,            v3) VALUES
  ('p',  'clinic_doctor','clinic-abc','patient_data','read'),
  ('p',  'clinic_manager','clinic-abc','patient_data','read'),
  ('p',  'clinic_manager','clinic-abc','patient_data','write'),
  ('p',  'clinic_doctor','clinic-xyz','patient_data','read')
ON CONFLICT (ptype, v0, v1, v2, v3, v4, v5) DO NOTHING;

-- 6) Optional starters
-- INSERT INTO products (product_name, traceability_level) VALUES ('VV Vaccine A','VACCINE'), ('VV Supplement B','FAST_WIN');
-- INSERT INTO product_ledger (product_lot_id, status, actor_domain_id) VALUES ('LOT-ABC-001','MANUFACTURED','vina_root');
