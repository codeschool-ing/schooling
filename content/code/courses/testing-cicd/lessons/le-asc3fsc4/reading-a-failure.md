---
title: Reading a red run
version: 1
---

A red run is information, and most of the work after it is reading. The lab's hook keeps, for every
run, what each cell produced, the equivalent of what hosted services call **artifacts**: files a job
saves so they outlive the machine it ran on.

```
ana@laptop:~/shipquote$ ls ~/ci/runs/
1
2
3
4
ana@laptop:~/shipquote$ ls ~/ci/runs/4/
install-3.11.log
install-3.12.log
install-3.13.log
py3.11-America-Sao_Paulo.log
py3.11-America-Sao_Paulo.xml
py3.11-UTC.log
py3.11-UTC.xml
py3.12-America-Sao_Paulo.log
py3.12-America-Sao_Paulo.xml
py3.12-UTC.log
py3.12-UTC.xml
py3.13-America-Sao_Paulo.log
py3.13-America-Sao_Paulo.xml
py3.13-UTC.log
py3.13-UTC.xml
ana@laptop:~/shipquote$ grep -E "^(E |FAILED)" ~/ci/runs/4/py3.13-UTC.log
E       assert datetime.date(2026, 10, 6) == datetime.date(2026, 10, 5)
E        +  where datetime.date(2026, 10, 6) = dispatch_date(1791217800)
E        +  and   datetime.date(2026, 10, 5) = date(2026, 10, 5)
FAILED tests/test_dispatch.py::test_an_order_before_two_leaves_the_same_day
```

Run 4 is the red one. For each Python version there is an installation log, and for each cell the
test log and a JUnit XML file. JUnit XML is a format nearly every CI service can read: it is how a
hosted service shows a list of failed tests on a web page instead of a wall of text. The failing
UTC cell's log names the test and both dates: the code said 6 October where the test expected the
5th.

## Fix, then confirm

The change is reverted rather than patched, because reverting returns `main` to a commit that is
known to pass, and the colleague can bring the simplification back later with the zone and a test
that runs in UTC. The revert is pushed and the CI confirms it:

```
ana@laptop:~/shipquote$ git log --oneline -3
b33d78b Revert "Read the order time in local time, no zone table needed"
1247039 Read the order time in local time, no zone table needed
6b77129 Remove the carrier test until its data is committed
ana@laptop:~/shipquote$ time git push
remote: ci: run 5, commit b33d78b, checked out clean        
remote: ci: 3.11  America/Sao_Paulo  pass  41 passed, 2 skipped in 1.96s        
remote: ci: 3.11  UTC                pass  41 passed, 2 skipped in 1.39s        
remote: ci: 3.12  America/Sao_Paulo  pass  41 passed, 2 skipped in 1.97s        
remote: ci: 3.12  UTC                pass  41 passed, 2 skipped in 1.42s        
remote: ci: 3.13  America/Sao_Paulo  pass  41 passed, 2 skipped in 2.05s        
remote: ci: 3.13  UTC                pass  41 passed, 2 skipped in 1.43s        
remote: ci: run 5 passed        
To /home/ana/ci/shipquote.git
   1247039..b33d78b  main -> main

real	0m13.315s
user	0m6.250s
sys	0m1.046s
```

All six cells pass again. **Run 5 is the evidence that `main` is healthy**, and the commit hash in
its first line, `b33d78b`, ties that evidence to an exact version of the code. Lesson 11 returns to
reverting as a way of rolling back.

## Fail fast, or finish every cell?

When a cell fails, a CI service can cancel the cells still running, which saves runner time, or let
them finish, which saves information. GitHub Actions cancels by default, a setting called
`fail-fast`. In run 4 that default would have stopped at the first red cell, and nobody would have
seen that **every UTC cell failed and every São Paulo cell passed**, which is what pointed at the
time zone in one glance. The lab's hook never cancels.

A reasonable compromise: fail fast on pull requests, where the author only needs to know that
something is wrong, and **finish every cell on `main`** and on scheduled runs, where the pattern is
what someone will read. Either way, the run keeps every log as an artifact, because a failure
nobody can read is a failure somebody will re-run hoping it goes away.
