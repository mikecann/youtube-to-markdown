// Bun preloads this only in child-process tests. No request reaches the public API.
globalThis.fetch = (async (_url: unknown, init: RequestInit) => {
  if (_url !== 'https://quirky-squirrel-220.convex.site/api/markdown' || init.method !== 'POST') {
    throw new Error('Unexpected API request');
  }
  const body = JSON.parse(init.body as string);
  if (body.url !== 'https://youtu.be/dQw4w9WgXcQ') throw new Error('Unexpected video URL');
  if (process.env.TEST_API_MODE === 'error') return new Response('{"error":"Test API failure"}', { status: 503 });
  if (process.env.TEST_API_MODE === 'empty') return Response.json({});
  return Response.json({ markdown: '[![Test title](https://example.com/thumb.jpg)](https://youtu.be/dQw4w9WgXcQ)', title: 'Test title' });
}) as typeof fetch;
