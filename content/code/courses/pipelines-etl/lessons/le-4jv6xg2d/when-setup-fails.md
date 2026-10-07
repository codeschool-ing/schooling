---
title: When the setup fails
version: 1
---

`setup.sh` stops at the first error rather than carrying on, so **the last line it printed is the
line that broke.** Read that before anything else. Running it again is always safe: it keeps what
is done and carries on from where it stopped. Five failures account for most of it:

- **A line ending in `is required: apt-get install …`, or `there is no user ana`.** Something from
  the first section of this lesson is missing. Install what it names, or make the user, and run the
  setup again.
- **`/home/ana/pontofinal/shop.sh is missing`**, or the same for another file. The setup looks for
  the files beside itself, so all four belong in `~/pontofinal`, with exactly those names.
- **`pip` cannot reach the package index.** The error mentions a timeout, a certificate or a
  proxy. Airflow is installed against a constraints file that is fetched from GitHub, so the
  machine needs to reach both `pypi.org` and `raw.githubusercontent.com`. Try one `pip install
  requests` by hand in the virtual machine: when that works, the setup works.
- **`Text file busy`, `Permission denied` under `/opt/etl`.** Something from a previous attempt
  is still running. `sudo shop down` stops everything `shop` started, and then the setup can
  replace the files.
- **`No space left on device`.** The virtual environments need 1.3 GB at once and pip's download
  cache as much again while it works. Give the virtual machine a larger disk, or delete
  `/root/.cache/pip` after the first successful run.

**One failure prints no error at all: a file copied with a line missing.** The generator still
runs, and draws a different shop. Its line in the setup's output is the check, `customers 5079,
orders 17012, lines 26620 at 2026-02-28; 31 days of changes`. If yours differs, copy the file
again, delete `/var/lib/etl-data` so the setup draws it afresh, run the setup, then `sudo shop
reset`.

Two habits make the rest of the course easier. **Run `sudo shop reset` whenever a lesson says
so**: it puts the shop back to the night of 28 February, empties the warehouse and makes Airflow
forget everything, so your numbers match the lesson's again. And **never fix the lab by editing the
shop database by hand**: the pipelines in this course read it, and a row you changed behind
`shop`'s back is a row that makes your output disagree with the page for reasons nobody can find.
