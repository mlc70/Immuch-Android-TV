#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');

const bodyPath = process.argv[2];
if (!bodyPath) {
  console.error('Usage: node tools/check-pr-template.cjs <body-file> [additional-template-file ...]');
  process.exit(2);
}

const body = fs.readFileSync(bodyPath, 'utf8');
const templates = [path.join(__dirname, '../.github/pull_request_template.md'), ...process.argv.slice(3)];
const headings = [...new Set(templates.flatMap((file) =>
  fs.readFileSync(file, 'utf8').replace(/<!--[\s\S]*?-->/g, '').split(/\r?\n/)
    .filter((line) => line.startsWith('## '))
))];
const bodyLines = new Set(body.split(/\r?\n/));
const missing = headings.filter((heading) => !bodyLines.has(heading));
if (missing.length) {
  console.error(`PR description is missing required template headings:\n${missing.join('\n')}`);
  process.exit(1);
}
console.log(`PR template check passed (${headings.length} required headings).`);
