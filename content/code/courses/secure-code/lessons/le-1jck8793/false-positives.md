---
title: Noise, and how to answer it
version: 1
---

A static check knows patterns, not intentions, so some of what it reports is not a problem. **A
check that cries wolf on every run is a check people learn to ignore**, so the noise has to be
dealt with on purpose, one finding at a time, and never by switching the check off.

Run bandit over the whole folder, with a one-line format that is easier to read in a terminal:

```
(.venv) ana@vm:~/sc/checks$ bandit -q -r . -f custom --msg-template '{relpath}:{line}: {test_id} {msg}'
app.py:8: B105 Possible hardcoded password: 'vereda-dev'
app.py:12: B311 Standard pseudo-random generators are not suitable for security/cryptographic purposes.
app.py:16: B324 Use of weak MD5 hash for security. Consider usedforsecurity=False
app.py:20: B201 A Flask app appears to be run with debug=True, which exposes the Werkzeug debugger and allows the execution of arbitrary code.
test_app.py:7: B101 Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
test_app.py:8: B101 Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
test_app.py:12: B101 Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
```

Three new findings, all **B101** in `test_app.py`: `assert` is removed when Python runs with
optimisation switched on, so code that relies on `assert` for a security decision loses the check.
That is true, and it is about application code. In a pytest file, `assert` is how a test states
what it expects, and pytest never runs optimised. The right answer is to **leave the test files
out of the scan**, with `-x ./test_app.py`, rather than to stop using `assert` in tests.

### Three kinds of answer

| finding | right answer | why |
|---|---|---|
| a real flaw (B311 on the reset code) | fix the code | the finding is the point of the tool |
| a pattern used safely on purpose (B324 on a receipt id) | say so **in the code**, where the tool and the reader both see it | the intention is recorded beside the line it explains |
| a rule that does not apply to a whole kind of file (B101 in tests) | exclude those files, in the command everybody runs | one decision, made once, visible in the repository |

For the receipt id, Python's own `hashlib` has the way to say it: `hashlib.md5(…,
usedforsecurity=False)` declares that this digest protects nothing, and bandit's own message
suggested exactly that. Where a library offers no such argument, bandit accepts a comment on the
line, `# nosec B324`, and the comment should carry the reason: *`# nosec B324: receipt ids are
labels, not a security control`*. A bare `# nosec`, with no rule and no reason, silences every
future finding on that line too, which is how a real one gets past.

### Severity and confidence

Every finding carries both. **Severity** is how bad it would be if the finding is real; **confidence**
is how sure the tool is that it is. B201 above is high severity with medium confidence: the debugger
is dangerous, and the tool cannot tell whether that line ever runs outside a laptop. Neither number
is a verdict. They order the reading, highest of both first.
