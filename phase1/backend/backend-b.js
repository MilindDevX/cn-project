const http = require('node:http');

function createServer() {
  return http.createServer((request, response) => {
    response.setHeader('X-Backend', 'B');

    if (request.method === 'GET' && request.url === '/') {
      response.setHeader('Content-Type', 'text/plain; charset=utf-8');
      response.end('Hello from Backend B');
      return;
    }

    if (request.method === 'GET' && request.url === '/api/status') {
      response.setHeader('Content-Type', 'application/json; charset=utf-8');
      response.end(JSON.stringify({ status: 'ok', backend: 'B' }));
      return;
    }

    if (request.method === 'GET' && request.url === '/api/cache') {
      const etag = '"backend-b-cache-v1"';
      response.setHeader('Cache-Control', 'max-age=60');
      response.setHeader('ETag', etag);
      if (request.headers['if-none-match'] === etag) {
        response.writeHead(304);
        response.end();
        return;
      }
      response.setHeader('Content-Type', 'text/plain; charset=utf-8');
      response.end('Cached response from Backend B');
      return;
    }

    response.writeHead(404);
    response.end('Not found');
  });
}

module.exports = { createServer };

if (require.main === module) {
  createServer().listen(3002, '0.0.0.0', () => {
    console.log('Backend B listening on 0.0.0.0:3002');
  });
}
