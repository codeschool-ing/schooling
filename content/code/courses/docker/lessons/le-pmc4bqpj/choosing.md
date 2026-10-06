---
title: Which one, when
version: 1
---

**The question that decides is who owns the files.** If the application owns them and nobody edits
them by hand, a named volume. If a person on the host owns them and the container should see that
person's edits, a bind mount. If nobody needs them after the container exits, `tmpfs`, which keeps
them in memory.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Three mounts into one container. On the left, the host: a named volume pgdata, kept by Docker under /var/lib/docker/volumes; a bind-mounted directory /home/ana/site, which Ana edits; and memory, for a tmpfs. On the right, the container sees them at /var/lib/postgresql/data, /srv and /scratch. The volume and the directory survive the container; the tmpfs does not.\"><defs><marker id=\"l8three-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l8three-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l8three-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"330\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the host</text><rect x=\"400\" y=\"10\" width=\"310\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"416\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">the container</text><rect x=\"26\" y=\"44\" width=\"298\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">named volume</text><text x=\"38\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/var/lib/docker/volumes/pgdata</text><text x=\"38\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Docker owns it · survives</text><rect x=\"420\" y=\"60\" width=\"270\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"434\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/var/lib/postgresql/data</text><path d=\"M326 74 L416 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8three-ah-phosphor)\"></path><rect x=\"26\" y=\"119\" width=\"298\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">bind mount</text><text x=\"38\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/home/ana/site</text><text x=\"38\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Ana owns it · survives</text><rect x=\"420\" y=\"135\" width=\"270\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"434\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/srv</text><path d=\"M326 149 L416 150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8three-ah-amber)\"></path><rect x=\"26\" y=\"194\" width=\"298\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tmpfs</text><text x=\"38\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">memory</text><text x=\"38\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gone when the container exits</text><rect x=\"420\" y=\"210\" width=\"270\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"434\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/scratch</text><path d=\"M326 224 L416 225\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8three-ah-wire)\"></path></svg>", "caption": "The three differ in who owns the files on the left. Docker owns the volume, Ana owns the directory, and nobody keeps the memory once the container exits."}
```

| | named volume | bind mount | tmpfs |
| --- | --- | --- | --- |
| where the data is | a directory Docker manages, under `/var/lib/docker/volumes` | any host directory you name | memory |
| who creates it | Docker, on first use or with `docker volume create` | you, before the container starts | Docker, when the container starts |
| survives the container | yes | yes, it is your directory | no |
| typical use | databases, uploads, anything the application owns | source code while developing, configuration files | scratch space, secrets that must not touch the disk |
| depends on the host's layout | no | yes, the path has to exist on every machine | no |

The last row matters more than it looks. A command with a bind mount works only on a machine with
that path, so it does not travel; a command with a named volume works anywhere Docker runs. That is
why production setups lean on volumes and development setups on bind mounts.

## Two ways to write it, and one difference

`-v` and `--mount` ask for the same mounts, in two syntaxes. `--mount` is longer and says
everything by name; `-v` is shorter and guesses. The guess shows when the host path does not exist:

```
ana@vm:~$ docker run --rm --mount type=bind,source="$PWD/missing",target=/srv alpine:3.22 true
docker: Error response from daemon: invalid mount config for type "bind": bind source path does not exist: /home/ana/missing

Run 'docker run --help' for more information
ana@vm:~$ docker run --rm -v "$PWD/missing":/srv alpine:3.22 true; ls -ld missing
drwxr-xr-x 2 root root 4096 Oct  6 13:42 missing
```

**`--mount` refuses a missing source; `-v` creates it**, as an empty directory owned by root, and
the container starts with nothing in it. A typo in a path then becomes a container that runs
happily against an empty directory, and a stray root-owned directory on the host. Prefer `--mount`
in scripts and anywhere a mistake should stop the run, and keep `-v` for typing at a prompt.

## tmpfs, for what should never reach a disk

```
ana@vm:~$ docker run --rm --tmpfs /scratch:size=16m alpine:3.22 sh -c "df -h /scratch; dd if=/dev/zero of=/scratch/big bs=1M count=32"
Filesystem                Size      Used Available Use% Mounted on
tmpfs                    16.0M         0     16.0M   0% /scratch
dd: error writing '/scratch/big': No space left on device
17+0 records in
16+0 records out
16777216 bytes (16.0MB) copied, 0.006519 seconds, 2.4GB/s
```

A `tmpfs` mount lives in memory and disappears with the container. The `size=16m` is a hard limit:
`dd` tried to write 32 MB and stopped at 16 with "No space left on device". Without a size, the
mount is offered half the host's memory:

```
ana@vm:~$ docker run --rm --tmpfs /scratch alpine:3.22 df -h /scratch
Filesystem                Size      Used Available Use% Mounted on
tmpfs                     7.9G         0      7.9G   0% /scratch
```

7.9G on a machine with 16 GB. Whatever a container writes there counts against its own memory limit
from lesson 4, so set a size. It suits files that are numerous and short-lived, and it suits files that
must not be left behind on disk, which is why lesson 21 mounts one for a read-only container's
temporary files.
