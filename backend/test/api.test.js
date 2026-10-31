const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const request = require('supertest');

process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';
process.env.JWT_EXPIRES_IN = '1h';

const app = require('../app');
const seedPrograms = require('../seed/seedPrograms');

const mongoUri = process.env.MONGODB_TEST_URI || 'mongodb://127.0.0.1:27017/campusflow_test';
let token;
const email = `alex.${Date.now()}@test.com`;

describe('CampusFlow API', () => {
  before(async () => {
    await mongoose.connect(mongoUri);
    await mongoose.connection.dropDatabase();
    await seedPrograms();
  });

  after(async () => {
    await mongoose.connection.dropDatabase();
    await mongoose.disconnect();
  });

  it('reports health and database status', async () => {
    const res = await request(app).get('/health');
    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'ok');
    assert.equal(res.body.database, 'connected');
    assert.ok(typeof res.body.uptime === 'number');
  });

  it('signs up a user and returns a token', async () => {
    const res = await request(app).post('/auth/signup').send({
      name: 'Alex Learner',
      email,
      password: 'secret12',
    });
    assert.equal(res.status, 201);
    assert.equal(res.body.user.email, email);
    assert.equal(res.body.user.password, undefined);
    assert.ok(res.body.token, 'Token should be returned on signup');
  });

  it('rejects duplicate signup', async () => {
    const res = await request(app).post('/auth/signup').send({
      name: 'Alex Learner',
      email,
      password: 'secret12',
    });
    assert.equal(res.status, 409);
  });

  it('rejects invalid login', async () => {
    const res = await request(app).post('/auth/login').send({
      email,
      password: 'wrong-password',
    });
    assert.equal(res.status, 401);
  });

  it('logs in and returns a token', async () => {
    const res = await request(app).post('/auth/login').send({
      email,
      password: 'secret12',
    });
    assert.equal(res.status, 200);
    assert.ok(res.body.token);
    token = res.body.token;
  });

  it('returns the current user', async () => {
    const res = await request(app).get('/auth/me').set('Authorization', `Bearer ${token}`);
    assert.equal(res.status, 200);
    assert.equal(res.body.user.email, email);
  });

  it('updates the current user profile', async () => {
    const res = await request(app)
      .put('/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Alex Updated' });
    assert.equal(res.status, 200);
    assert.equal(res.body.user.name, 'Alex Updated');
  });

  it('lists programs in the Flutter shape', async () => {
    const res = await request(app).get('/programs');
    assert.equal(res.status, 200);
    assert.ok(Array.isArray(res.body));
    const design = res.body.find((p) => p.id === 'p1');
    assert.equal(design.title, 'Design Thinking Workshop');
    assert.equal(design.category, 'Workshop');
    assert.ok(Number.isInteger(design.capacity));
  });

  it('filters programs by category and query', async () => {
    const resCat = await request(app).get('/programs?category=Seminar');
    assert.equal(resCat.status, 200);
    assert.ok(resCat.body.every((p) => p.category === 'Seminar'));

    const resQuery = await request(app).get('/programs?q=Design');
    assert.equal(resQuery.status, 200);
    assert.ok(resQuery.body.some((p) => p.id === 'p1'));
  });

  it('registers for a program once', async () => {
    const first = await request(app)
      .post('/programs/p1/register')
      .set('Authorization', `Bearer ${token}`);
    assert.equal(first.status, 201);
    assert.equal(first.body.message, 'Registration confirmed');

    const second = await request(app)
      .post('/programs/p1/register')
      .set('Authorization', `Bearer ${token}`);
    assert.equal(second.status, 409);
  });

  it('lists registrations', async () => {
    const res = await request(app)
      .get('/registrations')
      .set('Authorization', `Bearer ${token}`);
    assert.equal(res.status, 200);
    assert.equal(res.body[0].programId, 'p1');
    assert.equal(res.body[0].program.title, 'Design Thinking Workshop');
  });

  it('cancels a registration and decrements seats', async () => {
    const res = await request(app)
      .delete('/programs/p1/register')
      .set('Authorization', `Bearer ${token}`);
    assert.equal(res.status, 200);
    assert.equal(res.body.message, 'Registration cancelled successfully');

    // Re-register so registrations list has data for following tests
    const reReg = await request(app)
      .post('/programs/p1/register')
      .set('Authorization', `Bearer ${token}`);
    assert.equal(reReg.status, 201);
  });

  it('accepts feedback', async () => {
    const res = await request(app)
      .post('/programs/p1/feedback')
      .set('Authorization', `Bearer ${token}`)
      .send({
        rating: 5,
        category: 'Content',
        email,
        comment: 'Clear, practical, and well paced.',
      });
    assert.equal(res.status, 201);
    assert.equal(res.body.message, 'Thank you for your feedback!');
  });

  it('retrieves feedback for a program', async () => {
    const res = await request(app).get('/programs/p1/feedback');
    assert.equal(res.status, 200);
    assert.ok(Array.isArray(res.body));
    assert.ok(res.body.length >= 1);
  });

  it('rejects short feedback', async () => {
    const res = await request(app)
      .post('/programs/p1/feedback')
      .set('Authorization', `Bearer ${token}`)
      .send({
        rating: 4,
        category: 'Content',
        email,
        comment: 'too short',
      });
    assert.equal(res.status, 400);
  });

  it('lists, marks, and deletes notifications', async () => {
    const list = await request(app)
      .get('/notifications')
      .set('Authorization', `Bearer ${token}`);
    assert.equal(list.status, 200);
    assert.ok(list.body.unreadCount >= 1);
    const id = list.body.notifications[0].id;

    // Mark single notification read
    const read = await request(app)
      .patch(`/notifications/${id}/read`)
      .set('Authorization', `Bearer ${token}`);
    assert.equal(read.status, 200);
    assert.equal(read.body.read, true);

    // Mark non-existent or client-generated string id (e.g. reg_p2) gracefully without 500
    const invalidIdRes = await request(app)
      .patch('/notifications/reg_p2/read')
      .set('Authorization', `Bearer ${token}`);
    assert.equal(invalidIdRes.status, 404);

    // Mark all read
    const all = await request(app)
      .patch('/notifications/read-all')
      .set('Authorization', `Bearer ${token}`);
    assert.equal(all.status, 200);
    assert.equal(all.body.unreadCount, 0);

    // Delete single notification
    const del = await request(app)
      .delete(`/notifications/${id}`)
      .set('Authorization', `Bearer ${token}`);
    assert.equal(del.status, 200);
  });

  it('toggles module completion, updates progress, and transitions status', async () => {
    // p1 has 3 modules in learningPath
    // 1. Mark module 0 complete
    const m0 = await request(app)
      .patch('/registrations/p1/modules/0/toggle')
      .set('Authorization', `Bearer ${token}`);
    assert.equal(m0.status, 200);
    assert.deepEqual(m0.body.registration.completedModules, [0]);
    assert.equal(m0.body.registration.progress, 33);
    assert.equal(m0.body.registration.status, 'ongoing');

    // 2. Mark module 1 complete
    const m1 = await request(app)
      .patch('/registrations/p1/modules/1/toggle')
      .set('Authorization', `Bearer ${token}`);
    assert.equal(m1.status, 200);
    assert.equal(m1.body.registration.progress, 67);
    assert.equal(m1.body.registration.status, 'ongoing');

    // 3. Mark module 2 complete -> 100% completed
    const m2 = await request(app)
      .patch('/registrations/p1/modules/2/toggle')
      .set('Authorization', `Bearer ${token}`);
    assert.equal(m2.status, 200);
    assert.equal(m2.body.registration.progress, 100);
    assert.equal(m2.body.registration.status, 'completed');
    assert.ok(m2.body.registration.completedAt);

    // Verify registration query reflects status
    const regRes = await request(app)
      .get('/registrations/p1')
      .set('Authorization', `Bearer ${token}`);
    assert.equal(regRes.status, 200);
    assert.equal(regRes.body.status, 'completed');
    assert.equal(regRes.body.progress, 100);

    // 4. Untoggle module 1 -> reverts to ongoing
    const unM1 = await request(app)
      .patch('/registrations/p1/modules/1/toggle')
      .set('Authorization', `Bearer ${token}`);
    assert.equal(unM1.status, 200);
    assert.equal(unM1.body.registration.progress, 67);
    assert.equal(unM1.body.registration.status, 'ongoing');
  });
});
