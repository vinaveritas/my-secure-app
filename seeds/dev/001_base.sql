-- seeds/dev/001_base.sql
-- Dev seed data for domains, users, casbin rules, patients, owner links, products, and ledger.
-- Safe to re-run (idempotent).

BEGIN;

-- Ensure UUID generator
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ===== Domains =====
INSERT INTO domains (domain_id, domain_name, domain_type) VALUES
('clinic-abc','clinic-abc','CLINIC')
ON CONFLICT (domain_id) DO NOTHING;

INSERT INTO domains (domain_id, domain_name, domain_type) VALUES
('vina_root','vina_root','VINA_ROOT')
ON CONFLICT (domain_id) DO NOTHING;

INSERT INTO domains (domain_id, domain_name, domain_type) VALUES
('owner-alice','owner-alice','PET_OWNER')
ON CONFLICT (domain_id) DO NOTHING;

-- ===== Users =====
INSERT INTO users (user_id, email, password_hash, full_name) VALUES
('user-jane','jane@clinic.com','...','Dr. Jane')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO users (user_id, email, password_hash, full_name) VALUES
('user-joe','joe@clinic.com','...','Manager Joe')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO users (user_id, email, password_hash, full_name) VALUES
('user-root','root@vinaveritas.com','...','VV Admin')
ON CONFLICT (user_id) DO NOTHING;

-- ===== Casbin Grouping (g): user -> role @ domain =====
INSERT INTO casbin_rule (ptype, v0, v1, v2)
SELECT 'g','user-jane','clinic_doctor','clinic-abc'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rule WHERE ptype='g' AND v0='user-jane' AND v1='clinic_doctor' AND v2='clinic-abc'
);

INSERT INTO casbin_rule (ptype, v0, v1, v2)
SELECT 'g','user-joe','clinic_manager','clinic-abc'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rule WHERE ptype='g' AND v0='user-joe' AND v1='clinic_manager' AND v2='clinic-abc'
);

INSERT INTO casbin_rule (ptype, v0, v1, v2)
SELECT 'g','user-root','vv_admin','vina_root'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rule WHERE ptype='g' AND v0='user-root' AND v1='vv_admin' AND v2='vina_root'
);

-- ===== Casbin Policies (p): role permissions =====
-- clinic_doctor@clinic-abc can read patient_data
INSERT INTO casbin_rule (ptype, v0, v1, v2, v3)
SELECT 'p','clinic_doctor','clinic-abc','patient_data','read'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rule WHERE ptype='p' AND v0='clinic_doctor' AND v1='clinic-abc' AND v2='patient_data' AND v3='read'
);

-- clinic_manager@clinic-abc can read + write patient_data
INSERT INTO casbin_rule (ptype, v0, v1, v2, v3)
SELECT 'p','clinic_manager','clinic-abc','patient_data','read'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rule WHERE ptype='p' AND v0='clinic_manager' AND v1='clinic-abc' AND v2='patient_data' AND v3='read'
);

INSERT INTO casbin_rule (ptype, v0, v1, v2, v3)
SELECT 'p','clinic_manager','clinic-abc','patient_data','write'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rule WHERE ptype='p' AND v0='clinic_manager' AND v1='clinic-abc' AND v2='patient_data' AND v3='write'
);

-- vv_admin@vina_root admin wildcard (example capability)
INSERT INTO casbin_rule (ptype, v0, v1, v2, v3)
SELECT 'p','vv_admin','vina_root','admin','*'
WHERE NOT EXISTS (
  SELECT 1 FROM casbin_rule WHERE ptype='p' AND v0='vv_admin' AND v1='vina_root' AND v2='admin' AND v3='*'
);

-- ===== Patients (two examples) =====
INSERT INTO patients (clinic_domain_id, owner_user_id, name, species, breed, dob)
SELECT 'clinic-abc','user-jane','Buddy','Dog','Beagle','2020-04-20'
WHERE NOT EXISTS (
  SELECT 1 FROM patients WHERE clinic_domain_id='clinic-abc' AND name='Buddy' AND dob='2020-04-20'
);

INSERT INTO patients (clinic_domain_id, owner_user_id, name, species, breed, dob)
SELECT 'clinic-abc',NULL,'Milo','Cat','Siamese','2021-09-01'
WHERE NOT EXISTS (
  SELECT 1 FROM patients WHERE clinic_domain_id='clinic-abc' AND name='Milo' AND dob='2021-09-01'
);

-- ===== Owner links =====
INSERT INTO pet_owner_clinic_links (pet_owner_domain_id, clinic_domain_id, status)
SELECT 'owner-alice','clinic-abc','PENDING'
WHERE NOT EXISTS (
  SELECT 1 FROM pet_owner_clinic_links WHERE pet_owner_domain_id='owner-alice' AND clinic_domain_id='clinic-abc' AND status='PENDING'
);

INSERT INTO pet_owner_clinic_links (pet_owner_domain_id, clinic_domain_id, status)
SELECT 'owner-alice','clinic-abc','APPROVED'
WHERE NOT EXISTS (
  SELECT 1 FROM pet_owner_clinic_links WHERE pet_owner_domain_id='owner-alice' AND clinic_domain_id='clinic-abc' AND status='APPROVED'
);

-- ===== Products + Ledger =====
INSERT INTO products (product_name, traceability_level)
SELECT 'VV Vaccine A','VACCINE'
WHERE NOT EXISTS (
  SELECT 1 FROM products WHERE product_name='VV Vaccine A' AND traceability_level='VACCINE'
);

INSERT INTO product_ledger (product_lot_id, status, actor_domain_id)
SELECT 'LOT-001','MANUFACTURED','vina_root'
WHERE NOT EXISTS (
  SELECT 1 FROM product_ledger WHERE product_lot_id='LOT-001' AND status='MANUFACTURED' AND actor_domain_id='vina_root'
);

INSERT INTO product_ledger (product_lot_id, status, actor_domain_id)
SELECT 'LOT-001','RECEIVED_BY_CLINIC','clinic-abc'
WHERE NOT EXISTS (
  SELECT 1 FROM product_ledger WHERE product_lot_id='LOT-001' AND status='RECEIVED_BY_CLINIC' AND actor_domain_id='clinic-abc'
);

COMMIT;
