#!/usr/bin/env node
/**
 * `npx vibiz` — installs the Vibiz Claude Code plugin in one shot.
 *
 * What this does:
 *   1. Checks `claude` CLI is on PATH (Claude Code installed)
 *   2. Adds the marketplace: `claude plugin marketplace add Vibiz-ai/vibiz-claude-plugin`
 *   3. Installs the plugin: `claude plugin install vibiz@vibiz`
 *   4. Tells the user to authenticate via `/mcp` (we can't automate the
 *      OAuth browser handoff)
 *
 * Falls back gracefully — if any step fails, prints the manual slash
 * commands so the user can finish the install from inside Claude Code.
 */

'use strict';

const { spawnSync } = require('node:child_process');

const REPO = 'Vibiz-ai/vibiz-claude-plugin';
const PLUGIN = 'vibiz@vibiz';
const MARKETPLACE = 'vibiz';

const log = (m) => process.stdout.write(m + '\n');
const err = (m) => process.stderr.write(m + '\n');

function checkClaudeCli() {
  const r = spawnSync('claude', ['--version'], { stdio: 'pipe' });
  return r.status === 0;
}

function tryRun(args, label) {
  log(`\n→ ${label}`);
  const r = spawnSync('claude', args, { stdio: 'inherit' });
  return r.status === 0;
}

function manualFallback(reason) {
  err(`\n✗ ${reason}`);
  err('  Open Claude Code and run these slash commands manually:');
  err('');
  err(`    /plugin marketplace add ${REPO}`);
  err(`    /plugin install ${PLUGIN}`);
  err('    /mcp');
  err('');
  err('  Then pick "vibiz" → Authenticate.');
  process.exit(1);
}

function main() {
  log('🎨  Installing Vibiz for Claude Code…');

  if (!checkClaudeCli()) {
    err('\n✗ Claude Code is not installed (or not on $PATH).');
    err('  Install it first:');
    err('    brew install claude-code');
    err('  …or:');
    err('    npm i -g @anthropic-ai/claude-code');
    err('  Then re-run:  npx vibiz');
    process.exit(1);
  }

  if (!tryRun(['plugin', 'marketplace', 'add', REPO], `Adding marketplace ${REPO}`)) {
    manualFallback('Could not add the marketplace via the CLI.');
  }

  if (!tryRun(['plugin', 'install', PLUGIN], `Installing plugin ${PLUGIN}`)) {
    manualFallback('Could not install the plugin via the CLI.');
  }

  log('\n✓ Vibiz installed.');
  log('');
  log('Next — authenticate (one-time, opens your browser):');
  log('');
  log('   claude');
  log('   /mcp');
  log(`   pick "${MARKETPLACE}" → Authenticate`);
  log('');
  log('Then try:  /vibiz:status');
  log('Docs:      https://github.com/' + REPO);
}

main();
