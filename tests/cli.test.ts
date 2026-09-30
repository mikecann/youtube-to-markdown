import { expect, test } from 'bun:test';
import { chmodSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const root = resolve(import.meta.dir, '..');
const url = 'https://youtu.be/dQw4w9WgXcQ';
const markdown = `[![Test title](https://example.com/thumb.jpg)](${url})`;

// Clipboard commands are replaced on POSIX. Windows runs validation-only tests;
// real clipboard and cmd.exe forwarding still need a Windows interaction check.
function withCli(check: (run: (args: string[], mode?: string) => ReturnType<typeof spawnSync>, dir: string) => void) {
  const dir = mkdtempSync(join(tmpdir(), 'youtube-markdown-cli-'));
  try {
    for (const name of ['pbcopy', 'clip', 'xclip']) {
      const path = join(dir, name);
      writeFileSync(path, '#!/bin/sh\ncat > "$TEST_CLIPBOARD"\n');
      chmodSync(path, 0o755);
    }
    const run = (args: string[], mode = '') => spawnSync(process.execPath, [
      '--preload', join(root, 'tests/fixtures/api.ts'), join(root, 'index.ts'), ...args,
    ], {
      cwd: dir, encoding: 'utf8',
      env: { ...process.env, PATH: `${dir}:${process.env.PATH}`, TEST_CLIPBOARD: join(dir, 'clipboard.txt'), TEST_API_MODE: mode },
    });
    check(run, dir);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test('invalid input exits with a useful error and renamed banner', () => withCli((run) => {
  const result = run(['missing file.url']);
  expect(result.status).toBe(1);
  expect(result.stdout).toContain('YOUTUBE TO MARKDOWN');
  expect(result.stderr).toContain('Not a valid URL or .url file');
}));

test('non-YouTube URL is rejected before fetching', () => withCli((run) => {
  const result = run(['https://example.com']);
  expect(result.status).toBe(1);
  expect(result.stderr).toContain('Not a YouTube URL');
}));

test.skipIf(process.platform !== 'darwin')('direct URL copies the API markdown to the mocked clipboard', () => withCli((run, dir) => {
  const result = run([url]);
  expect(result.status).toBe(0);
  expect(result.stdout).toContain('Copied to clipboard!');
  expect(result.stdout).toContain('Test title');
  expect(readFileSync(join(dir, 'clipboard.txt'), 'utf8')).toBe(markdown);
}));

test.skipIf(process.platform !== 'darwin')('Internet Shortcut with spaces and CRLF is converted', () => withCli((run, dir) => {
  const file = join(dir, 'My Video.url');
  writeFileSync(file, `[InternetShortcut]\r\nURL=${url}\r\n`);
  expect(run([file]).status).toBe(0);
  expect(readFileSync(join(dir, 'clipboard.txt'), 'utf8')).toBe(markdown);
}));

test('API failure is reported', () => withCli((run) => {
  const result = run([url], 'error');
  expect(result.status).toBe(1);
  expect(result.stderr).toContain('Test API failure');
}));

test('empty markdown response is reported', () => withCli((run) => {
  const result = run([url], 'empty');
  expect(result.status).toBe(1);
  expect(result.stderr).toContain('API returned an empty markdown field');
}));
