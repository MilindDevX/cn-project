const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createServer } = require('./backend-a');

async function withServer(run) {
  const server = createServer();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    const { port } = server.address();
    await run(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test('root and status expose Backend A identity', async () => {
  await withServer(async (base) => {
    const root = await fetch(base);
    assert.equal(root.status, 200);
    assert.equal(root.headers.get('x-backend'), 'A');
    assert.equal(await root.text(), 'Hello from Backend A');

    const status = await fetch(`${base}/api/status`);
    assert.equal(status.status, 200);
    assert.equal(status.headers.get('x-backend'), 'A');
    assert.deepEqual(await status.json(), { status: 'ok', backend: 'A' });
  });
});

test('cache endpoint supports fresh response and conditional 304', async () => {
  await withServer(async (base) => {
    const fresh = await fetch(`${base}/api/cache`);
    assert.equal(fresh.status, 200);
    assert.equal(fresh.headers.get('cache-control'), 'max-age=60');
    assert.equal(fresh.headers.get('x-backend'), 'A');
    const etag = fresh.headers.get('etag');
    assert.ok(etag);

    const conditional = await fetch(`${base}/api/cache`, {
      headers: { 'If-None-Match': etag },
    });
    assert.equal(conditional.status, 304);
    assert.equal(conditional.headers.get('x-backend'), 'A');
    assert.equal(conditional.headers.get('cache-control'), 'max-age=60');
    assert.equal(await conditional.text(), '');
  });
});

test('unknown path returns 404 with backend identity', async () => {
  await withServer(async (base) => {
    const response = await fetch(`${base}/missing`);
    assert.equal(response.status, 404);
    assert.equal(response.headers.get('x-backend'), 'A');
  });
});
