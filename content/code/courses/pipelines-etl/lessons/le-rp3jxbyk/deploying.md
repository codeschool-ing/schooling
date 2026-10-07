---
title: Merge, tag, deploy
version: 1
---

Before the change leaves her branch, the suite from lesson 17 runs on it — the unit tests, and the
integration test against its own warehouse:

```
ana@vm:~/etl$ python -m pytest -q tests
..........                                                               [100%]
10 passed in 9.85s
```

Then the change is committed with a message that says why, merged into `main`, and given a version:

```
ana@vm:~/etl$ git add shop && git commit -q -m "stg_books: categories start with a capital, whatever the publisher sends" && git switch -q main && git merge -q --ff-only initcap-categories && git log --oneline
b0fa055 stg_books: categories start with a capital, whatever the publisher sends
cdef2c0 The nightly as it runs today
ana@vm:~/etl$ git tag -a v1.1.0 -m "Categories start with a capital" && git tag -n
v1.0.0          The nightly as it runs today
v1.1.0          Categories start with a capital
```

`v1.1.0` and not `v2.0.0`, and the number is a message. A common convention, **semantic
versioning**, reads a version as *major.minor.patch*. The patch is for a fix that changes no output, the
minor for a change that adds or changes behaviour without breaking anybody who reads the result, and
the major for one that does break them: a renamed column, a removed table, a different grain. With
the first attempt, renaming five categories that reports filter on, this would have been a major
version. That makes a good test of whether a change was meant: *would I be happy to call it 2.0?*

Deploying is moving production to the new tag and building it:

```
ana@vm:~/etl-prod$ git checkout -q v1.1.0 && git describe --tags
v1.1.0
ana@vm:~/etl-prod$ dbt build --project-dir shop --target prod 2>&1 | grep -E "stg_books|daily_sales |Done"
07:37:31  1 of 16 START sql view model dbt_staging.stg_books ............................. [RUN]
07:37:31  1 of 16 OK created sql view model dbt_staging.stg_books ........................ [CREATE VIEW in 0.27s]
07:37:32  13 of 16 START sql table model dbt_marts.daily_sales ........................... [RUN]
07:37:32  13 of 16 OK created sql table model dbt_marts.daily_sales ...................... [INSERT 0 7298 in 0.22s]
07:37:32  Done. PASS=14 WARN=1 ERROR=0 SKIP=0 NO-OP=1 REUSED=0 TOTAL=16
```

`git describe --tags` says which version production is on, which is the first thing to ask when a
number looks wrong in the morning. The build ran the whole project with the `prod` target, and the
two models the change touched are among the sixteen nodes. The one warning is lesson 12's erased
customers, still known and still lawful.

In a team, the same steps are taken by a machine. The tests and the comparison run when a change is
proposed; the merge waits for them; the tag and the build follow it. That machinery — continuous
integration and deployment — is not set up in the lab, and every step it would run is a command
this section has already shown.
