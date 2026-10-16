---
title: Streamlit on your machine, and three ways to have it
version: 1
---

**Streamlit** is the opposite end from Metabase: a Python library that turns a short script into a
web page with widgets and charts. There are no menus and no saved questions. The app is the code, and
whoever writes the code decides everything — which is its strength for a page nobody else's tool can
draw, and its risk for definitions, which live wherever the programmer put them.

You do not need to know Python to follow this. The app in the next section is shown whole, with a
note beside each part saying what it does, and running it is three commands.

## In the virtual machine — the recommended path

Streamlit is installed into a **virtual environment**: a directory holding its own copy of Python's
libraries, so that what you install for this course cannot disturb anything else on the machine.
Ubuntu needs one package for that, then the environment is created and Streamlit installed into it
with its PostgreSQL driver. The versions are written out so your page matches the course:

```sh
sudo apt install -y python3-venv
```

```
ana@vm:~$ python3 -m venv ~/st
ana@vm:~$ ~/st/bin/pip install -q streamlit==1.65.0 "psycopg[binary]==3.3.6"
ana@vm:~$ ~/st/bin/streamlit version
Streamlit, version 1.65.0
ana@vm:~$ du -sh ~/st
473M	/home/ana/st
```

`pip install -q` prints nothing when it works. The environment takes 473 MB of disk, most of it
libraries Streamlit uses to draw charts.

The app connects to the database like Metabase does, through a role of its own that reads only what
it needs — here, two views of the layer:

```sql
CREATE ROLE streamlit_app LOGIN PASSWORD 'a-third-password-to-choose';
GRANT USAGE ON SCHEMA semantic TO streamlit_app;
GRANT SELECT ON semantic.orders, semantic.customers TO streamlit_app;
```

```
lantern=# CREATE ROLE streamlit_app LOGIN PASSWORD 'a-third-password-to-choose';
CREATE ROLE

lantern=# GRANT USAGE ON SCHEMA semantic TO streamlit_app;
GRANT

lantern=# GRANT SELECT ON semantic.orders, semantic.customers TO streamlit_app;
GRANT
```

## On your own computer, with Python

If Python 3 is installed on your computer, the same two `pip` lines in a virtual environment there
install the same versions. The app would then run on your computer and connect to PostgreSQL inside
the virtual machine, which lesson 1's arrangement deliberately does not allow; it works if
PostgreSQL also runs on your computer. Inside the virtual machine, nothing has to be opened.

## Online

Streamlit's company offers a free hosting service for Streamlit apps, Community Cloud, which deploys
an app from a public code repository. It needs an account, and the app has to reach a database on
the internet rather than one inside your machine. The course does not depend on it.
