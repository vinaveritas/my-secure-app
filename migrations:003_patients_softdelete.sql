-- migrations/003_patients_softdelete.sql
-- Soft-delete for patients: add is_active + archived_at and index

BEGIN;

-- 1) Add columns safely (idempotent)
ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN,
  ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

-- 2) Ensure defaults and not-null for is_active
ALTER TABLE patients
  ALTER COLUMN is_active SET DEFAULT TRUE;

UPDATE patients
   SET is_active = TRUE
 WHERE is_active IS NULL;

ALTER TABLE patients
  ALTER COLUMN is_active SET NOT NULL;

-- 3) Helpful index for common queries (active first)
CREATE INDEX IF NOT EXISTS patients_active_idx
  ON patients (clinic_domain_id, is_active, created_at DESC);

COMMIT;
