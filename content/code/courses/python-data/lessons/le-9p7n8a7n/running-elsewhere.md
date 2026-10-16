---
title: Running it from somewhere else
version: 1
---

**A relative path is relative to the folder you run the program from, not to the folder the program is
in.** In JupyterLab those are always the same folder, so a notebook never meets the difference. A
script meets it the first time it is run from anywhere else: a schedule, which usually starts in the
home folder, or a colleague who keeps the script in one place and the data in another.

Run from `/tmp`, with the data named the way the notebook named it:

```
(.venv) ana@lab:~/pydata$ cd /tmp
(.venv) ana@lab:/tmp$ python ~/pydata/station_report.py S05 --data trips.csv
Traceback (most recent call last):
  File "/home/ana/pydata/station_report.py", line 50, in <module>
    main()
  File "/home/ana/pydata/station_report.py", line 39, in main
    trips = load(args.data)
            ^^^^^^^^^^^^^^^
  File "/home/ana/pydata/station_report.py", line 13, in load
    return pd.read_csv(path, parse_dates=["started_at"], date_format="%Y-%m-%d %H:%M:%S")
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/pydata/.venv/lib/python3.12/site-packages/pandas/io/parsers/readers.py", line 872, in read_csv
    return _read(filepath_or_buffer, kwds)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/pydata/.venv/lib/python3.12/site-packages/pandas/io/parsers/readers.py", line 300, in _read
    parser = TextFileReader(filepath_or_buffer, **kwds)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/pydata/.venv/lib/python3.12/site-packages/pandas/io/parsers/readers.py", line 1643, in __init__
    self._engine = self._make_engine(f, self.engine)
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/pydata/.venv/lib/python3.12/site-packages/pandas/io/parsers/readers.py", line 1907, in _make_engine
    self.handles = get_handle(
                   ^^^^^^^^^^^
  File "/home/ana/pydata/.venv/lib/python3.12/site-packages/pandas/io/common.py", line 930, in get_handle
    handle = open(
             ^^^^^
FileNotFoundError: [Errno 2] No such file or directory: 'trips.csv'
```

`trips.csv` was looked for in `/tmp`, where the command was typed, and it is not there. The traceback
is long, most of it inside pandas, and its last line is the one to read.

The script's default does not have this problem, because it is built from `HERE`, the folder of the
script itself:

```py
HERE = Path(__file__).parent
```

`__file__` is the path of the running file, and `.parent` its folder, so `HERE / "trips.csv"` is the
data beside the script wherever the command is typed:

```
(.venv) ana@lab:/tmp$ python ~/pydata/station_report.py S05
started_at
1     359
2     346
3     345
4     352
5     318
6     348
7     343
8     340
9     334
10    376
11    354
12    339
saved S05.png
```

The chart, though, went to `/tmp/S05.png`. The output default is relative on purpose: a report is
saved where the person running it is working, which is the usual expectation of a command-line
program. **Inputs that belong with the script are found from the script's folder; outputs go where the
caller is, or where `--out` says.**

The same rule answers the question of the data's location on another machine. The script takes
`--data`, so the data can live anywhere, and nothing in the code needs editing to point at it.
