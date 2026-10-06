---
title: Files that belong to one test
version: 1
---

A test that writes a file needs somewhere to write it. The choices that go wrong are the obvious
ones: the current directory, where the file is left behind and the next run trips over it; a fixed
path like `/tmp/quotes.db`, which two runs at once share; or the real data directory, where a test
deletes something a person needed.

pytest's answer is `tmp_path`, a fixture that gives each test a new, empty directory. The store
tests use it through the store fixture, and their databases can be found after the run:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_store.py -q
...                                                                      [100%]
3 passed in 0.18s
ana@laptop:~/shipquote$ ls /tmp/pytest-of-ana/
pytest-1
pytest-2
pytest-3
pytest-current
ana@laptop:~/shipquote$ find /tmp/pytest-of-ana/pytest-current/ -name "*.db"
/tmp/pytest-of-ana/pytest-current/test_recent_lists_the_newest_f0/quotes.db
/tmp/pytest-of-ana/pytest-current/test_the_database_refuses_a_ce0/quotes.db
/tmp/pytest-of-ana/pytest-current/test_a_saved_quote_comes_back_0/quotes.db
```

Three things to read in that listing.

**Each test had its own directory**, named after the test, truncated, and numbered. Three tests,
three `quotes.db` files, and no way for one to see another's rows.

**The directory is under the user's name**, `/tmp/pytest-of-ana`, so two people on one machine do
not collide either.

**pytest keeps the last three runs** and deletes older ones: `pytest-0`, `pytest-1`, and
`pytest-current`, a link to the newest. That is deliberate. When a test fails, the files it wrote
are still there to inspect, and the disk does not fill up with every run ever made.

## Other things a test should not share

The same thinking applies to everything a test can touch outside its own memory:

| resource | the shared version | the per-test version |
|---|---|---|
| a file | a fixed path | `tmp_path` |
| a port | 8080 | port 0, chosen by the system (lesson 1) |
| an environment variable | `os.environ[...] = ...` left set | `monkeypatch.setenv`, undone after the test |
| the current directory | `os.chdir` left changed | `monkeypatch.chdir` |

`monkeypatch` is the fixture lesson 2 section 09 mentioned beside `mock.patch`, and this is
its everyday use: **changes that are undone automatically when the test ends**, pass or fail.

A test that leaves something behind is a test that works the first time and fails the second,
or works on its own and fails in a pipeline where the previous job left a file. Lesson 5 shows why a
pipeline starts from a clean checkout; a test should not need that to pass.
