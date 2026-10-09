---
title: What differs between environments, and where it lives
version: 1
---

Across this lesson and the last, the same code ran in four places — Ana's schemas, production's, the
test warehouse and, in lesson 17, a temporary directory — and nothing in the code said which. What
differed was **configuration**, kept outside it:

- **the dbt target**, chosen with `--target`, whose details are in `~/.dbt/profiles.yml`;
- **environment variables**: `SHOP_DB` and `WH_DB` for the loader, `PRICES_API_KEY` for the price
  client;
- **the checkout**: which tag the directory is on.

The rule this follows is short and easy to break: **code never asks which environment it is in.** An
`if target == "prod"` inside a model, a hard-coded schema name in a script, a test that knows it is a
test: each is a place where production runs code that development never ran, and that is where the
surprises live. When an environment has to behave differently — fewer threads in development, a
sample of the data in test — the difference goes into the configuration and the code reads it.

The same goes for secrets with more force. A password in the code is in every copy of the code, every
branch and every tag, for ever, since a version is a thing that can be returned to. Keep them in the
environment, give each environment its own, and give development none that can write to production.
The lab has one user for everything, which is convenient for a course and is the one thing here not
to copy.
