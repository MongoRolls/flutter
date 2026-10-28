import express from 'express';
import request from 'supertest';
import { gzipSync } from 'node:zlib';
import { describe, expect, it } from 'vitest';

// Exercise the installed Express dependency chain without loading DB or secrets.
describe('HTTP dependency security regressions', () => {
  it('does not trust an IPv4 client through a short mapped IPv6 subnet', async () => {
    const app = express();
    app.set('trust proxy', '::ffff:10.0.0.0/8');
    app.get('/', (req, res) => res.json({ ip: req.ip }));
    const response = await request(app).get('/').set('X-Forwarded-For', '203.0.113.7').expect(200);
    expect(response.body.ip).not.toBe('203.0.113.7');
  });

  it('preserves legitimate loopback proxy configuration', async () => {
    const app = express();
    app.set('trust proxy', 'loopback');
    app.get('/', (req, res) => res.json({ ip: req.ip }));
    const response = await request(app).get('/').set('X-Forwarded-For', '203.0.113.7').expect(200);
    expect(response.body.ip).toBe('203.0.113.7');
  });

  it('enforces JSON limits and continues serving after rejection', async () => {
    const app = express();
    app.use(express.json({ limit: 64 }));
    app.post('/', (req, res) => res.json(req.body));
    await request(app).post('/').send({ value: 'x'.repeat(128) }).expect(413);
    await request(app).post('/').send({ value: 'ok' }).expect(200, { value: 'ok' });
  });

  it('rejects an invalid size limit at parser construction', () => {
    expect(() => express.json({ limit: 'invalid-limit' })).toThrow();
  });

  it('survives a gzip body with trailing bytes', async () => {
    const app = express();
    app.use(express.json());
    app.post('/', (req, res) => res.json(req.body));
    const payload = Buffer.concat([gzipSync('{"value":"ok"}'), Buffer.from('trailing-invalid-frame')]);
    const response = await request(app).post('/').set('Content-Type', 'application/json')
      .set('Content-Encoding', 'gzip').send(payload).timeout(2000);
    expect([200, 400]).toContain(response.status);
    await request(app).post('/').send({ value: 'still-alive' }).expect(200);
  });
});
