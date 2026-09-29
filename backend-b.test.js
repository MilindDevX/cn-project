const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createServer } = require('./backend-b');

async function withServer(run) {
  const server = createServer();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    await run(`http://127.0.0.1:${server.address().port}`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test('Backend B serves its identity on root and status', async () => {
  await withServer(async (base) => {
    const root = await fetch(base);
    assert.equal(root.status, 200);
    assert.equal(root.headers.get('x-backend'), 'B');
    assert.equal(await root.text(), 'Hello from Backend B');

    const status = await fetch(`${base}/api/status`);
    assert.equal(status.status, 200);
    assert.equal(status.headers.get('x-backend'), 'B');
    assert.deepEqual(await status.json(), { status: 'ok', backend: 'B' });
  });
});

test('Backend B cache supports ETag revalidation', async () => {
  await withServer(async (base) => {
    const fresh = await fetch(`${base}/api/cache`);
    assert.equal(fresh.status, 200);
    assert.equal(fresh.headers.get('cache-control'), 'max-age=60');
    const etag = fresh.headers.get('etag');
    assert.ok(etag);

    const conditional = await fetch(`${base}/api/cache`, {
      headers: { 'If-None-Match': etag },
    });
    assert.equal(conditional.status, 304);
    assert.equal(conditional.headers.get('x-backend'), 'B');
    assert.equal(await conditional.text(), '');
  });
});
