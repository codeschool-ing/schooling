---
title: Breaking the code to test the tests
version: 2
---

Lesson 1 broke `brl` on purpose to see a test fail, and lesson 3 did the same to `split`. **Mutation
testing** makes that a method. A *mutant* is a copy of the code with one small deliberate change,
such as `>=` to `>`. Run the suite against it. If some test fails, the mutant is **killed**: the
suite noticed. If every test passes, the mutant **survived**, and the suite cannot tell the broken
code from the real one.

Tools such as `mutmut` and `cosmic-ray` for Python, PIT for Java and Stryker for JavaScript generate
thousands of mutants automatically. The idea fits in a short script, and seeing it whole is the
best way to understand what those tools report. This one was written for the lesson, and it runs
from the project's directory. Save it as `mutate.py`:

```python
"""Mutation testing by hand: change one thing, run the suite, see who notices.

Each mutation is a (file, old, new) replacement. The file is restored after
every run, whatever happened.
"""
import subprocess
import sys
from pathlib import Path

MUTATIONS = [
    ("shipquote/quote.py", "subtotal_cents >= FREE_FROM", "subtotal_cents > FREE_FROM"),
    ("shipquote/quote.py", "if weight_g <= 0:", "if weight_g < 0:"),
    ("shipquote/quote.py", "(weight_g - 1) // 500", "weight_g // 500"),
    ("shipquote/quote.py", "len(digits) != 8 or", "len(digits) != 8 and"),
    ("shipquote/quote.py", '"6": "N"', '"6": "NE"'),
    ("shipquote/store.py", "ORDER BY created_at DESC, id DESC", "ORDER BY created_at DESC"),
    ("shipquote/store.py", "CHECK (cents >= 0)", "CHECK (cents >= -1000)"),
    ("shipquote/store.py", "CHECK (length(cep) = 8)", "CHECK (length(cep) >= 7)"),
]

killed = 0
for path, old, new in MUTATIONS:
    f = Path(path)
    original = f.read_text()
    assert old in original, (path, old)
    f.write_text(original.replace(old, new, 1))
    try:
        run = subprocess.run([sys.executable, "-m", "pytest", "-q", "-x", "-p", "no:cacheprovider"],
                             capture_output=True, text=True)
    finally:
        f.write_text(original)
    verdict = "killed" if run.returncode == 1 else "SURVIVED"
    killed += verdict == "killed"
    print(f"{verdict:9} {path:20} {old}  ->  {new}")
print(f"{killed} of {len(MUTATIONS)} mutants killed")
```

Eight mutants, each a plausible slip: a boundary moved, a band miscounted, a CEP check weakened, a
tie-break dropped, a constraint loosened. Each one is applied, the whole suite runs with `-x` to
stop at the first failure, and the file is restored.

```
ana@laptop:~/shipquote$ python mutate.py
killed    shipquote/quote.py   subtotal_cents >= FREE_FROM  ->  subtotal_cents > FREE_FROM
killed    shipquote/quote.py   if weight_g <= 0:  ->  if weight_g < 0:
killed    shipquote/quote.py   (weight_g - 1) // 500  ->  weight_g // 500
killed    shipquote/quote.py   len(digits) != 8 or  ->  len(digits) != 8 and
killed    shipquote/quote.py   "6": "N"  ->  "6": "NE"
SURVIVED  shipquote/store.py   ORDER BY created_at DESC, id DESC  ->  ORDER BY created_at DESC
SURVIVED  shipquote/store.py   CHECK (cents >= 0)  ->  CHECK (cents >= -1000)
killed    shipquote/store.py   CHECK (length(cep) = 8)  ->  CHECK (length(cep) >= 7)
6 of 8 mutants killed
```

The five mutants in `quote.py` were all killed: lesson 1's edges and lesson 3's table did their job.
**Two of the three in `store.py` survived, in a file the coverage report shows at 100%.**

- Dropping `id DESC` from the ordering survived because no test saves two quotes with the same
  `created_at`. The factory of lesson 3 makes sure of that, so the tie-break, which decides the
  order of two quotes made in the same second, is never exercised.
- Loosening `CHECK (cents >= 0)` survived because no test tries to store a negative price. The CEP
  constraint, which the third store test does exercise, was killed.

Each survivor names a test worth writing. Neither is a coverage problem: the lines ran. They are
assertion problems, invisible to every percentage in section 02.

## The cost, and how teams use it

Every mutant is a full run of the suite, so mutation testing is slow: eight mutants here took eight
runs, and a real tool on a real project generates thousands. Teams that use it run it **on the
files a change touched**, or nightly, rather than on every push, and they read the survivors rather
than chasing a score. A surviving mutant in a log message's wording is not worth a test; one in a
price is.

**A mutation score measures the tests; a coverage score measures the code that ran.** Of the two,
only the first says anything about whether the tests would catch a bug.
