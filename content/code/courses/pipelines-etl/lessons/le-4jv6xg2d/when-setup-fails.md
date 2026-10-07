---
title: When the setup fails
version: 1
---

`lab.sh` stops at the first error rather than carrying on, so **the last line it printed is the
line that broke.** Read that before anything else. Four failures account for most of it:

- **`PostgreSQL 16 is required: apt-get install postgresql-16`.** The script found no `initdb`.
  Install the package and run `lab.sh up` again; it skips what is already done and carries on from
  where it stopped.
- **`pip` cannot reach the package index.** The error mentions a timeout, a certificate or a
  proxy. Airflow is installed against a constraints file that is fetched from GitHub, so the
  machine needs to reach both `pypi.org` and `raw.githubusercontent.com`. Try one `pip install
  requests` by hand in the virtual machine: when that works, the script works.
- **`Text file busy`, `Permission denied` under `/opt/etl`.** Something from a previous attempt
  is still running. `sudo bash ~/lab/lab.sh down` stops everything the lab started, and then `up`
  can replace the files.
- **`No space left on device`.** The virtual environments need 1.3 GB at once and pip's download
  cache as much again while it works. Give the virtual machine a larger disk, or delete
  `/root/.cache/pip` after the first successful run.

Two habits make the rest of the course easier. **Run `lab.sh reset` whenever a lesson says so**:
it puts the shop back to the night of 28 February, empties the warehouse and makes Airflow forget
everything, so your numbers match the lesson's again. And **never fix the lab by editing the shop
database by hand**: the pipelines in this course read it, and a row you changed without the lab
knowing is a row that makes your output disagree with the page for reasons nobody can find.

If something fails that is not on this list, the script is short enough to read. Find the
function the last line came from and run its commands one at a time.
