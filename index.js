/* --- VinaVeritas Nexus API (Phase 0: soft-delete, no hard delete) --- */
require('dotenv').config();
const express = require('express');
const { newEnforcer } = require('casbin');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');
const { expressjwt } = require('express-jwt');

/* 1) Config */
const app = express();
app.use(express.json());
const PORT = Number(process.env.PORT) || 3001;
const JWT_SECRET = process.env.JWT_SECRET || 'dev-only-secret-change-me';

/* 2) Postgres (pg.Pool) */
const dbOptions = {
  user: process.env.PGUSER || 'xander23',
  host: process.env.PGHOST || 'localhost',
  database: process.env.PGDATABASE || 'vinaveritas_db',
  password: process.env.PGPASSWORD || '',
  port: Number(process.env.PGPORT) || 5432,
};
const dbPool = new Pool(dbOptions);

/* 3) Casbin adapter (robust import shapes) */
async function createCasbinPgAdapter(pool) {
  const mod = require('casbin-pg-adapter'); // works with 1.4.x
  if (typeof mod?.newAdapter === 'function') {
    console.log('casbin-pg-adapter: using mod.newAdapter(options)');
    return await mod.newAdapter({ pool });
  }
  if (typeof mod?.default?.newAdapter === 'function') {
    console.log('casbin-pg-adapter: using mod.default.newAdapter(options)');
    return await mod.default.newAdapter({ pool });
  }
  throw new Error(
    `Unsupported casbin-pg-adapter export shape. Keys: ${Object.keys(mod).join(', ')}`
  );
}

/* 4) Helpers */
const auth = expressjwt({ secret: JWT_SECRET, algorithms: ['HS256'] });

async function requireAccess(enforcer, sub, dom, obj, act) {
  return enforcer.enforce(sub, dom, obj, act);
}

function validateDob(dob) {
  if (dob === undefined || dob === null || dob === '') return null; // optional
  const d = new Date(dob);
  if (Number.isNaN(d.getTime())) return 'dob must be a valid date (YYYY-MM-DD)';
  const now = new Date();
  if (d > now) return 'dob cannot be in the future';
  return null;
}

function validatePatientPayload(body, isCreate = true) {
  const errors = [];
  const { name, species, breed, dob, archived } = body || {};

  if (isCreate) {
    if (!name || !String(name).trim()) errors.push('name is required');
    if (!species || !String(species).trim()) errors.push('species is required');
  }

  if (name !== undefined && String(name).trim().length > 100) errors.push('name max length is 100');
  if (species !== undefined && String(species).trim().length > 50) errors.push('species max length is 50');
  if (breed !== undefined && String(breed).trim().length > 100) errors.push('breed max length is 100');

  const dobErr = validateDob(dob);
  if (dobErr) errors.push(dobErr);

  if (archived !== undefined && typeof archived !== 'boolean') {
    errors.push('archived must be boolean when provided');
  }

  return errors;
}

/* 5) Main */
async function initializeServer() {
  console.log('Connecting to PostgreSQL...');
  const dbAdapter = await createCasbinPgAdapter(dbPool);
  const enforcer = await newEnforcer('model.conf', dbAdapter);
  await enforcer.enableAutoSave(true);
  await enforcer.loadPolicy();
  console.log('Enforcer loaded from database. Server is ready!');

  /* --- Routes --- */

  // Health
  app.get('/healthz', (req, res) =>
    res
      .set('Cache-Control', 'no-store')
      .set('Access-Control-Allow-Origin', '*')
      .json({ ok: true, uptime: process.uptime() })
  );

  // Login
  app.get('/login/:userId', async (req, res) => {
    try {
      const userId = req.params.userId;
      const gps = await enforcer.getFilteredGroupingPolicy(0, userId); // [[sub, role, dom], ...]
      if (!gps || gps.length === 0) {
        return res.status(404).json({ error: `User '${userId}' has no assigned roles or policies.` });
      }
      const [, role, clinicId] = gps[0];
      const token = jwt.sign({ sub: userId, role, clinic_id: clinicId }, JWT_SECRET, {
        expiresIn: '1h',
        algorithm: 'HS256',
      });
      return res.json({ message: `Login successful for ${userId}!`, token });
    } catch (err) {
      console.error('Error in login endpoint:', err);
      return res.status(500).json({ error: 'Internal server error' });
    }
  });

  // SIGNUP (bind user->role@domain + ensure read/write policies exist)
  app.post('/api/v6/signup/clinic', async (req, res) => {
    try {
      const { newUserId, newClinicId, newRole } = req.body || {};
      if (!newUserId || !newClinicId || !newRole) {
        return res.status(400).json({ error: 'newUserId, newClinicId, and newRole are required.' });
      }
      await enforcer.addPolicy(newRole, newClinicId, 'patient_data', 'read');
      await enforcer.addPolicy(newRole, newClinicId, 'patient_data', 'write');
      await enforcer.addGroupingPolicy(newUserId, newRole, newClinicId);
      return res.json({ status: 'success', message: `User ${newUserId} successfully added to ${newClinicId}.` });
    } catch (err) {
      console.error('Error in signup endpoint:', err);
      return res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Patients: READ (paginated, archived=false by default; includeArchived=true to include)
  app.get('/clinics/:clinicId/patients', auth, async (req, res) => {
    try {
      const userId = req.auth.sub;
      const clinicId = req.params.clinicId;
      const canRead = await requireAccess(enforcer, userId, clinicId, 'patient_data', 'read');
      if (!canRead) return res.status(403).json({ error: 'Forbidden' });

      const page = Math.max(1, Number(req.query.page) || 1);
      const pageSize = Math.min(50, Math.max(1, Number(req.query.pageSize) || 10));
      const includeArchived = String(req.query.includeArchived || 'false').toLowerCase() === 'true';
      const offset = (page - 1) * pageSize;

      let sql =
        `SELECT patient_id, clinic_domain_id, owner_user_id, name, species, breed, dob, archived, created_at
           FROM patients
          WHERE clinic_domain_id = $1`;
      const params = [clinicId];

      if (!includeArchived) {
        sql += ` AND archived = false`;
      }

      sql += ` ORDER BY created_at DESC LIMIT $2 OFFSET $3`;
      params.push(pageSize, offset);

      const { rows } = await dbPool.query(sql, params);
      return res.json({ items: rows, page, pageSize });
    } catch (err) {
      console.error('Error in GET patients:', err);
      return res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Patients: CREATE
  app.post('/clinics/:clinicId/patients', auth, async (req, res) => {
    try {
      const userId = req.auth.sub;
      const clinicId = req.params.clinicId;
      const canWrite = await requireAccess(enforcer, userId, clinicId, 'patient_data', 'write');
      if (!canWrite) return res.status(403).json({ error: 'Forbidden' });

      const errors = validatePatientPayload(req.body, true);
      if (errors.length) return res.status(400).json({ errors });

      const { name, species, breed, dob } = req.body;
      const { rows } = await dbPool.query(
        `INSERT INTO patients (clinic_domain_id, owner_user_id, name, species, breed, dob, archived)
         VALUES ($1, NULL, $2, $3, $4, $5, false)
         RETURNING patient_id, clinic_domain_id, owner_user_id, name, species, breed, dob, archived, created_at`,
        [clinicId, name?.trim(), species?.trim(), (breed ?? '').trim() || null, dob || null]
      );
      return res.status(201).json({ patient: rows[0] });
    } catch (err) {
      console.error('Error in POST patient:', err);
      return res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Patients: UPDATE (PATCH) — supports archived true/false
  app.patch('/clinics/:clinicId/patients/:patientId', auth, async (req, res) => {
    try {
      const userId = req.auth.sub;
      const clinicId = req.params.clinicId;
      const patientId = req.params.patientId;
      const canWrite = await requireAccess(enforcer, userId, clinicId, 'patient_data', 'write');
      if (!canWrite) return res.status(403).json({ error: 'Forbidden' });

      const errors = validatePatientPayload(req.body, false);
      if (errors.length) return res.status(400).json({ errors });

      const fields = [];
      const values = [];
      const allowed = {
        name: 'name',
        species: 'species',
        breed: 'breed',
        ownerUserId: 'owner_user_id',
        dob: 'dob',
        archived: 'archived',
      };

      let i = 1;
      for (const [key, col] of Object.entries(allowed)) {
        if (req.body[key] !== undefined) {
          fields.push(`${col} = $${i++}`);
          let value = req.body[key];

          if (key === 'archived') {
            value = Boolean(value);
          }
          if (typeof value === 'string') {
            value = value.trim();
            if (value === '') value = null;
          }

          values.push(value);
        }
      }

      if (fields.length === 0) return res.status(400).json({ error: 'No updatable fields provided.' });

      values.push(clinicId);  // $i
      values.push(patientId); // $i+1

      const sql = `
        UPDATE patients
           SET ${fields.join(', ')}
         WHERE clinic_domain_id = $${i} AND patient_id = $${i + 1}
         RETURNING patient_id, clinic_domain_id, owner_user_id, name, species, breed, dob, archived, created_at
      `;

      const { rows } = await dbPool.query(sql, values);
      if (rows.length === 0) return res.status(404).json({ error: 'Patient not found' });
      return res.json({ patient: rows[0] });
    } catch (err) {
      console.error('Error in PATCH patient:', err);
      return res.status(500).json({ error: 'Internal server error' });
    }
  });

  // No hard DELETE: return 405
  app.delete('/clinics/:clinicId/patients/:patientId', auth, (req, res) => {
    return res.status(405).json({ error: 'Hard delete is disabled. Use PATCH { archived: true }.' });
  });

  // Unauthorized handler
  app.use((err, req, res, next) => {
    if (err && err.name === 'UnauthorizedError') {
      return res.status(401).json({ error: 'Invalid or expired token.' });
    }
    return next(err);
  });

  // Start & graceful shutdown
  const server = app.listen(PORT, () => {
    console.log(`Server is running at http://localhost:${PORT}`);
  });
  const shutdown = async () => {
    console.log('Shutting down...');
    server.close(() => console.log('HTTP server closed.'));
    await dbPool.end();
    process.exit(0);
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

initializeServer();
