-- Soft delete / archive support for patients
BEGIN;

ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS archived BOOLEAN NOT NULL DEFAULT FALSE;

-- Helpful index: fast lists by clinic + archived flag + recency
CREATE INDEX IF NOT EXISTS idx_patients_clinic_archived_created
  ON patients (clinic_domain_id, archived, created_at DESC);

COMMIT;
