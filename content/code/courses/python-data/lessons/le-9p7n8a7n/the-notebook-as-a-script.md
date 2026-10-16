---
title: The notebook, as a script
version: 1
---

**A notebook is the right place to find an answer and the wrong place to keep producing it.** The day
somebody asks for the same chart every month, for a different station each time, the notebook has
to run without you: from a terminal, on another computer, on a schedule. This lesson moves one
notebook there, step by step, and each step is a failure the notebook was hiding.

Ana's notebook, `stations.ipynb`, counts the trips from one station per month and saves a chart. Its
four cells, run top to bottom:

```py
import pandas as pd
import matplotlib.pyplot as plt
```

```py
%time trips = pd.read_csv("trips.csv", parse_dates=["started_at"], date_format="%Y-%m-%d %H:%M:%S")
```

```py
station = "S05"
mine = trips[trips["start_station"] == station]
per_month = mine.groupby(mine["started_at"].dt.month).size()
per_month
```

```py
fig, ax = plt.subplots(layout="constrained")
ax.bar(per_month.index, per_month.to_numpy())
ax.set_title(f"Trips from {station}, 2025")
fig.savefig(f"{station}.png")
```

It works in JupyterLab, and lesson 2's test passes: Restart and Run All gives the same table and the
same chart. The first move is the one JupyterLab offers itself. `jupyter nbconvert --to script`
writes the code cells out as a Python file:

```
(.venv) ana@lab:~/pydata$ jupyter nbconvert --to script stations.ipynb
[NbConvertApp] Converting notebook stations.ipynb to script
[NbConvertApp] Writing 576 bytes to stations.py
```

```
(.venv) ana@lab:~/pydata$ cat stations.py
#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd
import matplotlib.pyplot as plt


# In[2]:


get_ipython().run_line_magic('time', 'trips = pd.read_csv("trips.csv", parse_dates=["started_at"], date_format="%Y-%m-%d %H:%M:%S")')


# In[3]:


station = "S05"
mine = trips[trips["start_station"] == station]
per_month = mine.groupby(mine["started_at"].dt.month).size()
per_month


# In[4]:


fig, ax = plt.subplots(layout="constrained")
ax.bar(per_month.index, per_month.to_numpy())
ax.set_title(f"Trips from {station}, 2025")
fig.savefig(f"{station}.png")

```

Every code cell is there, in order, under a comment with its execution count, `# In[3]:`. Two things
changed on the way. The `%time` line became `get_ipython().run_line_magic(...)`, because `%time` is
not Python: it is a command to IPython, the program inside the kernel, and `nbconvert` wrote it as the
call IPython would make. And `per_month` on its own line is still there, as a line that computes a
value and does nothing with it.

Run as a program, the file shows both:

```
(.venv) ana@lab:~/pydata$ python stations.py
Traceback (most recent call last):
  File "/home/ana/pydata/stations.py", line 14, in <module>
    get_ipython().run_line_magic('time', 'trips = pd.read_csv("trips.csv", parse_dates=["started_at"], date_format="%Y-%m-%d %H:%M:%S")')
    ^^^^^^^^^^^
NameError: name 'get_ipython' is not defined
```

**`get_ipython` exists only inside IPython**, so the script stops at the second cell. Had the magic
not been there, it would have run to the end, saved the chart, and printed nothing at all: the table
the notebook showed under the third cell was the notebook displaying the last value of a cell, and a
script displays only what it prints.

A converted notebook is a start, not a script. The rest of this lesson rewrites it into one.
