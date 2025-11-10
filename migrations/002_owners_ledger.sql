-- 002_owners_ledger.sql (idempotent, CI-safe)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- products
CREATE TABLE IF NOT EXISTS products (
  product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_name TEXT NOT NULL,
  traceability_level TEXT NOT NULL CHECK (traceability_level IN ('VACCINE','FAST_WIN')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE products
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
CREATE INDEX IF NOT EXISTS idx_products_name ON products (product_name);

-- product_ledger (event log)
CREATE TABLE IF NOT EXISTS product_ledger (
  ledger_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_lot_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('MANUFACTURED','RECEIVED_BY_CLINIC','ISSUED_TO_OWNER')),
  actor_domain_id TEXT REFERENCES domains(domain_id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE product_ledger
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
CREATE INDEX IF NOT EXISTS idx_prod_ledger_lot        ON product_ledger (product_lot_id);
CREATE INDEX IF NOT EXISTS idx_prod_ledger_status     ON product_ledger (status);
CREATE INDEX IF NOT EXISTS idx_prod_ledger_created_at ON product_ledger (created_at);

-- pet_owner_clinic_links
CREATE TABLE IF NOT EXISTS pet_owner_clinic_links (
  link_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_owner_domain_id TEXT REFERENCES domains(domain_id),
  clinic_domain_id     TEXT REFERENCES domains(domain_id),
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','APPROVED','DEACTIVATED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- If an earlier migration created this table without created_at, add it now:
ALTER TABLE pet_owner_clinic_links
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_pocl_owner       ON pet_owner_clinic_links (pet_owner_domain_id);
CREATE INDEX IF NOT EXISTS idx_pocl_clinic      ON pet_owner_clinic_links (clinic_domain_id);
CREATE INDEX IF NOT EXISTS idx_pocl_status      ON pet_owner_clinic_links (status);
CREATE INDEX IF NOT EXISTS idx_pocl_created_at  ON pet_owner_clinic_links (created_at);
