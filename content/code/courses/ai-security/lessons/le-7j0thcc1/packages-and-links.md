---
title: Names that do not exist yet
version: 1
---

The most direct way a hallucination becomes an attack is through a name. A model asked to write code
suggests a package to install, and sometimes the package it names has never been published. The
suggestion looks exactly like a real one. **A name nobody owns is a name anybody can register**, and if
a model keeps suggesting the same invented name, whoever registers it first decides what the next
developer who trusts the suggestion installs. Researchers have measured models inventing package
names at a noticeable rate, and the trick of registering them has its own nickname, *slopsquatting*.

The defence is the same as for links in lesson 19: **a name a model produced is checked against a
list you trust before anything acts on it.** In the lab, a model's suggestions for a Pix QR code
feature are in `data/suggested-deps.txt`, written by the course, and `data/registry-snapshot.txt` is a
short stand-in for the packages Tarefa has already reviewed:

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

Two names are not in the snapshot. The lab does not say whether they exist on the public index,
because that is not the question that protects Tarefa: a name that exists is not therefore the package
the model meant, and the safe outcome is the same either way. **A person looks the package up**, reads
who publishes it, how long it has existed and how widely it is used, and adds it to the reviewed list
or does not install it.

Three habits make this hold in a team:

- **Install from the reviewed list, with versions pinned and hashes checked**, so that a new name
  needs a decision and a known name cannot change under you.
- **Treat a package name in a model's code as untrusted input**, the same as a URL in its reply.
- **Watch for the same invented name recurring.** A suggestion that is wrong once is noise; one that is
  wrong the same way for many developers is the name somebody will register.

## Links are names too

Lesson 19's `out-6` linked to `pay-tarefa.example`, a host that looked like Tarefa's. A model that
invents a plausible link produces the same risk as one that invents a package: a name that somebody
else can own. The host allowlist of lesson 19 is the same defence as the registry snapshot here, one
for the client's browser and one for the developer's machine.
