---
title: `python -m pip`, and why not `pip`
version: 1
---

```sh
python -m pip install requests
python -m pip uninstall requests
python -m pip list
python -m pip show requests
python -m pip install --upgrade requests
```

**Write `python -m pip`, not `pip`.** They are the same program reached two ways, and the
difference is which interpreter it installs into.

`pip` is a small script with an interpreter path written into its first line, and the one your
shell finds is whichever came first on `PATH`. `python -m pip` runs the `pip` belonging to the
`python` you just ran — which is the environment you are in, by construction.

The failure this prevents is silent: the install succeeds, reports success, and the import fails
because the library went somewhere else.

## `list` and `show`

```sh
$ python -m pip list
Package            Version
------------------ ---------
certifi            2026.7.22
charset-normalizer 3.5.1
idna               3.20
requests           2.31.0
urllib3            2.8.0
```

Five packages after installing one. The other four are what `requests` needs, and this is the
first sight of the distinction the next two sections are about.

```sh
$ python -m pip show requests
Location: /tmp/project/.venv/lib/python3.11/site-packages
Requires: certifi, charset-normalizer, idna, urllib3
Required-by:
```

`Location` is where it actually landed, and it is the first thing to look at when an import finds
the wrong copy. `Requires` and `Required-by` are the two directions of the dependency graph;
`Required-by` being empty is how you know `requests` is something you asked for rather than
something that came along.

## `uninstall` removes one thing

```sh
python -m pip uninstall requests
```

It removes `requests` and leaves `certifi`, `idna`, `charset-normalizer` and `urllib3` behind. It
has no concept of "no longer needed", so an environment that has been installed into and
uninstalled from for a year holds a layer of things nothing uses.

That is one of the arguments for the tools in the next lesson, and in the meantime the answer is
the one above: delete the directory and rebuild it.

## `--upgrade` and what it decides

```sh
python -m pip install --upgrade requests
```

Without it, `install` on something already present does nothing. With it, `pip` takes the newest
version that satisfies the specifier — and it may upgrade the four other packages too, because
their versions have to satisfy what the new `requests` asks for.

There is no "upgrade everything" command, deliberately. `pip list --outdated` tells you what has
moved, and you decide.
