-- 002_owners_ledger.sql
-- Adds tables for owner links, products, and product ledger (idempotent).

-- Ensure UUID generator is available (safe if already installed)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Pet owner <-> clinic links
CREATE TABLE IF NOT EXISTS pet_owner_clinic_links (
  link_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_owner_domain_id TEXT REFERENCES domains(domain_id),
  clinic_domain_id TEXT REFERENCES domains(domain_id),
  status TEXT NOT NULL DEFAULT 'PENDING',  -- 'PENDING', 'APPROVED'
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pocl_clinic ON pet_owner_clinic_links (clinic_domain_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pocl_owner  ON pet_owner_clinic_links (pet_owner_domain_id);
CREATE INDEX IF NOT EXISTS idx_pocl_status ON pet_owner_clinic_links (status);

-- Products
CREATE TABLE IF NOT EXISTS products (
  product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_name TEXT NOT NULL,
  traceability_level TEXT NOT NULL  -- e.g., 'VACCINE', 'FAST_WIN'
);
CREATE INDEX IF NOT EXISTS idx_products_name ON products (product_name);

-- Product ledger (immutable-ish event log)
CREATE TABLE IF NOT EXISTS product_ledger (
  ledger_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_lot_id TEXT NOT NULL,          -- unique QR/lot ID
  status TEXT NOT NULL,                   -- 'MANUFACTURED', 'RECEIVED_BY_CLINIC', 'SCANNED', 'ADMIN_NOTE'
  actor_domain_id TEXT REFERENCES domains(domain_id), -- who recorded the event? (clinic, manufacturer, etc.)
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ledger_lot     ON product_ledger (product_lot_id);
CREATE INDEX IF NOT EXISTS idx_ledger_actor_t ON product_ledger (actor_domain_id, created_at DESC);
