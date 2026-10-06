---
title: Coverage of the lines a change touched
version: 1
---

A total moves slowly. On a large project, a change that adds forty untested lines barely shifts the
percentage, and a reviewer reading "coverage 81% → 80%" learns nothing about the change in front of
them. The useful question for a pull request is narrower: **did the tests run the lines this change
added?**

Here a surcharge for heavy parcels is added to `freight`, two lines, and no test:

```python
    if weight_g > 30_000:           # heavy parcels go by road freight
        return BASE[zone] * 3 + extra * EXTRA_PER_500G
```

```
ana@laptop:~/shipquote$ git diff --stat
 shipquote/quote.py | 2 ++
 1 file changed, 2 insertions(+)
ana@laptop:~/shipquote$ coverage run -m pytest -q | tail -1; coverage report | tail -1
41 passed, 2 skipped in 1.67s
TOTAL                     166     33     26      5    80%
ana@laptop:~/shipquote$ coverage report -m --include=shipquote/quote.py
Name                 Stmts   Miss Branch BrPart  Cover   Missing
----------------------------------------------------------------
shipquote/quote.py      21      1      8      1    93%   30
----------------------------------------------------------------
TOTAL                   21      1      8      1    93%
```

The total went from **81% to 80%**. In the file, the report names line 30, the new `return`, as
never run. The `if` above it ran, because every quote passes through it, so a line-only report would
have claimed half of the change was tested. **Of the new behaviour, nothing was tested**: no test
sends a parcel over 30 kg, and the price for one could be anything.

## Making it a check

That comparison, the lines a diff added against the lines coverage saw run, is what tools called
*diff coverage* or *patch coverage* compute. `diff-cover` reads a coverage report and a `git diff`
and prints the uncovered changed lines; hosted services such as Codecov and Coveralls show the same
thing as a comment on the pull request. A team that wants a coverage gate is usually better served
by one on the change than on the total:

- it asks something of **the person who made the change**, about their change, which they can
  answer;
- it does not punish a change for old untested code it did not touch;
- it cannot be met by adding a test elsewhere, as the total can.

It has the same weakness as every coverage gate: lines that ran are not lines that were checked. In
review, the question after "is the new code covered?" is still "what does the test assert?".

## Reading a report in review

Whatever the tooling, the habit is the same. For each changed file, look at the **Missing** column
next to the diff. A missing line in a branch the change added is either a test to write, or a
decision, written down, that the path is not worth one. The surcharge above is a price, so it is the
first.
