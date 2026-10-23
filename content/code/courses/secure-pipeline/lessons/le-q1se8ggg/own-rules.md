---
title: Rules written for this project
version: 1
---

Bandit's checks were written for every Python program, so they know nothing about this one. They
cannot know that linkbox has one administration token, that every route that writes must check it,
or that the team decided how. **The rules that catch a project's own mistakes have to be written by
the project**, and they are often the most valuable ones it has, because they encode a decision
nobody else could have made for it.

Semgrep is a tool for exactly that. A rule is a piece of code with holes in it: `$DB.execute(...)`
matches any call to `execute` on anything, and the hole `$DB` takes whatever is there. Rules are
YAML, they live in the repository beside the code, and they are reviewed like it.

### Install it

Semgrep brings dozens of packages with it, so `tail` keeps only the last three lines of the install:

```
ana@vm:~/linkbox$ uv tool install semgrep==1.182.1 2>&1 | tail -n 3
 + wrapt==1.17.3
 + zipp==4.1.2
Installed 2 executables: pysemgrep, semgrep
ana@vm:~/linkbox$ semgrep --version
1.182.1
```

Semgrep's command-line tool and its pattern engine are open source. The company behind it also
runs a registry of rules and a paid platform; this course uses neither, and every rule it runs is
written below.

### Two rules

Save them as `.semgrep.yml`:

```yaml
rules:
  - id: sql-built-from-a-string
    languages: [python]
    severity: ERROR
    message: >-
      SQL text built from a string reaches execute(). Write a ? where the
      value goes and pass the value as a parameter.
    pattern-either:
      - pattern: $DB.execute(f"...", ...)
      - pattern: $DB.execute("..." + $X, ...)
      - pattern: $DB.execute("...".format(...), ...)
      - pattern: $DB.execute("..." % $X, ...)
  - id: writes-need-the-token
    languages: [python]
    severity: ERROR
    message: >-
      A POST route that never calls require_token() lets anybody write.
    patterns:
      - pattern: |
          @app.post(...)
          def $ROUTE(...):
              ...
      - pattern-not: |
          @app.post(...)
          def $ROUTE(...):
              ...
              require_token()
              ...
```

**The first rule is Bandit's B608, said in the project's own words.** It matches a call to
`execute` whose first argument is a string built in any of Python's four ways: an f-string,
`+`, `.format()` or `%`. A call with a plain string and a tuple of parameters, like `follow()`'s,
matches none of them. Its message says what to write instead, which a generic tool cannot do as
precisely, because it does not know this project's database is SQLite with `?` placeholders.

**The second rule is a decision written down.** It matches every function decorated with
`@app.post`, then removes from the matches every one whose body calls `require_token()` somewhere.
What is left is a route that writes and never calls the function that checks the token. The
function does not exist yet; the rule is written first, the way a test is.

### What it finds

```
ana@vm:~/linkbox$ semgrep scan --metrics=off --quiet --emacs --config .semgrep.yml .
app.py:32:1:error(writes-need-the-token):@app.post("/links"):A POST route that never calls require_token() lets anybody write.
app.py:46:12:error(sql-built-from-a-string):    rows = db().execute(f"SELECT code, url FROM links WHERE url LIKE '%{q}%'").fetchall():SQL text built from a string reaches execute(). Write a ? where the value goes and pass the value as a parameter.
```

Two findings, one per rule, each on one line: file, line, column, the rule and its message.
`--emacs` asks for that format, which a log can hold and `grep` can search. Read the first one
carefully, because it is the more interesting: `create()`, at line 32, **does check the token.** Its first two lines compare the header with `ADMIN_TOKEN` and
answer 401 when they differ, and lesson 1's test proves it. So is this a false positive?

It is a true positive **of the rule**, which said something narrower than "this route is open".
It said this route does not call `require_token()`, and that is exactly true. The question the
finding raises is whether the rule is right to want the call, and there are two reasons it is.

- **An inline check is copied, and a copy can be wrong.** The next route that writes will be
  written by copying `create()`. The copy that forgets the two lines, or gets the header's name
  wrong, passes every test that was not written for it. One function called from every route that
  writes has one place to be right, and the rule makes forgetting it visible.
- **`!=` is the wrong comparison for a secret.** A string comparison stops at the first character
  that differs, so it takes slightly longer the more of the start of a guess is right. Over enough
  attempts and a network quiet enough, that difference is measurable, and it leaks the token a
  character at a time. `secrets.compare_digest()` takes the same time whatever the input, which
  is why Python's documentation recommends it for exactly this.

Neither of those is something Bandit could have known. **That is the gap a project's own rules
fill**: Bandit found the injection from its shape, and only a rule that knows linkbox's design
could find a route that skips the project's own check.

### When a rule is wrong about one line

Semgrep's suppression is a comment on the line it matches, naming the rule. The table-name query of
the previous section would carry it like this, with the reason above:

```python
# A table name cannot be a ? parameter, and t only ever comes from TABLES.
count = db().execute(f"SELECT count(*) FROM {t}").fetchone()[0]  # nosemgrep: sql-built-from-a-string
```

The rules from the previous section apply word for word: the rule's id, never a bare `nosemgrep`,
and the reason beside it. **A rule a team wrote and then suppresses often is a rule to rewrite**:
either its pattern is too wide, or the decision it encodes has changed and nobody updated it.
