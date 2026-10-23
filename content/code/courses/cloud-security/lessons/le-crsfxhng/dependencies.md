---
title: What the function carries, and how old it is
version: 1
---

**A function ships with its dependencies inside it, frozen at the moment it was packaged.** A server
gets its libraries upgraded when somebody upgrades the server. A function's zip file holds the
versions that were installed on the day it was built, and it goes on running them, unchanged, until
somebody builds it again. A function that works is a function nobody rebuilds, so its libraries age
in place.

The wrong belief is that "serverless" means the provider keeps the software current. Lambda patches
the runtime, meaning the operating system and the Python interpreter, for as long as that runtime is
supported (lesson 3 showed what happens after). **Everything your code imports is in your zip file,
and nobody patches it but you.**

## Asking which versions are known to be vulnerable

`pip-audit` reads a list of pinned Python packages and asks a public database of known
vulnerabilities about each version. It goes into a virtual environment of its own, `~/aws/tools`,
beside moto's and apart from it. Lesson 12 put Checkov in the same directory; if you have it, the
same two lines only add pip-audit to it:

```sh
python3 -m venv ~/aws/tools
~/aws/tools/bin/pip install -q pip-audit==2.10.1
```

The clinic's export function talks to the booking system over HTTP, and its requirements were
written when the function was, in 2018:

```sh
cat > requirements.txt <<'EOF'
requests==2.19.1
EOF
```

```
ana@laptop:~/aws$ ~/aws/tools/bin/pip-audit --version
pip-audit 2.10.1
ana@laptop:~/aws$ ~/aws/tools/bin/pip-audit --no-deps --disable-pip -r requirements.txt
WARNING:pip_audit._cli:--no-deps is supported, but users are encouraged to fully hash their pinned dependencies
WARNING:pip_audit._cli:Consider using a tool like `pip-compile`: https://pip-tools.readthedocs.io/en/latest/#using-hashes
Found 10 known vulnerabilities in 1 package
Name     Version ID              Fix Versions
-------- ------- --------------- ------------
requests 2.19.1  PYSEC-2018-28   2.20.0
requests 2.19.1  PYSEC-2018-28   2.20.0
requests 2.19.1  PYSEC-2023-74   2.31.0
requests 2.19.1  PYSEC-2023-74   2.31.0
requests 2.19.1  PYSEC-2026-1873 2.32.0
requests 2.19.1  PYSEC-2026-1872 2.32.4
requests 2.19.1  PYSEC-2026-2275 2.33.0
requests 2.19.1  PYSEC-2026-1873 2.32.0
requests 2.19.1  PYSEC-2026-1872 2.32.4
requests 2.19.1  PYSEC-2026-2275 2.33.0
```

`--no-deps` checks the versions written in the file and does not try to work out what they would
pull in, and `--disable-pip` lets it do that without installing anything. The two warnings above the
table are pip-audit's own advice: with every dependency pinned *and hashed*, what is audited is
provably what gets installed.

**Each row is a published advisory against `requests` 2.19.1, with the first version that fixes it.**
Some identifiers appear twice, which is how this version of pip-audit printed them. The table
is the answer on the day this lesson was recorded. **Run it next month and it may be longer**,
because the version did not change and the knowledge about it did, which is exactly why a scan is
repeated rather than passed once.

## Fixing it, and proving the fix

The fix is a newer pin. 2.34.2 was the newest release of `requests` when this lesson was recorded:

```
ana@laptop:~/aws$ sed -i 's/requests==2.19.1/requests==2.34.2/' requirements.txt
ana@laptop:~/aws$ ~/aws/tools/bin/pip-audit --no-deps --disable-pip -r requirements.txt
WARNING:pip_audit._cli:--no-deps is supported, but users are encouraged to fully hash their pinned dependencies
WARNING:pip_audit._cli:Consider using a tool like `pip-compile`: https://pip-tools.readthedocs.io/en/latest/#using-hashes
No known vulnerabilities found
```

A clean audit of the file is half the proof. The other half is that the zip file Lambda runs was
built from it: **a fixed `requirements.txt` beside an old deployment package fixes nothing**, so the
function is packaged again with the new versions inside, and deployed. On a real account,
`aws lambda get-function --function-name daily-export --query Configuration.LastModified` then says
when the code last changed, and a date older than the fix is a deployment that did not happen. That
query was not run here.

## What else is in the zip

Three habits that keep a function's contents small and known:

- **Package only what the handler imports.** A library that is not imported cannot be exploited
  through the function, and it is one less row in every future audit. A zip file built by copying
  a developer's whole virtual environment carries test tools, notebooks and their dependencies too.
- **Layers are dependencies too.** A Lambda layer is a zip file shared between functions, and a
  function that uses a layer runs whatever version of the layer it was published with. Audit the
  layer as you audit the function.
- **Rebuild on a schedule, not only on a change.** A function nobody touched for a year is the one
  carrying a year of advisories, so the build that packages it runs on a calendar as well.

::: track devsecops
The `secure-pipeline` course's lesson 5 put this same question into a pipeline, where a vulnerable
pin fails the build before the function is ever packaged. Lesson 14 of this course brings that gate
into the cloud deployment flow.
:::

::: track *
Running this audit by hand teaches what it says. It belongs in the build, where a vulnerable pin
stops the function before it is packaged, and lesson 14 of this course puts it there.
:::
