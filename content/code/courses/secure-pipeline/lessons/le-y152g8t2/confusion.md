---
title: Dependency confusion and typosquatting, from the defender's side
version: 1
---

Two of the incidents in this lesson needed no break-in at all. Nobody stole an account or touched a
build server: somebody published a package under a name, and the victims' own tools chose to install
it. **The flaw was in how the installer picks a package, and the defence is in the same place.**

### Dependency confusion

A company with private packages usually serves them from an index of its own, and points its
installers at both that index and the public one. The trap is in the word "both". **pip treats every
index it is given as one pool of candidates and installs the highest version it finds**, wherever it
found it. If a private package's name is free on PyPI, anybody can register it there with a high
version number, and every installer pointed at both indexes prefers it. That is how `torchtriton`
reached PyTorch's nightly users: the name existed on PyTorch's index and nobody had claimed it on
PyPI.

You can watch the rule on your own machine without anybody publishing anything. A name that already
exists on PyPI behaves exactly as yours would on the day somebody registers it, so take `packaging`
and make a version 0.1 of your own, the way an internal package would be made. Two files are enough.
Save the first as `~/supply/internal/pyproject.toml`:

```toml
[project]
name = "packaging"
version = "0.1"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

And the module itself, which only has to exist, as `~/supply/internal/src/packaging/__init__.py`:

```python
"""Our own packaging, version 0.1, on our own index."""
```

Build the wheel into a directory laid out as an index, one directory per package under `simple/`,
and serve it on `127.0.0.1:8081` with `python3 -m http.server 8081 --bind 127.0.0.1 --directory
index` in a second terminal. pip reads a plain directory listing as an index.

```
(supply) ana@vm:~/supply$ uv build -q --wheel -o index/simple/packaging/ internal
(supply) ana@vm:~/supply$ ls index/simple/packaging
packaging-0.1-py2.py3-none-any.whl
```

Point pip at your index **alone**, with `--index-url`, and it can only find your package:

```
(supply) ana@vm:~/supply$ pip download --no-deps -d got --index-url http://127.0.0.1:8081/simple/ packaging
Looking in indexes: http://127.0.0.1:8081/simple/
Collecting packaging
  Downloading packaging-0.1-py2.py3-none-any.whl (942 bytes)
Saved ./got/packaging-0.1-py2.py3-none-any.whl
Successfully downloaded packaging
```

Now the arrangement most teams actually write, the private index **added** to PyPI with
`--extra-index-url`:

```
(supply) ana@vm:~/supply$ pip download --no-deps -d got --extra-index-url http://127.0.0.1:8081/simple/ packaging
Looking in indexes: https://pypi.org/simple, http://127.0.0.1:8081/simple/
Collecting packaging
  Downloading packaging-26.3-py3-none-any.whl.metadata (3.5 kB)
Downloading packaging-26.3-py3-none-any.whl (129 kB)
Saved ./got/packaging-26.3-py3-none-any.whl
Successfully downloaded packaging
(supply) ana@vm:~/supply$ ls got
packaging-0.1-py2.py3-none-any.whl
packaging-26.3-py3-none-any.whl
```

pip looked in both, found 0.1 in yours and 26.3 on PyPI, and took 26.3. Here 26.3 is the real
`packaging` and harmless; on the day the higher version is somebody else's, it is the same decision.
**Nothing in the output warns you**, because nothing went wrong from pip's point of view.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"sp-l12-confusion\" aria-label=\"Two indexes offer a package named packaging: your own index has version 0.1 and PyPI has 26.3. pip with --extra-index-url puts both in one pool and installs the highest version, 26.3 from PyPI. uv by default stops at the first index that has the name, your own, and installs 0.1. With --index-url and one index, there is nothing to choose between.\"><defs><marker id=\"sp-l12-confusion-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l12-confusion-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l12-confusion-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">your index</text><text x=\"105.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">packaging 0.1</text><rect x=\"20\" y=\"130\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PyPI</text><text x=\"105.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">packaging 26.3</text><rect x=\"280\" y=\"30\" width=\"220\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pip --extra-index-url</text><text x=\"390.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one pool, highest version wins</text><rect x=\"280\" y=\"130\" width=\"220\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">uv, by default</text><text x=\"390.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">first index that has the name</text><path d=\"M190 58 L278 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l12-confusion-ah-paper-dim)\"></path><path d=\"M190 158 L278 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l12-confusion-ah-paper-dim)\"></path><path d=\"M190 58 L278 150\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l12-confusion-ah-phosphor)\"></path><rect x=\"570\" y=\"30\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">installs</text><text x=\"635.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">26.3</text><rect x=\"570\" y=\"130\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">installs</text><text x=\"635.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.1</text><path d=\"M500 58 L568 58\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-confusion-ah-amber)\"></path><path d=\"M500 158 L568 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-confusion-ah-phosphor)\"></path></svg>", "caption": "The same two indexes, two rules. Under pip's, whoever publishes the higher version wins."}
```

uv, which this course uses everywhere else, decided the other way by default. It stops at the first
index that has the package, and it puts the extra index before PyPI:

```
(supply) ana@vm:~/supply$ uv pip install --dry-run --extra-index-url http://127.0.0.1:8081/simple/ packaging
Resolved 1 package in 17ms
Would download 1 package
Would install 1 package
 + packaging==0.1
(supply) ana@vm:~/supply$ uv pip install --dry-run --index-strategy unsafe-best-match --extra-index-url http://127.0.0.1:8081/simple/ packaging
Resolved 1 package in 6ms
Would install 1 package
 + packaging==26.3
```

`--index-strategy unsafe-best-match` restores pip's behaviour, and the name says what uv thinks of
it.

### The defences, in order of strength

- **One index.** Installers point at a single index the company controls, which proxies PyPI and
  serves the private packages, and decides in one place which name comes from where. Products such as
  Artifactory, Nexus and devpi do this. `--index-url` to that index and nothing else.
- **Hashes.** A lock with the hash of every file refuses a file that is not the one reviewed,
  whichever index offers it. The previous section showed pip doing it.
- **Claim your names.** Register each internal name on the public index as an empty placeholder, as
  PyTorch did for the name it moved its dependency to after the incident. It closes the door for those names and no
  others.
- **A resolver that does not mix indexes**, like uv's default, or a scope or namespace where the
  ecosystem has one, such as npm's `@company/` scopes.

### Typosquatting

Typosquatting relies on a person instead of a resolver: a package named one keystroke away from a
popular one, waiting for somebody to type the name wrong once, in a terminal or in a requirements
file. SLSA puts it at its letter H, the choice of package. **A typo in a requirements file is a
dependency nobody chose**, and the defences are about making the choice visible:

- a new dependency arrives in a pull request, where the lockfile's diff shows the exact name, and a
  reviewer reads it as carefully as code;
- copy the install command from the project's own documentation rather than typing it;
- a name that is new to the project gets a look at its page on the index: who publishes it, since
  when, how many depend on it. Lesson 15 makes that reading a habit.

Neither confusion nor typosquatting needs a vulnerability in your code. Both need only that a name
reaches your installer, and both are stopped before the first byte of the package runs.
