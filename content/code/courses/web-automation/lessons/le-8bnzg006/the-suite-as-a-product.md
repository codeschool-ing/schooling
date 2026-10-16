---
title: The suite as a product
version: 1
---

DRAFT. Save it as `slowest.mjs`:

```javascript
import { readFileSync } from 'node:fs';

// Reads the report `--reporter=json` writes, and says where the time went.
const report = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const tests = [];

function walk(suite) {
  for (const spec of suite.specs ?? []) {
    for (const test of spec.tests) {
      const ms = test.results.reduce((sum, result) => sum + result.duration, 0);
      tests.push({ file: spec.file, title: `${spec.file}:${spec.line} › ${spec.title}`, ms, test });
    }
  }
  for (const child of suite.suites ?? []) walk(child);
}
report.suites.forEach(walk);

const seconds = (ms) => (ms / 1000).toFixed(1).padStart(5) + ' s';
const { expected, unexpected, flaky, skipped, duration } = report.stats;
console.log(`${tests.length} tests, ${seconds(duration).trim()} from start to end`);
console.log(`as declared ${expected}, not as declared ${unexpected}, flaky ${flaky}, skipped ${skipped}`);

const byFile = new Map();
for (const t of tests) byFile.set(t.file, (byFile.get(t.file) ?? 0) + t.ms);
console.log('the five slowest files:');
for (const [file, ms] of [...byFile].sort((a, b) => b[1] - a[1]).slice(0, 5)) {
  console.log(`  ${seconds(ms)}  ${file}`);
}

// A test declared with test.fail() passes on ANY failure, so print the one
// it had: it should still be the defect its comment names.
const declared = tests.filter((t) => t.test.expectedStatus === 'failed');
const spent = declared.reduce((sum, t) => sum + t.ms, 0);
console.log(`declared to fail: ${declared.length} tests, ${seconds(spent).trim()}`);
for (const t of declared) {
  const error = t.test.results.at(-1)?.error?.message ?? 'no error recorded';
  const first = error.replace(/\x1b\[[0-9;]*m/g, '').split('\n')[0];
  console.log(`  ${t.title}\n      ${first}`);
}

for (const t of tests.filter((t) => t.test.status === 'unexpected' || t.test.status === 'flaky')) {
  console.log(`${t.test.status}: ${t.title}`);
}
```

```
%%CAP suite-w1%%
```

```
%%CAP suite-5%%
```
