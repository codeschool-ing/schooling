---
title: Parameters, from the command line
version: 1
---

**A parameter is what the person running a script chooses without editing it.** In the notebook the
station was a line of code, `station = "S05"`; changing it meant opening the notebook, editing a cell
and running everything again. `argparse` makes it a word typed after the script's name.

The help `argparse` writes from the arguments the script declared:

```
(.venv) ana@lab:~/pydata$ python station_report.py -h
usage: station_report.py [-h] [--data DATA] [--out OUT] station

Trips per month from one station of Maré Bikes.

positional arguments:
  station      a station code, such as S05

options:
  -h, --help   show this help message and exit
  --data DATA  the trips file (default: trips.csv beside this script)
  --out OUT    where to save the chart (default: STATION.png)
```

Nobody wrote that text. `argparse` built it from each `add_argument`: `station` is **positional**,
required and given by place; `--data` and `--out` are **options**, named and optional, with the
defaults their `help` describes. `-h` was added for free.

A run for one station:

```
(.venv) ana@lab:~/pydata$ python station_report.py S05
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

The table the notebook displayed is printed, because the script said `print`, and the chart is in
`S05.png`. Another station is another run, with nothing edited:

```
(.venv) ana@lab:~/pydata$ python station_report.py S12 --out quiet.png
started_at
1     71
2     65
3     88
4     64
5     70
6     68
7     73
8     64
9     66
10    76
11    69
12    73
saved quiet.png
```

## Saying no

A station that does not exist:

```
(.venv) ana@lab:~/pydata$ python station_report.py S99
no trips from station 'S99'
(.venv) ana@lab:~/pydata$ echo $?
1
```

**`sys.exit` with a message prints it and ends the script with a status of 1**, which `echo $?` shows:
`$?` is the status of the last command, and 0 means success. Anything that runs the script, a
schedule, another script, a pipeline, reads that number to know whether to go on. A script that saved
an empty chart and ended with 0 would have reported success for a typo.

A missing argument is refused by `argparse` itself, before any of the script's own code runs:

```
(.venv) ana@lab:~/pydata$ python station_report.py
usage: station_report.py [-h] [--data DATA] [--out OUT] station
station_report.py: error: the following arguments are required: station
(.venv) ana@lab:~/pydata$ echo $?
2
```

Status 2 this time: `argparse` uses it for a command line it could not understand, so a caller can
tell a wrong call from a failed run.
