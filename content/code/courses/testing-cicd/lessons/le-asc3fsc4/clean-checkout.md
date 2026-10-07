---
title: Starting from what was committed
version: 2
---

"It works on my machine" is usually true. The machine has files the repository does not, packages
installed months ago, an environment variable set in a shell profile. A CI run's first job is to
**forget all of that**: it starts from a checkout of the commit and nothing else, so it tests what
everybody else will get when they pull.

Here is that difference catching a real mistake. Ana adds a test that reads a new data file,
`tests/data/carriers.csv`, commits the test, and forgets to add the CSV. Make the same mistake on
purpose. The data file is two carriers:

```sh
printf 'name,base_cents\nCorreios,1290\nJadlog,1450\n' > tests/data/carriers.csv
```

The test reads it. Save it as `tests/test_carriers.py`:

```python
import csv
from pathlib import Path

CARRIERS = Path(__file__).parent / "data" / "carriers.csv"


def test_every_carrier_has_a_positive_base_price():
    for row in csv.DictReader(open(CARRIERS)):
        assert int(row["base_cents"]) > 0, row["name"]
```

and only the test is committed:

```sh
git add tests/test_carriers.py
git commit -m "Check every carrier has a positive base price"
```

Then the test, the status and the push:

```
ana@laptop:~/shipquote$ python -m pytest -q tests/test_carriers.py
.                                                                        [100%]
1 passed in 0.62s
ana@laptop:~/shipquote$ git status --short
?? tests/data/carriers.csv
ana@laptop:~/shipquote$ git push
remote: ci: run 2, commit f3b2545, checked out clean        
remote: ci: 3.11  America/Sao_Paulo  FAIL  1 failed, 41 passed, 2 skipped in 2.00s        
remote: ci: 3.11  UTC                FAIL  1 failed, 41 passed, 2 skipped in 1.39s        
remote: ci: 3.12  America/Sao_Paulo  FAIL  1 failed, 41 passed, 2 skipped in 1.95s        
remote: ci: 3.12  UTC                FAIL  1 failed, 41 passed, 2 skipped in 1.43s        
remote: ci: 3.13  America/Sao_Paulo  FAIL  1 failed, 41 passed, 2 skipped in 1.98s        
remote: ci: 3.13  UTC                FAIL  1 failed, 41 passed, 2 skipped in 1.42s        
remote: ci: run 2 FAILED, logs in /home/ana/ci/runs/2        
To /home/ana/ci/shipquote.git
   b3062cb..f3b2545  main -> main
```

On the laptop the test passes: the CSV is there. `git status --short` gives it away with `??`, the
mark for a file git is not tracking, but nothing forces anybody to read it. (If you ran lesson 3's
property tests, a second `??` line names `.hypothesis/`, the examples Hypothesis remembers. It is
not part of the project either.) The CI run started from
commit `f3b2545`, which has the test and not the file, and **every cell failed with one failure**:
the test could not open a file that was never committed.

## Why this is the most valuable thing CI does

Nobody would make this mistake on purpose, and nobody notices it locally, because locally it is not
a mistake. It only exists for the next person who clones the repository: a colleague, a new laptop,
the production build. The clean checkout makes that next person arrive immediately, as a machine,
instead of next week, as a confused message.

Files that are on one machine and not in the repository are the commonest case, but not the only
one. The same discipline catches:

- **a dependency installed by hand** and never added to `requirements-dev.txt`;
- **an environment variable** set in someone's shell profile that the code silently relies on;
- **generated files** committed by accident, which mask a broken generator.

The CI can only catch these if it **really starts clean**. A runner that reuses a working directory
between runs, to save time, can carry a file from a previous build into the next one and pass for
the same reason the laptop did. Hosted runners start every job on a fresh virtual machine; a
self-hosted runner needs its workspace wiped, and lesson 6 shows where that is configured.

The fix for Ana's commit was a second commit removing the test until the CSV could be reviewed,
pushed as run 3. The lesson moves on from there:

```sh
rm tests/data/carriers.csv
git rm -q tests/test_carriers.py
git commit -m "Remove the carrier test until its data is committed"
git push
```
