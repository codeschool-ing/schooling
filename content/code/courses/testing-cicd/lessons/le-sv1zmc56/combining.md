---
title: Coverage from several runs
version: 1
---

In a pipeline, the suite rarely runs as one command. Lesson 1 section 14 split it into a fast layer
and a slow one, and lesson 5 will run it on three Python versions and two time zones. Each of those
runs sees part of the code, and **the coverage that matters is the union of all of them**.

`coverage run -p` writes a data file with a unique name instead of overwriting `.coverage`, and
`coverage combine` merges every such file into one. Here are the two layers of `shipquote`,
measured separately and then combined:

```
ana@laptop:~/shipquote$ coverage run -p -m pytest -q -m "not functional and not acceptance" | tail -1
37 passed, 2 skipped, 4 deselected in 0.65s
ana@laptop:~/shipquote$ coverage run -p -m pytest -q -m "functional or acceptance" | tail -1
4 passed, 39 deselected in 1.31s
ana@laptop:~/shipquote$ ls .coverage.* | wc -l
2
ana@laptop:~/shipquote$ coverage combine
Combined 2 files
ana@laptop:~/shipquote$ coverage report | tail -1
TOTAL                     164     32     24      4    81%
```

The fast layer ran 37 tests and the slow one 4. Two data files were written, `combine` merged them,
and the report shows **81%**, exactly the figure of the single run in section 02. Neither run alone
covers what the two do together: the functional tests are the only ones that reach `app.py`, and
the unit tests reach rules the HTTP tests never ask for.

## In a pipeline

The usual arrangement, which lesson 6 writes as a workflow, is:

1. every job that runs tests runs them under `coverage run -p` and keeps its data file as an
   **artifact**, a file the pipeline saves when the job ends;
2. one last job, after all the others, downloads the artifacts, runs `coverage combine` and
   `coverage report`, and publishes the result.

Two details make this work. The data files store absolute paths, so jobs that check the code out
into different directories need a `[paths]` section in the configuration that maps them to one
place. And the combined report should be produced **even when a test job failed**, because a
failing run is exactly when somebody will want to know what the other runs covered.

## Coverage as a reading, from here on

From lesson 5 on, the pipeline runs the tests, and it can produce this report on every push. What
lessons 1 to 4 add up to is how to read it: **uncovered lines are a list of places nobody checked;
covered lines are a list of places somebody might have.** A suite earns trust through its
assertions, its edges and its doubles kept honest, and coverage is the cheap way to find where none
of those has reached yet.
