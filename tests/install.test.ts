import { expect, test } from 'bun:test';
import { mkdtempSync, readFileSync, realpathSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

// Install into a disposable directory rather than changing the user's PATH.
test.skipIf(process.platform === 'win32')('installer is repeatable and its symlink forwards arguments from another cwd', () => {
  const dir = mkdtempSync(join(tmpdir(), 'youtube-markdown-install-'));
  const bin = join(dir, 'bin with spaces');
  const root = resolve(import.meta.dir, '..');
  try {
    for (let i = 0; i < 2; i++) {
      const result = spawnSync('bash', [join(root, 'install.sh'), bin, '--skip-deps'], { cwd: dir, encoding: 'utf8' });
      expect(result.status).toBe(0);
    }
    const launcher = join(bin, 'youtube-to-markdown');
    expect(realpathSync(launcher)).toBe(join(root, 'youtube-to-markdown'));
    const result = spawnSync(launcher, ['not a url'], { cwd: dir, encoding: 'utf8' });
    expect(result.status).toBe(1);
    expect(result.stdout).toContain('YOUTUBE TO MARKDOWN');
    expect(result.stderr).toContain('Not a valid URL or .url file: not a url');
    expect(readFileSync(join(root, 'package.json'), 'utf8')).toContain('"name": "youtube-to-markdown"');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
