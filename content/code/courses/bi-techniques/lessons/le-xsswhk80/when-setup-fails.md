---
title: When the setup fails
version: 1
---

Setting up is where most people give up on a course like this, and almost always over one of five
problems. Each has a message you can recognise and a fix that takes a minute.

## "No such file or directory: 'daily_orders.csv'"

```
ana@vm:~/bi$ .venv/bin/python look.py
Traceback (most recent call last):
  File "/home/ana/bi/look.py", line 3, in <module>
    orders = pd.read_csv("daily_orders.csv", parse_dates=["date"], index_col="date")["orders"]
             ~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py", line 872, in read_csv
    return _read(filepath_or_buffer, kwds)
  File "/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py", line 300, in _read
    parser = TextFileReader(filepath_or_buffer, **kwds)
  File "/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py", line 1643, in __init__
    self._engine = self._make_engine(f, self.engine)
                   ~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^
  File "/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py", line 1907, in _make_engine
    self.handles = get_handle(
                   ~~~~~~~~~~^
        f,
        ^^
    ...<6 lines>...
        storage_options=self.options.get("storage_options", None),
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    )
    ^
  File "/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/common.py", line 930, in get_handle
    handle = open(
        handle,
    ...<3 lines>...
        newline="",
    )
FileNotFoundError: [Errno 2] No such file or directory: 'daily_orders.csv'
```

**Read the last line first.** Python prints the whole chain of calls that led to the problem, and
most of it is inside pandas, which is not where the problem is. The last line names it: the program
looked for `daily_orders.csv` and the file was not there. Either `panela.py` has not been run yet,
as here, or it was run in a different folder. The files are written into the folder you run
`panela.py` from, and the programs read them from the folder *they* are run from. Run everything
from the course folder and the problem disappears.

## "No module named 'statsmodels'"

```
ana@vm:~/bi$ python3 -c "import pandas, statsmodels, sklearn"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import pandas, statsmodels, sklearn
ModuleNotFoundError: No module named 'statsmodels'
```

**The program ran in the wrong Python.** `python3` is the system's, and the packages were installed
in the virtual environment's. On the machine these lessons were recorded on, the system's Python
happens to have pandas and not statsmodels, so the mistake shows up on the second package rather
than the first. That is the dangerous version of this problem: a program that only uses pandas
would run, on a different version from the lessons', and print numbers that differ for no visible
reason. Run every program as `.venv/bin/python`.

## "can't open file"

```
ana@vm:~/bi$ .venv/bin/python lok.py
.venv/bin/python: can't open file '/home/ana/bi/lok.py': [Errno 2] No such file or directory
```

The message names the path it looked for, and that path is the clue: a typo in the name, as here,
or a terminal opened in a different folder. `ls` shows what is really there.

## pip says "externally-managed-environment"

Recent Linux distributions, Ubuntu 24.04 among them, refuse `pip install` into the system's own
Python, to protect the packages the system depends on. **That is the reason for the virtual
environment**: install into `.venv`, never with `sudo pip`. If `python3 -m venv` itself fails on
Ubuntu or Debian, the module is packaged separately and `sudo apt install python3-venv` adds it.

## pip cannot find a version, or cannot reach the internet

pip refuses a package whose requirements your Python does not meet, and numpy and scipy need 3.12
or newer: on an older Python the install stops with a message that no matching version was found.
`python3 --version` settles it, and the fix is a newer Python. A message mentioning `SSL` or
`certificate` means something else: a network in between, such as a company proxy or a school
firewall. Try once from another network. If it works there, the problem is the network and not
your setup, and the online path in "The computer you will analyse on" avoids it entirely.

## When none of these is it

Search for the **last line** of the error, word for word, together with the package's name. Almost
every message a fresh setup produces has been met and answered by somebody before you.
