---
title: What this course is, and how it shows its work
version: 1
---

**This is the scientific stack on top of Python, and not Python again.** The `python` course
taught the language: its types, functions, modules and files. This one assumes all of that and
adds the four tools that turn the language into something you can analyse data with — a notebook
to work in, **NumPy** for arrays, **pandas** for tables, and **matplotlib** with **seaborn** for
charts — plus the habits that make the work survive being handed to somebody else.

It runs in this order:

| lessons | what |
|---|---|
| 1 to 3 | the notebook and the environment: where the code runs, and why a notebook lies when it is run out of order |
| 4 to 8 | NumPy: arrays, loops you no longer write, broadcasting, masks, and random numbers that repeat |
| 9 to 12 | pandas: the DataFrame, reading every common format, selecting, and types, dates and missing values |
| 13 to 17 | reshaping: grouping, joining, pivoting, windows over time, and why `apply` is the slow path |
| 18 and 19 | charts, from matplotlib's parts to seaborn's one-liners |
| 20 and 21 | memory and speed, and turning a notebook into a script that runs on another computer |

The course after this one is `machine-learning`, and it assumes everything here without
re-explaining it. Statistics helps and is not assumed: the charts here get drawn before they get
interpreted.

## How the outputs are shown

Every cell in this course was run, and what it printed is pasted under it. The code is a
highlighted block; what it printed is the plain block straight after it:

```python
2 ** 10
```

```
1024
```

When a cell's last line is a table, JupyterLab draws it with borders and shading. The course shows
the plain-text version of the same table, which is what a notebook keeps beside the drawing and
what `print` would show; the numbers are the same, and the section on the notebook file, later in
this lesson, says where each version lives. Terminal sessions start with a prompt, `(.venv) ana@lab:~/pydata$`, where `ana` is
the analyst and `lab` the machine they were recorded on.

## The versions are pinned, and that matters more than usual

pandas and NumPy have both changed things under their users within the last few years. NumPy 2
changed how numbers print and how two types combine; pandas 3 changed what happens when you
modify a selection, and made text its own type. Code written against the old behaviour still
runs, often with a different answer. **The lab section pins every library to the version these
outputs came from**, so that a difference between your screen and this page means something.
Where an older version behaved differently in a way you will meet in other people's code, the
lesson says so: lesson 4 for NumPy, lessons 11 and 12 for pandas.

## The data is one city's bikes

Every lesson from lesson 9 on works on the same three files: the stations, the trips and the
weather of a bike-share scheme in Recife. The NumPy lessons use them too, read as plain arrays.
Two sections from now you make them yourself, with a program shown in full.
