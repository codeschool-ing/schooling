---
title: The test runner Node brings
version: 1
---

**Node 22 has a test runner built in, `node:test`, and an assertion library, `node:assert`.** A
small server needs nothing else, and `npm test` already runs it: the script is
`node --test --test-reporter=spec`. Without a file name, `node --test` finds the files whose names end
in `.test.js` and runs each in a process of its own.

The first test file checks the promises `src/code.js` makes:

```schooling-example
{"language": "javascript", "file": "test/code.test.js", "parts": [
 {"code": "import { test } from \"node:test\";\nimport assert from \"node:assert/strict\";\nimport { makeCode, isCode, ALPHABET, LENGTH } from \"../src/code.js\";", "note": "`test` declares one test; `assert/strict` is the version of the library whose comparisons never coerce types."},
 {"code": "test(\"a code has the right length\", () => {\n  assert.equal(makeCode().length, LENGTH);\n});", "note": "The simplest promise: six characters."},
 {"code": "test(\"a code uses only the alphabet\", () => {\n  for (let i = 0; i < 1000; i++) {\n    for (const c of makeCode()) assert.ok(ALPHABET.includes(c), `${c} is not in the alphabet`);\n  }\n});", "note": "A random function is tested by asking it many times. A thousand codes is six thousand characters checked."},
 {"code": "test(\"isCode refuses what makeCode would never make\", () => {\n  assert.equal(isCode(\"abc\"), false);\n  assert.equal(isCode(\"abcde1\"), false);\n  assert.equal(isCode(123456), false);\n  assert.equal(isCode(makeCode()), true);\n});", "note": "**The useful test is the one about what is refused.** A short string, a character outside the alphabet, something that is not a string."}
]}
```

```
ana@dev:~/server/links$ npm test

> links@0.1.0 test
> node --test --test-reporter=spec

✔ a code has the right length (0.882784ms)
✔ a code uses only the alphabet (5.449469ms)
✔ isCode refuses what makeCode would never make (0.161387ms)
ℹ tests 3
ℹ suites 0
ℹ pass 3
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 57.93399
```

`--test-reporter=spec` is what a terminal shows by default; it is written out in the script so that
`npm test` prints the same thing when its output goes to a file or a build log, where the default
would be a different format.

## A failing test

Somebody decides that `1` is a fine character after all and adds it to the alphabet. The `sed` line
below makes that change, and the test that was written for exactly this catches it:

```
ana@dev:~/server/links$ sed -i 's/ALPHABET = "23456789/ALPHABET = "123456789/' src/code.js
ana@dev:~/server/links$ npm test; echo "exit code $?"

> links@0.1.0 test
> node --test --test-reporter=spec

✔ a code has the right length (0.709916ms)
✔ a code uses only the alphabet (4.333075ms)
✖ isCode refuses what makeCode would never make (0.805499ms)
ℹ tests 3
ℹ suites 0
ℹ pass 2
ℹ fail 1
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 55.884691

✖ failing tests:

test at test/code.test.js:13:1
✖ isCode refuses what makeCode would never make (0.805499ms)
  AssertionError [ERR_ASSERTION]: Expected values to be strictly equal:
  
  true !== false
  
      at TestContext.<anonymous> (file:///home/ana/server/links/test/code.test.js:15:10)
      at Test.runInAsyncScope (node:async_hooks:214:14)
      at Test.run (node:internal/test_runner/test:1047:25)
      at Test.processPendingSubtests (node:internal/test_runner/test:744:18)
      at Test.postRun (node:internal/test_runner/test:1173:19)
      at Test.run (node:internal/test_runner/test:1101:12)
      at async Test.processPendingSubtests (node:internal/test_runner/test:744:7) {
    generatedMessage: true,
    code: 'ERR_ASSERTION',
    actual: true,
    expected: false,
    operator: 'strictEqual',
    diff: 'simple'
  }
exit code 1
ana@dev:~/server/links$ sed -i 's/ALPHABET = "123456789/ALPHABET = "23456789/' src/code.js
```

**A failure names the test, the assertion, what was expected and what came instead**, and the line in
the test file. The exit code is 1, which is what makes a build fail. `git checkout src/code.js` or the
reverse `sed` puts the alphabet back.

## Tests that do not finish

A test file that opens something and never closes it — a server still listening, a timer still
running — keeps its process alive, exactly as lesson 2's section on when a process is finished
described, and the run hangs. Lesson 6's tests start the Express application on a port the system
picks and close it in an `after` hook, which is the pattern for anything a test opens.
