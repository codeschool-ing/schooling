---
title: When the setup fails
version: 1
---

Setting up is where most people who give up on a course like this give up, and almost always over
one of a handful of messages. Each one below was produced on purpose, on the machine the course was
recorded on, by undoing one step of the setup. Find the one that matches what you see.

## `externally-managed-environment`

```
ana@lab:~/emb$ pip install numpy
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
    
    If you wish to install a non-Debian-packaged Python package,
    create a virtual environment using python3 -m venv path/to/venv.
    Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    sure you have python3-full installed.
    
    If you wish to install a non-Debian packaged Python application,
    it may be easiest to use pipx install xyz, which will manage a
    virtual environment for you. Make sure you have pipx installed.
    
    See /usr/share/doc/python3.12/README.venv for more information.

note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
```

**`pip` ran outside the course's environment.** Ubuntu protects the Python it uses for itself and
refuses to install packages into it. The environment `setup.sh` made has a `pip` of its own, and
the line it added to `~/.bashrc` puts that one first, but only in a terminal opened afterwards. Type
`source ~/.bashrc`, or open a new terminal, and `which python` should then answer
`~/.venvs/emb/bin/python` with your home directory in front of it.

## `ensurepip is not available`

```
ana@lab:~/emb$ python3 -m venv ~/.venvs/try
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/ana/.venvs/try/bin/python3
```

**The package that lets Python make environments is missing.** Install it, delete the half-made
environment, and run the setup again:

```bash
sudo apt install -y python3-venv
rm -rf ~/.venvs/emb
bash setup.sh
```

## `Is the server running locally`

```
ana@lab:~/emb$ psql -c "SELECT 1"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
```

**PostgreSQL is not running.** Ubuntu starts it when it is installed and normally whenever the
computer starts, so this tends to appear after a restart on a system that does not start its
services by itself. Start it with `sudo service postgresql start`. If `psql` instead says that a **role** does not exist, the
`createuser` line of the previous section was skipped; run it, and then `createdb shop`.

## `extension "vector" is not available`

```
ana@lab:~/emb$ psql -c "CREATE EXTENSION vector"
ERROR:  extension "vector" is not available
DETAIL:  Could not open extension control file "/usr/share/postgresql/16/extension/vector.control": No such file or directory.
HINT:  The extension must first be installed on the system where PostgreSQL is running.
```

**PostgreSQL is running, but pgvector is not installed beside it.** The extension is a separate
package, and the database only finds it once it is on disk:

```bash
sudo apt install -y postgresql-16-pgvector
```

Nothing needs restarting. Asked straight afterwards which version of the extension it can find, it
answers:

```
ana@lab:~/emb$ psql -c "SELECT name, default_version FROM pg_available_extensions WHERE name = 'vector'"
  name  | default_version 
--------+-----------------
 vector | 0.6.0
(1 row)
```

Lesson 2 is where `CREATE EXTENSION` runs for real.

## `No module named 'minilm'`

```
ana@lab:~$ python -c "from minilm import embed"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'minilm'
```

**The program ran from the wrong directory.** Python finds `minilm.py` because it sits in the
directory you run from, and that directory is `~/emb`. Type `cd ~/emb` and run it again. The same
message for `numpy`, `chromadb` or any other library means the terminal is outside the environment:
that is the first case above.

## Anything else

Two habits get through most of the rest. Read the **last** line of a long error first, because a
Python traceback lists every call on the way down and the cause comes at the bottom. And compare
your command with the page character by character. A quote that became a curly quote on the way
through a chat program accounts for many of the remaining ones, and so does the last line of a
pasted block that never arrived. When a whole step has gone wrong, `setup.sh` can safely be run again: it installs
into the same environment, downloads and checks the model again, and adds its lines to `~/.bashrc`
only once.
