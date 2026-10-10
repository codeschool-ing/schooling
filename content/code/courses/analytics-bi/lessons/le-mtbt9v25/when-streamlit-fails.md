---
title: When the app does not work
version: 1
---

Streamlit reports most failures in two places at once: on the page, as a red box with the error, and
in the terminal where it is running, as the same error with its full traceback. The last line of the
traceback is the one that names the problem.

## `streamlit: command not found`

```
ana@vm:~/revenue$ streamlit run app.py
bash: line 1: streamlit: command not found
```

Streamlit is installed inside the virtual environment, not on the machine, so the shell does not find
it by name. Call it by its path, `~/st/bin/streamlit`, as the last section does. (Activating the
environment with `source ~/st/bin/activate` also works, and then `streamlit` alone is found until the
terminal closes.)

## The page shows an old version of the app

You started the app a second time while the first was still running, perhaps in another terminal.
The second does not fail: it quietly takes the next port.

```
ana@vm:~/revenue$ timeout -s KILL 20 ~/st/bin/streamlit run app.py 2>&1 | grep -o "server started on .*"
server started on 0.0.0.0:8502
```

Port 8502 is not forwarded, so your browser at 8501 still shows the first app, with the old code.
Stop the old one with Ctrl+C in its terminal and start again.

## `No secrets found`

The last line in the terminal:

```
streamlit.errors.StreamlitSecretNotFoundError: No secrets found. Valid paths for a secrets.toml file or secret directories are: /home/ana/.streamlit/secrets.toml, /home/ana/revenue/.streamlit/secrets.toml
```

The file is missing, misnamed or in the wrong directory. Streamlit lists the two places it looked, and
the file has to be at one of them with exactly that name: `secrets.toml`, inside `.streamlit`, beside
`app.py` or in your home directory.

## `password authentication failed`

```
psycopg.OperationalError: connection failed: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "streamlit_app"
```

The password in `secrets.toml` is not the role's. It is the same message lesson 3 met for Metabase,
from the same server, for the same reason.

## It worked, I broke the connection, and it still works

`@st.cache_data(ttl=600)` keeps each answer for ten minutes. A connection broken after the first run is
invisible until the cached answers expire, or until the app is restarted, which clears them. That is
why the two failures above were produced by restarting the app: **a cache hides a broken source for
exactly as long as its time to live**, which is a property of every BI tool that caches, including
Metabase.
