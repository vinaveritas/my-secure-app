CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS patients (
  patient_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_domain_id  TEXT REFERENCES domains(domain_id) ON DELETE SET NULL,
  owner_user_id     TEXT REFERENCES users(user_id) ON DELETE SET NULL,
  name              TEXT NOT NULL,
  species           TEXT NOT NULL,
  breed             TEXT,
  dob               DATE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS patients_by_clinic_idx
  ON patients (clinic_domain_id, created_at DESC);
