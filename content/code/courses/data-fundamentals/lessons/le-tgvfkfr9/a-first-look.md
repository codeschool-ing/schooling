---
title: A first look, and the two halves of one program
version: 1
---

**A small program shows the split this lesson has been describing better than any table.** Here is
Marta's kind of question at its smallest: how many rides started at each station on one Sunday
morning. The data is six rides, pasted into the program as the app might export them, so there is
nothing to download. Save it in `~/roda` as `first.py`.

```schooling-example
{"language": "python", "file": "first.py", "parts": [
{"code": "# first.py\nimport csv\nimport io\n\nEXPORT = \"\"\"ride_id,bike_id,start_station,started_at,minutes\nR000001,B017,ST02,2025-09-14 07:52,12\nR000002,B044,ST05,2025-09-14 08:03,25\nR000003,B017,ST06,2025-09-14 08:31,9\nR000004,B081,ST02,2025-09-14 09:10,31\nR000005,B032,ST02,2025-09-14 10:47,7\nR000006,B044,ST08,2025-09-14 11:20,44\n\"\"\"\n", "note": "The export, as text. A real one arrives as a file every morning; here it is six lines inside the program, so the program is the whole lab. The first line names the columns."},
{"code": "\nrides = list(csv.DictReader(io.StringIO(EXPORT)))\n", "note": "`csv.DictReader` turns each line into a dictionary keyed by the column names. `io.StringIO` lets it read a string as though it were a file."},
{"code": "per_station = {}\nfor ride in rides:\n    station = ride[\"start_station\"]\n    per_station[station] = per_station.get(station, 0) + 1\n", "note": "The question itself: one counter per station. This line is where the program depends on the export calling the column `start_station`."},
{"code": "\nprint(len(rides), \"rides on 14 September\")\nfor station, n in sorted(per_station.items()):\n    print(station, n)\n", "note": "The answer, one station to a line, in order."}
]}
```

Run it:

```
ana@lab:~/roda$ python first.py
6 rides on 14 September
ST02 3
ST05 1
ST06 1
ST08 1
```

Three of the six rides left from Rua XV. That is the analyst's half of the program: a definition (a
ride counts at the station it started from) and a count.

## The engineer's half is everything above `rides =`

The program trusts four things it never checks: that the export exists, that its columns are called
what they were called yesterday, that every ride is in it once, and that it is the export for the right
day. Each of those is somebody's job, and at Roda Livre it is Davi's.

Break the second one. The app team renames a column, and the next morning's export says `start`
where it said `start_station`. The command below makes that version of the file and runs it:

```
ana@lab:~/roda$ sed "s/,start_station,started_at/,start,started_at/" first.py > renamed.py
ana@lab:~/roda$ python renamed.py
Traceback (most recent call last):
  File "/home/ana/roda/renamed.py", line 17, in <module>
    station = ride["start_station"]
              ~~~~^^^^^^^^^^^^^^^^^
KeyError: 'start_station'
```

That failure is loud, and **loud is the good kind**. The program stops, names the column it looked
for, and nobody gets a wrong number.

Now break the third. A retried export writes ride `R000002` twice:

```
ana@lab:~/roda$ sed "/^R000002/p" first.py > twice.py
ana@lab:~/roda$ python twice.py
7 rides on 14 September
ST02 3
ST05 2
ST06 1
ST08 1
```

Seven rides on a morning that had six, and Rodoferroviária counted twice. Nothing stopped, nothing
complained, and the output looks exactly as trustworthy as the first one. **That is the failure a data
engineer is paid to prevent**, because nobody downstream can see it. Lesson 3 builds a pipeline that
can be run twice without counting twice; lesson 7 checks a delivery before trusting it.

Keep `first.py`: it is the smallest version of every pipeline in the course, an input, a definition and
an output, and it is useful to have a program you understand completely beside the ones that are bigger.
