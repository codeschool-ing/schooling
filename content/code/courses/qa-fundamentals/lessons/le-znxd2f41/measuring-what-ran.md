---
title: Measuring which lines ran
version: 1
---

**Python ships with a module called `trace` that watches a program run and counts how many times each
line executed.** That count is statement coverage, and it needs nothing installed. To use it, the tests
have to be a program too: here are lesson 6's six cases, the ones from the rule's table, written so that
`trace` can watch them. Save it in `~/aurora` as `cases.py`.

```schooling-example
{"language": "python", "file": "cases.py", "parts": [{"code": "# cases.py\nfrom tickets import price\n", "note": "It calls `price` from `tickets.py` directly, without the command line, so the trace module can watch which lines of `price` run."}, {"code": "\nCASES = [\n    (35, False, \"thu\", \"16:59\", 2800),\n    (35, False, \"thu\", \"17:00\", 3600),\n    (20, True, \"thu\", \"20:00\", 1800),\n    (11, False, \"thu\", \"20:00\", 1800),\n    (12, False, \"thu\", \"20:00\", 3600),\n    (35, False, \"wed\", \"20:00\", 1800),\n]\n", "note": "The six cases from lesson 6’s table, each with the price it should give, in centavos."}, {"code": "\nfor age, student, day, time, expected in CASES:\n    got = price(age, student, day, time)\n    print(\"ok  \" if got == expected else \"FAIL\", age, student, day, time, got)\n", "note": "Runs each case and prints `ok` or `FAIL` beside it. A program that checks another program’s answers against expected ones is a test, and lesson 15 gives this kind a proper home."}]}
```

## Running it under trace

`-m trace` runs `cases.py` under the trace module. `--count` counts the lines, `--missing` marks the ones
that never ran, `--summary` prints a percentage per file, and `-C .` writes the annotated copies into the
current directory.

```
lia@lab:~/aurora$ python -m trace --count --missing --summary -C . cases.py
ok   35 False thu 16:59 2800
ok   35 False thu 17:00 3600
ok   20 True thu 20:00 1800
ok   11 False thu 20:00 1800
ok   12 False thu 20:00 3600
ok   35 False wed 20:00 1800
lines   cov%   module   (path)
    5   100%   cases   (cases.py)
   24    83%   home.lia.aurora.tickets   (/home/lia/aurora/tickets.py)
```

Six `ok`s: the six cases pass, as in lesson 6. Below them, the summary: every line of `cases.py` ran, and
83% of the lines of `tickets.py` did. The other 17% is what this lesson is about.

## Reading the annotated copy

`trace` wrote a copy of `tickets.py` with a count in front of every line that runs. It names the copy
after the file's full path, so on the recording machine it is `home.lia.aurora.tickets.cover`; on yours
the middle part is your own user name, and `*tickets.cover` finds it whatever it is called.

```
lia@lab:~/aurora$ ls *.cover
cases.cover
home.lia.aurora.tickets.cover
lia@lab:~/aurora$ cat *tickets.cover
       # tickets.py
    1: import sys
       
    1: EVENING = 3600
    1: MATINEE = 2800
       
       
    1: def price(age, student, day, time):
    6:     if time < "17:00":
    1:         full = MATINEE
           else:
    5:         full = EVENING
    6:     half = False
    6:     if student:
    1:         half = True
    6:     if age > 60:
>>>>>>         half = True
    6:     if age < 12:
    1:         half = True
    6:     if day == "wed":
    1:         full = full // 2
    6:     if half:
    2:         return full // 2
    4:     return full
       
       
    1: def brl(cents):
>>>>>>     return f"R$ {cents // 100},{cents % 100:02d}"
       
       
    1: if __name__ == "__main__":
>>>>>>     age, student, day, time = sys.argv[1:]
>>>>>>     print(brl(price(int(age), student == "yes", day, time)))
```

The number before each line is how many times it ran; a line marked `>>>>>>` never ran at all. Three
groups of lines never ran, and each means something different:

- **`brl` and the last two lines**: the command-line part. `cases.py` calls `price` directly, so this is
  expected, and lesson 6 already ran those lines from the outside. A coverage report always needs this
  kind of reading: not every unrun line is a gap;
- **`half = True` after `if age > 60`**: no case was over sixty, so the line that gives older people their
  reduction **has never been run by these tests**. Whatever it does, right or wrong, nothing has checked
  it;
- nothing else in `price`. Every other line ran at least once.

That second finding is what the report is for. Lesson 6's table was built from the rule, and the rule
has three reductions; the table tested two of them. Nobody noticed the gap by reading the table. The
coverage report noticed it in one line.

## Closing the gap, and what that proves

The obvious response is to add a case that runs the line: a customer over sixty. Here is `cases.py`
again with a seventh case, an adult of sixty-one at an evening session:

```python
# cases.py
from tickets import price

CASES = [
    (35, False, "thu", "16:59", 2800),
    (35, False, "thu", "17:00", 3600),
    (20, True, "thu", "20:00", 1800),
    (11, False, "thu", "20:00", 1800),
    (12, False, "thu", "20:00", 3600),
    (35, False, "wed", "20:00", 1800),
    (61, False, "thu", "20:00", 1800),
]

for age, student, day, time, expected in CASES:
    got = price(age, student, day, time)
    print("ok  " if got == expected else "FAIL", age, student, day, time, got)
```

```
lia@lab:~/aurora$ python -m trace --count --missing --summary -C . cases.py
ok   35 False thu 16:59 2800
ok   35 False thu 17:00 3600
ok   20 True thu 20:00 1800
ok   11 False thu 20:00 1800
ok   12 False thu 20:00 3600
ok   35 False wed 20:00 1800
ok   61 False thu 20:00 1800
lines   cov%   module   (path)
    5   100%   cases   (cases.py)
   24    87%   home.lia.aurora.tickets   (/home/lia/aurora/tickets.py)
lia@lab:~/aurora$ grep -A1 "age > 60" *tickets.cover
    7:     if age > 60:
    1:         half = True
```

Seven `ok`s, the file's coverage rises from 83% to 87%, and the line now ran once. Every line of `price`
has run. By statement coverage, `price` is fully tested.

**And the sixty-year-old's defect is still there.** Sixty-one is over sixty in every reading of the rule,
so the line ran and gave the right answer; the case that would have failed is sixty, and nobody chose it.
Statement coverage asked whether the line ran. It never asked whether the line was right, and it cannot,
because that needs an expected result, which only the rule can give.

That is the most important thing to know about coverage, and it is why lesson 22 lists a coverage
percentage among the numbers that turn into theatre when somebody is judged by them.
