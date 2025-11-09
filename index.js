// index.js — VinaVeritas Phase 1 (DX + Auth + Admin Policy API + Patients API)

let dotenvLoaded = false;
try { require('dotenv').config(); dotenvLoaded = true; } catch (_) {
  console.warn('[warn] dotenv not installed — skipping .env load. (Run: npm i dotenv)');
}

const express = require('express');
const morgan = require('morgan');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcrypt');
const { newEnforcer } = require('casbin');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');
const { expressjwt } = require('express-jwt');

const app = express();
app.use(morgan('dev'));
app.use(cors());
app.use(express.json());
app.use(rateLimit({ windowMs: 60_000, max: 120 }));

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'CHANGE-ME-super-secret';

const dbOptions = process.env.DATABASE_URL
  ? { connectionString: process.env.DATABASE_URL }
  : {
      user: process.env.PGUSER || 'xander23',
      host: process.env.PGHOST || 'localhost',
      database: process.env.PGDATABASE || 'vinaveritas_db',
      password: process.env.PGPASSWORD ?? '',
      port: Number(process.env.PGPORT) || 5432,
    };
const dbPool = new Pool(dbOptions);

// ---------- casbin-pg-adapter discovery ----------
function findFactory(obj, seen = new Set(), depth = 0) {
  if (!obj || depth > 5 || seen.has(obj)) return null;
  seen.add(obj);
  if (typeof obj.newAdapter === 'function') return obj.newAdapter;
  if (typeof obj === 'function') return obj;
  const candidates = [obj.default, obj.module && obj.module.exports, obj.exports, obj['module.exports']].filter(Boolean);
  for (const c of candidates) { const f = findFactory(c, seen, depth + 1); if (f) return f; }
  for (const k of Object.keys(obj)) { try { const f = findFactory(obj[k], seen, depth + 1); if (f) return f; } catch(_){} }
  return null;
}
async function resolveAdapterFactory() {
  let mod; try { mod = await import('casbin-pg-adapter'); } catch (_) {}
  let factory = mod && findFactory(mod);
  if (!factory) { try { factory = findFactory(require('casbin-pg-adapter')); } catch(_){} }
  if (!factory) throw new Error('Unsupported casbin-pg-adapter export shape');
  return factory;
}
async function createCasbinPgAdapter(pool) {
  const factory = await resolveAdapterFactory();
  try { return await factory({ pool }); }
  catch (_) {
    const opts = process.env.DATABASE_URL ? { connectionString: process.env.DATABASE_URL } : dbOptions;
    return await factory(opts);
  }
}

// ---------- HATEOAS ----------
async function buildLinks(enforcer, userId, clinicId) {
  const patientResource = 'patient_data';
  const _links = { self: { href: `/api/v6/patients/${clinicId}/patient-xyz` } };
  const canRead  = await enforcer.enforce(userId, clinicId, patientResource, 'read');
  const canWrite = await enforcer.enforce(userId, clinicId, patientResource, 'write');
  if (canRead)  _links.read_charts  = { href: `/api/v6/patients/${clinicId}/patient-xyz/charts` };
  if (canWrite) _links.write_charts = { href: `/api/v6/patients/${clinicId}/patient-xyz/charts`, method: 'POST' };
  return _links;
}

let enforcer;

async function initializeServer() {
  if (!dotenvLoaded) console.log('[info] Running with process.env only; .env not loaded.');
  console.log('Connecting to PostgreSQL...');
  await dbPool.query('select 1');

  const dbAdapter = await createCasbinPgAdapter(dbPool);
  enforcer = await newEnforcer('model.conf', dbAdapter);
  await enforcer.enableAutoSave(true);
  await enforcer.loadPolicy();

  console.log('Enforcer loaded from database. Server is ready!');

  // Health / Debug
  app.get('/healthz', (_req, res) => res.json({ ok: true, uptime: process.uptime() }));
  app.get('/_debug/casbin', async (_req, res) => {
    const p = await enforcer.getPolicy();
    const g = await enforcer.getGroupingPolicy();
    res.json({ p, g });
  });

  // Auth (email/password)
  app.post('/auth/register', async (req, res) => {
    try {
      const { userId, email, fullName, password } = req.body || {};
      if (!userId || !email || !password) return res.status(400).json({ error: 'userId, email, password are required.' });
      const passwordHash = await bcrypt.hash(password, 12);
      await dbPool.query(
        'INSERT INTO users (user_id, email, password_hash, full_name) VALUES ($1,$2,$3,$4) ON CONFLICT (user_id) DO NOTHING',
        [userId, email, passwordHash, fullName || null]
      );
      res.json({ status: 'ok' });
    } catch (e) {
      console.error('register error', e);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  app.post('/auth/login', async (req, res) => {
    try {
      const { email, password } = req.body || {};
      if (!email || !password) return res.status(400).json({ error: 'email and password are required.' });

      const r = await dbPool.query('SELECT user_id, password_hash FROM users WHERE email=$1 LIMIT 1', [email]);
      if (r.rowCount === 0) return res.status(401).json({ error: 'Invalid credentials' });

      const { user_id, password_hash } = r.rows[0];
      const ok = await bcrypt.compare(password, password_hash);
      if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

      const rules = await enforcer.getFilteredGroupingPolicy(0, user_id);
      if (rules.length === 0) return res.status(403).json({ error: 'No assigned roles/policies for this user.' });
      const [, role, clinicId] = rules[0];

      const token = jwt.sign({ sub: user_id, clinic_id: clinicId, role }, JWT_SECRET, { expiresIn: '1h' });
      res.json({ token });
    } catch (e) {
      console.error('auth login error', e);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Helper login
  app.get('/login/:userId', async (req, res) => {
    try {
      const userId = req.params.userId;
      const rules = await enforcer.getFilteredGroupingPolicy(0, userId);
      if (rules.length === 0) return res.status(404).json({ error: `User '${userId}' has no assigned roles or policies.` });
      const [, role, clinicId] = rules[0];
      const token = jwt.sign({ sub: userId, clinic_id: clinicId, role }, JWT_SECRET, { expiresIn: '1h' });
      res.json({ message: `Login successful for ${userId}!`, token });
    } catch (e) {
      console.error('Login error:', e);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Secure demo route
  app.get('/my-patient-data', expressjwt({ secret: JWT_SECRET, algorithms: ['HS256'] }), async (req, res) => {
    try {
      const { sub: userId, clinic_id: clinicId } = req.auth;
      const links = await buildLinks(enforcer, userId, clinicId);
      res.json({ message: `Your custom patient data for clinic ${clinicId}`, _links: links });
    } catch (e) {
      console.error('Secure endpoint error:', e);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Tenant signup (role perms + binding)
  app.post('/api/v6/signup/clinic', async (req, res) => {
    try {
      const { newUserId, newClinicId, newRole } = req.body || {};
      if (!newUserId || !newClinicId || !newRole) return res.status(400).json({ error: 'newUserId, newClinicId, and newRole are required.' });
      await enforcer.addPolicy(newRole, newClinicId, 'patient_data', 'read');
      await enforcer.addGroupingPolicy(newUserId, newRole, newClinicId);
      res.json({ status: 'success', message: `User ${newUserId} successfully added to ${newClinicId}.` });
    } catch (e) {
      console.error('Signup error:', e);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Admin Policy API
  const requireJwt = expressjwt({ secret: JWT_SECRET, algorithms: ['HS256'] });
  function adminOnly(req, res, next) {
    const { role, clinic_id: dom } = req.auth || {};
    if (role === 'vv_admin' && dom === 'vina_root') return next();
    return res.status(403).json({ error: 'Admin only' });
  }
  app.get('/admin/policies', requireJwt, adminOnly, async (_req, res) => res.json({ p: await enforcer.getPolicy() }));
  app.get('/admin/groupings', requireJwt, adminOnly, async (_req, res) => res.json({ g: await enforcer.getGroupingPolicy() }));
  app.post('/admin/policy', requireJwt, adminOnly, async (req, res) => {
    const { sub, dom, obj, act } = req.body || {};
    if (!sub || !dom || !obj || !act) return res.status(400).json({ error: 'sub, dom, obj, act are required.' });
    res.json({ ok: await enforcer.addPolicy(sub, dom, obj, act) });
  });
  app.delete('/admin/policy', requireJwt, adminOnly, async (req, res) => {
    const { sub, dom, obj, act } = req.body || {};
    if (!sub || !dom || !obj || !act) return res.status(400).json({ error: 'sub, dom, obj, act are required.' });
    res.json({ ok: await enforcer.removePolicy(sub, dom, obj, act) });
  });
  app.post('/admin/grouping', requireJwt, adminOnly, async (req, res) => {
    const { userId, role, domain } = req.body || {};
    if (!userId || !role || !domain) return res.status(400).json({ error: 'userId, role, domain are required.' });
    res.json({ ok: await enforcer.addGroupingPolicy(userId, role, domain) });
  });
  app.delete('/admin/grouping', requireJwt, adminOnly, async (req, res) => {
    const { userId, role, domain } = req.body || {};
    if (!userId || !role || !domain) return res.status(400).json({ error: 'userId, role, domain are required.' });
    res.json({ ok: await enforcer.removeGroupingPolicy(userId, role, domain) });
  });

  // Patients API (tenant-scoped)
  async function can(enf, userId, clinicId, act) {
    if (!userId || !clinicId) return false;
    const rules = await enf.getFilteredGroupingPolicy(0, userId);
    const isAdmin = rules.some(r => r[1] === 'vv_admin' && r[2] === 'vina_root');
    if (isAdmin) return true;
    return enf.enforce(userId, clinicId, 'patient_data', act);
  }

  app.get('/clinics/:clinicId/patients', requireJwt, async (req, res) => {
    try {
      const { clinicId } = req.params;
      const userId = req.auth.sub;
      if (!(await can(enforcer, userId, clinicId, 'read'))) return res.status(403).json({ error: 'Forbidden' });
      const r = await dbPool.query(
        `SELECT patient_id, clinic_domain_id, owner_user_id, name, species, breed, dob, created_at
         FROM patients
         WHERE clinic_domain_id = $1
         ORDER BY created_at DESC
         LIMIT 200`,
        [clinicId]
      );
      res.json({ items: r.rows });
    } catch (e) {
      console.error('GET patients error:', e);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  app.post('/clinics/:clinicId/patients', requireJwt, async (req, res) => {
    try {
      const { clinicId } = req.params;
      const userId = req.auth.sub;
      if (!(await can(enforcer, userId, clinicId, 'write'))) return res.status(403).json({ error: 'Forbidden' });
      const { name, species, breed, dob, ownerUserId } = req.body || {};
      if (!name || !species) return res.status(400).json({ error: 'name and species are required.' });
      const r = await dbPool.query(
        `INSERT INTO patients (clinic_domain_id, owner_user_id, name, species, breed, dob)
         VALUES ($1,$2,$3,$4,$5,$6)
         RETURNING patient_id, clinic_domain_id, owner_user_id, name, species, breed, dob, created_at`,
        [clinicId, ownerUserId || null, name, species, breed || null, dob || null]
      );
      res.status(201).json({ patient: r.rows[0] });
    } catch (e) {
      console.error('POST patient error:', e);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // JWT Unauthorized handler
  app.use((err, _req, res, next) => {
    if (err.name === 'UnauthorizedError') return res.status(401).json({ error: 'Invalid or expired token.' });
    return next(err);
  });

  const server = app.listen(PORT, () => console.log(`Server is running at http://localhost:${PORT}`));
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
