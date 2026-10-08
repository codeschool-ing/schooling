---
title: Building it
version: 1
---

With the packages, the user and the four files in place, `ana` runs the setup once:

```
ana@vm:~$ sudo bash ~/pontofinal/setup.sh
customers 5079, orders 17012, lines 26620 at 2026-02-28; 31 days of changes
ready: log in again as ana, or run: . ~/.profile
```

The line before `ready` is the generator reporting what it drew. **The first run downloads every
package the six environments need, so most of its time is the download.** On the recording machine
the packages were already there, so the transcript shows only the data being drawn and loaded. A
second run finds everything in place, checks it and stops.

Then log in again as `ana`, or run `. ~/.profile`, so the shell reads `/etc/etl.env`. Go to `~/etl`,
the working directory the setup made, and check what you have:

```
ana@vm:~/etl$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~/etl$ python --version
Python 3.13.16
ana@vm:~/etl$ airflow version
3.3.2
ana@vm:~/etl$ dbt --version | head -2
Core:
  - installed: 1.12.5
```

And what it cost:

```
ana@vm:~/etl$ du -sh /var/lib/etl-data /var/lib/etl-pg /opt/etl
19M	/var/lib/etl-data
78M	/var/lib/etl-pg
1.3G	/opt/etl
```

**The data is small and the tools are not.** Nineteen megabytes of trade and 1.3 GB of software
to move it. That ratio is normal for a laptop and the opposite of production, and lesson 19 is
where the data gets large enough to matter.
