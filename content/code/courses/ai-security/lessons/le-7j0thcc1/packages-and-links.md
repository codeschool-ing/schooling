---
title: Names that do not exist yet
version: 2
---

The most direct way a hallucination becomes an attack is through a name. A model asked to write code
suggests a package to install, and sometimes the package it names has never been published. The
suggestion looks exactly like a real one. **A name nobody owns is a name anybody can register**, and if
a model keeps suggesting the same invented name, whoever registers it first decides what the next
developer who trusts the suggestion installs. Researchers have measured models inventing package
names at a noticeable rate, and the trick of registering them has its own nickname, *slopsquatting*.

The defence is the same as for links in lesson 9: **a name a model produced is checked against a
list you trust before anything acts on it.** Two files, both written by the course: the packages a model
might suggest for a Pix QR code feature, and a short stand-in for the packages Tarefa has already
reviewed:

```sh
cat > ~/guard/data/suggested-deps.txt <<'EOF'
requests
python-dateutil
pix-qrcode-br
qrcode
brazil-cpf-validator-pro
EOF
cat > ~/guard/data/registry-snapshot.txt <<'EOF'
django
fastjsonschema
flask
httpx
numpy
pandas
pillow
pydantic
python-dateutil
qrcode
requests
validate-docbr
EOF
```

The check is a set lookup. Save it as `~/guard/tools/deps.py`:

```python
# deps.py: suggested packages against the list Tarefa has already reviewed.
#
#   guard deps FILE
#
# FILE has package names, one or more per line; a leading `pip install` is
# ignored, so a model's reply can be checked as it came. Every name not in
# data/registry-snapshot.txt is printed as one not to install, and the exit
# status is 1 if there is any.
import os
import sys

with open(os.path.expanduser("~/guard/data/registry-snapshot.txt")) as f:
    reviewed = {line.strip().lower() for line in f if line.strip()}

names = []
with open(sys.argv[1]) as f:
    for line in f:
        words = line.split()
        if words[:2] == ["pip", "install"]:
            words = words[2:]
        names += words

missing = 0
for name in names:
    known = name.lower() in reviewed
    missing += not known
    print("%-26s %s" % (name, "in the snapshot" if known
                        else "NOT IN THE SNAPSHOT: do not install"))
sys.exit(1 if missing else 0)
```

```
ana@lab:~/guard$ cat data/suggested-deps.txt
requests
python-dateutil
pix-qrcode-br
qrcode
brazil-cpf-validator-pro
ana@lab:~/guard$ guard deps data/suggested-deps.txt; echo "exit $?"
requests                   in the snapshot
python-dateutil            in the snapshot
pix-qrcode-br              NOT IN THE SNAPSHOT: do not install
qrcode                     in the snapshot
brazil-cpf-validator-pro   NOT IN THE SNAPSHOT: do not install
exit 1
```

Two names are not in the snapshot. The check does not say whether they exist on the public index,
because that is not the question that protects Tarefa: a name that exists is not therefore the package
the model meant, and the safe outcome is the same either way. **A person looks the package up**, reads
who publishes it, how long it has existed and how widely it is used, and adds it to the reviewed list
or does not install it.

## What the model actually suggested

The list above was written to show the check. Ask the real model the same kind of question, and keep
its reply as it came:

```
ana@lab:~/guard$ guard ask "Which Python packages would I install to generate a Pix QR code for a Brazilian payment, and to validate a CPF? Reply with package names only, one per line, nothing else." > data/model-deps.txt
ana@lab:~/guard$ cat data/model-deps.txt
pip install qrcode
pip install pyzbar
pip install python-cpf
ana@lab:~/guard$ guard deps data/model-deps.txt; echo "exit $?"
qrcode                     in the snapshot
pyzbar                     NOT IN THE SNAPSHOT: do not install
python-cpf                 NOT IN THE SNAPSHOT: do not install
exit 1
ana@lab:~/guard$ guard ask "Which Python packages would I install to generate a Pix QR code for a Brazilian payment, and to validate a CPF? Reply with package names only, one per line, nothing else." --temperature 0.8 --seed 2
pip install python-qrcode
pip install py-cpf
```

It was asked for names only and answered with install commands, which is why `deps.py` ignores a
leading `pip install`: a check that reads a model's output has to read it as it comes, not as it was
asked for. `qrcode` is a real package, and Tarefa has reviewed it. `pyzbar` and `python-cpf` are not on
the reviewed list, and the check stops them there. Whether a package by each name exists on the public
index today, and who published it, is exactly what the person reviewing it finds out. (`pyzbar` reads
QR codes rather than making them, which is a second question for the same person.)

The model gave all three names with the same confidence, which is the whole problem: nothing in the reply
marks which name is which. The last run, at temperature 0.8, named two other packages, neither of them
on the reviewed list. A list of what one run suggested is no substitute for checking every run.

Three habits make this hold in a team:

- **Install from the reviewed list, with versions pinned and hashes checked**, so that a new name
  needs a decision and a known name cannot change under you.
- **Treat a package name in a model's code as untrusted input**, the same as a URL in its reply.
- **Watch for the same invented name recurring.** A suggestion that is wrong once is noise; one that is
  wrong the same way for many developers is the name somebody will register.

## Links are names too

Lesson 9's `out-6` linked to `pay-tarefa.example`, a host that looked like Tarefa's. A model that
invents a plausible link produces the same risk as one that invents a package: a name that somebody
else can own. The host allowlist of lesson 9 is the same defence as the registry snapshot here, one
for the client's browser and one for the developer's machine.
