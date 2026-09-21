---
title: The lesson that ages fastest, and the part that does not
version: 1
---

**This is the only reading in the course with a date on it.** Saying so is the point: the
recommendation at the top of this lesson is right today and has been wrong twice in the last five
years.

```text
setup.py + requirements.txt    the arrangement everything started from
pipenv                         recommended by the official packaging guide
poetry                         what most new projects used next
pyproject.toml                 standardised; setup.py begins to disappear
pip-tools                      how locking was done with pip alone
[project]                      the metadata table becomes a specification
hatch, pdm                     more tools, reading the same table
uv                             an order of magnitude faster than any of them
poetry 2                       adopts [project]; the two converge
```

That is an ordering rather than a set of dates, and it is enough to make the point: every row was
the sensible recommendation while it lasted, and following any of them leaves you with a
repository somebody has to migrate.

## What actually changed, and what did not

**The file did not.** `[project]` has a name, a version, `requires-python` and `dependencies`,
and everything above is a different program reading the same four keys. A project that declares
itself in the standard table has survived every one of those changes without an edit.

**The lock file format changes with the tool.** `Pipfile.lock`, `poetry.lock`, `requirements.txt`
from `pip-compile`, `uv.lock` — four formats for one idea, and none of them reads another's. That
is the part that makes a migration a migration.

**The verbs did not.** Add a dependency, resolve, lock, sync, run. Every one of these tools has
those five, under different names, and knowing what they mean transfers unchanged.

## What to do about it

- **Learn the file, not the tool.** The `[project]` table is a specification and it will outlive
  whatever you install this week.
- **Do not migrate a working project because something faster exists.** The migration costs a day
  and a class of bug that only appears in deployment; the speed saves seconds.
- **Do reach for the current tool on a new project.** The cost of being on the old one is paid
  later, by whoever joins.
- **Be suspicious of a tutorial with no date on it.** Half the packaging advice on the internet
  is correct for a year that has passed, and none of it says which year.

## And the honest caveat

`uv` is the newest of them. It is very good and it is owned by one company, and the last three
answers to this question were also very good on the day somebody wrote them down. The file is the
bet worth making; the tool is a choice you may have to make again.
