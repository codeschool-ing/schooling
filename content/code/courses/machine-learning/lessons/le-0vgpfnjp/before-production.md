---
title: What this server is not yet
version: 1
---

`app.py` answers correctly, checks its input, says which model it is and keeps a record of every
answer. It is still a server for one machine and one person, and it is worth knowing what stands between
it and a service the retention team relies on. None of this is machine learning, and all of it decides
whether the machine learning gets used.

- **It answers anybody who can reach it.** It listens on `127.0.0.1`, this machine only, which is what
  keeps it safe now. On a network it needs to know who is asking, and to refuse everybody else: the
  chances are personal data about named subscribers.
- **It runs as one process on one machine.** Uvicorn can run several workers, and a service usually
  runs several copies, on more than one machine, behind something that shares the requests out.
- **It stops when the terminal closes.** A real service is started by the system, restarted when it
  fails, and packaged with its versions so that the machine it runs on matches the card. Containers are
  the usual way, and `stored.load` refusing to start on the wrong versions is the same idea in one line.
- **Changing the model means stopping it.** `churn-2025-12` is written into the code. A service names
  the model it should load in its configuration, so that a new model can be put in place, and the old one
  put back, without changing a line.
- **`scores.jsonl` grows for ever, on one disk.** It is the most important file the server writes, and
  the next lesson is about why: it is the record of what the model said, and in a month it is set against
  what happened.

Each of those has tools and a discipline of its own, and **`ml-mlops` is the course about them**: model
registries, containers, scheduled retraining and the pipelines that run them. Every one of them assumes the part this lesson leaves in place: a model that is one object, a file that comes back
identical, a card that says what made it, a door that checks what comes in, and a test that the served
answers are the measured ones.

To stop the server, go to the second terminal and press **Ctrl+C**.
