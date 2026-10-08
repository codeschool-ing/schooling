---
title: The workbench, and the one command every lesson uses
version: 1
---

Every command in this course runs in one directory, `~/guard`, on the machine the previous section
built. This section makes it. It holds three things:

- `tools/`, one small Python program per defence. **Each lesson prints the programs it uses, whole,
  the first time it uses them**, and says where to save them;
- `data/`, the files those programs read. Each lesson gives you its own, small enough to paste;
- `bin/guard`, one short script that runs a program from `tools/` by its name, so that the program
  saved as `tools/surface.py` is the command `guard surface`.

## The directory and the command

Paste this whole block into the terminal. The `cat` line opens a file, and the line `EOF` closes it:

```sh
mkdir -p ~/guard/bin ~/guard/tools ~/guard/data
cat > ~/guard/bin/guard <<'EOF'
#!/bin/sh
# guard NAME [ARGS...] runs ~/guard/tools/NAME.py, the program a lesson
# printed under that name, with the rest of the line as its arguments.
tool="$HOME/guard/tools/$1.py"
if [ ! -f "$tool" ]; then
  echo "guard: no tool named '$1' in ~/guard/tools" >&2
  exit 2
fi
shift
exec python3 "$tool" "$@"
EOF
chmod +x ~/guard/bin/guard
```

Then two lines at the end of `~/.bashrc`, so that every new terminal finds `guard`:

```sh
cat >> ~/.bashrc <<'EOF'
# ai-security
export PATH="$HOME/guard/bin:$PATH"
EOF
```

Open a new terminal after that. The one you typed it in still has the old `PATH`.

If you took the smaller model, or a provider's, its variables go under the same two lines, for
example `export ASK_MODEL=llama3.2:1b`.

## `ask`: a question to the model

Most lessons check text rather than produce it, and need no model. The few that do ask it through
one program. Open a new file, paste the program into it, save and quit. Any editor will do; `nano`
is on every Ubuntu, saves with Ctrl+O and quits with Ctrl+X:

```sh
nano ~/guard/tools/ask.py
```

```python
# ask.py: send one question to a language model and print the reply.
#
#   guard ask QUESTION [--system TEXT] [--temperature T] [--seed S] [--json]
#
# It speaks chat completions, the protocol Ollama serves on your own computer
# and most paid providers serve too. With nothing set it asks llama3.2:3b on
# this machine. Three variables point it elsewhere: ASK_URL, ASK_MODEL and
# ASK_KEY. Later tools import ask() from here rather than repeat it.
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

URL = os.environ.get("ASK_URL", "http://localhost:11434/v1")
MODEL = os.environ.get("ASK_MODEL", "llama3.2:3b")
KEY = os.environ.get("ASK_KEY", "")


def ask(question, system=None, temperature=0.0, seed=1, json_only=False):
    """The model's reply to QUESTION, as text."""
    messages = [{"role": "user", "content": question}]
    if system:
        messages.insert(0, {"role": "system", "content": system})
    body = {"model": MODEL, "messages": messages,
            "temperature": temperature, "seed": seed}
    if json_only:
        body["response_format"] = {"type": "json_object"}
    req = urllib.request.Request(URL + "/chat/completions",
                                 json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    if KEY:
        req.add_header("Authorization", "Bearer " + KEY)
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            reply = json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit("ask: %s answered %d: %s" % (URL, e.code, e.read().decode().strip()))
    except urllib.error.URLError as e:
        sys.exit("ask: cannot reach %s (%s). Is Ollama running?" % (URL, e.reason))
    return reply["choices"][0]["message"]["content"]


if __name__ == "__main__":
    p = argparse.ArgumentParser(prog="guard ask")
    p.add_argument("question")
    p.add_argument("--system")
    p.add_argument("--temperature", type=float, default=0.0)
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--json", action="store_true")
    a = p.parse_args()
    print(ask(a.question, a.system, a.temperature, a.seed, a.json))
```

`guard` finds it by name, so the program is now a command:

```
ana@lab:~/guard$ guard ask "Say hello in five words."
Hello from the digital world.
ana@lab:~/guard$ guard ask "Say hello in five words."
Hello from the digital world.
ana@lab:~/guard$ guard ask "Say hello in five words." --temperature 0.8 --seed 3
Hello there, it's nice to meet you.
ana@lab:~/guard$ guard ask "Say hello in five words." --temperature 0.8 --seed 4
Hello from the digital realm.
```

The first two runs gave the same words, and that is what `--temperature 0`, the default here, is
for: at every step the model takes its most likely word, so the same question gives the same reply.
The last two raise the temperature and change only the seed, which is the number the random draw
starts from, and the reply changes with it. A lesson that quotes a reply sets both, so that you can
see what it saw; `prompt-engineering` is the course about what those settings do.

The three variables are for the other paths of the previous section. `ASK_MODEL` names a different
model, such as `llama3.2:1b`. `ASK_URL` is the address of a provider's API, and `ASK_KEY` is your key
there; the provider's documentation gives both.

## How to read the transcripts

Every command in this course was run, and every line under it is what the command printed. A
transcript has the prompt `ana@lab:~/guard$` in front of each command: `ana` is the person, `lab` is
the machine, and yours prints your own names.

- What the programs in `tools/` print is the same on your machine, line for line, once you have saved
  the same programs and pasted the same data.
- **What the model replied was captured from `llama3.2:3b`, served by Ollama 0.40.0, on
  7 October 2026**, on a computer with no graphics card. Run the same command and you may get the same
  words, or different ones: a different processor does the arithmetic in a different order, and a
  newer version of the model writes something else. Even on the recording machine, at temperature 0,
  a few commands gave a different reply on a different run, and the lessons where that happened say so. That is not a sign something is wrong. Judge a
  reply by what the lesson checks in it, never by whether it matches this page.
