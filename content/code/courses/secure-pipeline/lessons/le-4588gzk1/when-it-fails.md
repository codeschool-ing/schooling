---
title: When the setup fails
version: 1
---

A lab that does not work on the first try is normal, and the failures are few and repeat. Each one
below was produced on purpose on the recording machine, so the message is the one you will see.
Read the last line of an error first: tools print the cause at the bottom and the context above it.

### The CI does not run, and nothing says why

This is the dangerous one, because the push succeeds. Git runs a hook only if it is executable, and
when it is not, it prints a hint and carries on:

```
ana@vm:~/linkbox$ chmod -x ~/ci/linkbox.git/hooks/post-receive
ana@vm:~/linkbox$ git commit -q --allow-empty -m "does the CI run?"
ana@vm:~/linkbox$ git push ci main
hint: The 'hooks/post-receive' hook was ignored because it's not set as executable.
hint: You can disable this warning with `git config advice.ignoredHook false`.
To /home/ana/ci/linkbox.git
   85988f7..82c44d5  main -> main
ana@vm:~/linkbox$ chmod +x ~/ci/linkbox.git/hooks/post-receive
```

**The push went through and no pipeline ran.** Without the hint there would be no sign of it at all:
no `remote:` lines, and a commit on the server that nothing checked. That is the failure this whole
course is built against, a check that silently did not happen, and it is why the pipeline prints a
line for every stage it runs and a last line saying it passed. **When you push, look for that last
line, not for the absence of an error.** `chmod +x` on the hook fixes it, and the next push runs.

### Docker does not answer

```
ana@vm:~/linkbox$ DOCKER_HOST=unix:///run/nothing.sock docker version --format "{{.Server.Version}}"

failed to connect to the docker API at unix:///run/nothing.sock; check if the path is correct and if the daemon is running: dial unix /run/nothing.sock: connect: no such file or directory
```

The client could not reach the daemon. The message names the socket it tried, which tells you which
of three causes it is. The daemon is not running: `sudo systemctl start docker` on Linux, or start
Docker Desktop. `DOCKER_HOST` points somewhere else: `unset DOCKER_HOST`. Or, with the default
socket, the error ends in `permission denied` instead, which means your user is not in the `docker`
group yet, or is and has not logged in again since; `id -nG` tells you which. That last variant was
not reproduced here.

### PyPI cannot be reached

```
ana@vm:~/linkbox$ rm -rf .venv && uv venv -q
ana@vm:~/linkbox$ HTTPS_PROXY=http://127.0.0.1:9 uv pip install -r requirements.txt
error: Request failed after 3 retries in 5.0s
  Caused by: Failed to fetch: `https://pypi.org/simple/itsdangerous/`
  Caused by: error sending request for url (https://pypi.org/simple/itsdangerous/)
  Caused by: client error (Connect)
  Caused by: tunnel error: failed to create underlying connection
  Caused by: tcp connect error
  Caused by: Connection refused (os error 111)
```

uv tried three times and gave up, and the chain of causes ends with the connection. This one was
produced by pointing uv at a proxy where nothing listens, so the chain mentions a tunnel; on a
computer with no network at all it ends in a name that could not be resolved. Either way the
package index was never reached, so the requirements file is not the problem. If your computer
reaches the internet through a company proxy, `HTTPS_PROXY` has to carry its address, and the
proxy's certificate authority has to be one your system trusts.

### The port is taken

```
ana@vm:~/linkbox$ .venv/bin/gunicorn --bind 127.0.0.1:8000 app:app
[2026-10-23 01:09:30 -0300] [24073] [INFO] Starting gunicorn 21.2.0
[2026-10-23 01:09:30 -0300] [24073] [ERROR] Connection in use: ('127.0.0.1', 8000)
[2026-10-23 01:09:30 -0300] [24073] [ERROR] Retrying in 1 second.
[2026-10-23 01:09:31 -0300] [24073] [ERROR] Connection in use: ('127.0.0.1', 8000)
[2026-10-23 01:09:31 -0300] [24073] [ERROR] Retrying in 1 second.
[2026-10-23 01:09:32 -0300] [24073] [ERROR] Connection in use: ('127.0.0.1', 8000)
[2026-10-23 01:09:32 -0300] [24073] [ERROR] Retrying in 1 second.
[2026-10-23 01:09:33 -0300] [24073] [ERROR] Connection in use: ('127.0.0.1', 8000)
[2026-10-23 01:09:33 -0300] [24073] [ERROR] Retrying in 1 second.
[2026-10-23 01:09:34 -0300] [24073] [ERROR] Connection in use: ('127.0.0.1', 8000)
[2026-10-23 01:09:34 -0300] [24073] [ERROR] Retrying in 1 second.
[2026-10-23 01:09:35 -0300] [24073] [ERROR] Can't connect to ('127.0.0.1', 8000)
```

Something already listens on port 8000, often a gunicorn you started earlier with `--daemon` and
did not stop. `ss -ltnp 'sport = :8000'` names the process, and `kill $(cat linkbox.pid)` stops
the one this lesson started. gunicorn retries five times, once a second, before it gives up, which
is why the error repeats.

### Anything else

Run the same command again with nothing changed, once. If it fails the same way, the message is
the information, and the last line plus the name of the tool is what to search for. If it fails
differently, something on the machine changed between the two runs, and that is worth knowing
before anything else.
