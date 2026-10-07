---
title: Under version control
version: 1
---

The last piece is history. Code changes, maps grow, a rule is corrected, and six months later
somebody needs to know which version of the pipeline produced last quarter's report. **Version
control** keeps every version of every file, with who changed it, when and why. In this lab it is
git, and the first decision is what goes in:

```
ana@lab:~/clean$ git init -q && git config user.name 'Ana' && git config user.email ana@lab.example
ana@lab:~/clean$ cat .gitignore
raw/
ref/
out/
__pycache__/
*.png
ana@lab:~/clean$ git add . && git status --short
A  .gitignore
A  categorise.py
A  category_map.csv
A  checks.py
A  consent.py
A  derive.py
A  keyed.py
A  keys.py
A  lines.py
A  match.py
A  merge.py
A  orders.py
A  raw.sha256
A  raw_customers.py
A  ready.py
A  run.py
A  sources.csv
A  survivors.csv
A  typos.py
A  when.py
A  years.py
ana@lab:~/clean$ git commit -q -m 'Cleaning pipeline for the 2025 data, as of lesson 17' && git log --format='%an: %s'
Ana: Cleaning pipeline for the 2025 data, as of lesson 17
```

The `.gitignore` is a list of decisions, one per line:

- **`raw/` and `ref/` stay out.** The data is not code: it can be large, it may hold personal data
  that must not be copied into every clone of a repository, and its identity is already recorded,
  precisely, by `raw.sha256`, which does go in.
- **`out/` stays out.** Everything in it is rebuilt by `run.py`; committing it would create a second
  copy that can disagree with the code that made it.
- **`__pycache__/` and charts stay out.** They are by-products.

Everything else goes in, and the list of added files is the course in miniature: the reading
modules of lessons 7 and 10, the matching of lesson 5, the category map of lesson 8, the decisions of
lessons 9 and 10, the derived columns of lesson 12, the sources of lesson 14, the pipeline and its
checks. **The maps and the survivors list are code too**: `category_map.csv` was written by a person and
`survivors.csv` by a rule a person can read through, and both encode decisions that change in
reviewable ways.

The commit message says what this version is. From here, every change to a rule is a new commit, and
a report can name the commit it was built from. Together with the raw manifest, that one identifier
is enough to rebuild any past result exactly.
