-- users (demo hash = bcrypt('password') — dev only)
INSERT INTO users (user_id, email, password_hash, full_name) VALUES
  ('user-jane','jane@clinic.com','$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAg3G2z9rPmqe6G8aoe4w9u1e5X.W','Dr. Jane'),
  ('user-joe','joe@clinic.com','$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAg3G2z9rPmqe6G8aoe4w9u1e5X.W','Manager Joe'),
  ('user-sara','sara@other.com','$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAg3G2z9rPmqe6G8aoe4w9u1e5X.W','Dr. Sara'),
  ('user-root','root@vinaveritas.com','$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAg3G2z9rPmqe6G8aoe4w9u1e5X.W','VinaVeritas Admin')
ON CONFLICT (user_id) DO NOTHING;

-- domains
INSERT INTO domains (domain_id, domain_name, domain_type) VALUES
  ('vina_root','vina_root','VINA_ROOT'),
  ('clinic-abc','clinic-abc','CLINIC'),
  ('clinic-xyz','clinic-xyz','CLINIC')
ON CONFLICT (domain_id) DO NOTHING;

-- grouping (g): user -> role -> domain
INSERT INTO casbin_rule (ptype, v0, v1, v2) VALUES
  ('g','user-jane','clinic_doctor','clinic-abc'),
  ('g','user-joe','clinic_manager','clinic-abc'),
  ('g','user-sara','clinic_doctor','clinic-xyz'),
  ('g','user-root','vv_admin','vina_root')
ON CONFLICT (ptype, v0, v1, v2, v3, v4, v5) DO NOTHING;

-- policy (p): role -> domain -> obj -> act
INSERT INTO casbin_rule (ptype, v0, v1, v2, v3) VALUES
  ('p','clinic_doctor','clinic-abc','patient_data','read'),
  ('p','clinic_manager','clinic-abc','patient_data','read'),
  ('p','clinic_manager','clinic-abc','patient_data','write'),
  ('p','clinic_doctor','clinic-xyz','patient_data','read')
ON CONFLICT (ptype, v0, v1, v2, v3, v4, v5) DO NOTHING;

-- sample patient
INSERT INTO patients (clinic_domain_id, owner_user_id, name, species, breed, dob)
VALUES ('clinic-abc','user-jane','Buddy','Dog','Beagle','2020-04-20')
ON CONFLICT DO NOTHING;
