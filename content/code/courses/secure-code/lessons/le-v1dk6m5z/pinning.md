---
title: Pinning, and what it costs
version: 1
---

`flask==3.1.3` is a **pin**: exactly that version, nothing else. `flask>=3.1` is a **range**: that
version or anything newer. The choice between them is a trade, and it is worth seeing both sides
before picking one.

| | exact pins (`==`) | ranges (`>=`, `~=`) |
|---|---|---|
| what gets installed | the same thing every time, on every machine | whatever is newest on the day |
| a new advisory | stays until somebody raises the pin | fixed automatically, when the fix is in range |
| a broken release upstream | never arrives by surprise | arrives on the next install, unannounced |
| what it needs | a routine to update | trust that every release in the range is good |

**For an application, pin**, and update on purpose. A deployment that installs different code on
Tuesday from Monday, with no change in the repository, cannot be reproduced, reviewed or rolled
back. The security argument and the reliability argument point the same way: you want to know
exactly what is running. A **library** published for others to use is the opposite case: it
declares ranges, so that the applications using it can resolve one version for everybody.

### Pin everything, not just what you named

The file in the previous section pins three packages and lets pip choose the versions of their
dependencies: MarkupSafe, Werkzeug, urllib3 and the rest. Those are installed by range, so the
"pinned" project changes underneath anyway. `pip freeze` prints every package in an environment at its exact version, and a file made from it pins the transitive dependencies too. Tools such as `pip-tools` and `uv` write the same kind of complete **lock file** from a short list of what you asked for. Neither tool was run for this course.

### Pin the bytes, too

A version number names a release. It does not prove that the file downloaded is the file that was
published. pip can check that with a **hash** written beside each pin. `pip hash` computes one
from a downloaded file:

```
(.venv) ana@vm:~/sc/deps$ pip download --no-deps --progress-bar off -d ~/wheels jinja2==3.1.6
Collecting jinja2==3.1.6
  Using cached jinja2-3.1.6-py3-none-any.whl.metadata (2.9 kB)
Using cached jinja2-3.1.6-py3-none-any.whl (134 kB)
Saved /home/ana/wheels/jinja2-3.1.6-py3-none-any.whl
Successfully downloaded jinja2
(.venv) ana@vm:~/sc/deps$ pip hash ~/wheels/jinja2-3.1.6-py3-none-any.whl
/home/ana/wheels/jinja2-3.1.6-py3-none-any.whl:
--hash=sha256:85ece4451f492d0c13c5dd7c13a64681a86afae63a5f347908daf103ce6d2f67
```

A requirement written as `jinja2==3.1.6 --hash=sha256:85ec…` makes pip refuse any file whose
digest differs, and with `--require-hashes` it refuses any requirement that has no hash at all.
That protects against a tampered or swapped download, not against a flaw in the published release
itself: **an audit checks what was published, and a hash checks that you received it.**
