---
title: Your lab
version: 1
---

Every check in this course runs on a machine you control, against a service you wrote. **The
platform gives you no machine for it, and that is on purpose:** the scanners, the CI server, the
registry and the cluster are things a DevSecOps engineer sets up on the first day of any job, and
setting them up is part of what the course teaches. You build the lab once, here, and each later
lesson says what it adds to it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"sp-l01-lab\" aria-label=\"The lab this course builds on your own machine. You commit in ~/linkbox and push to ~/ci/linkbox.git, a bare repository whose post-receive hook runs the pushed commit's ci/pipeline.sh. Each run keeps its checkout and logs in ~/ci/runs/N and builds an image in Docker. Lesson 8 adds a registry on localhost:5000 and lesson 10 a kind cluster that pulls from it.\"><defs><marker id=\"sp-l01-lab-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l01-lab-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l01-lab-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your machine</text><rect x=\"30\" y=\"60\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/linkbox</text><text x=\"115.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the project</text><rect x=\"290\" y=\"60\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/ci/linkbox.git</text><text x=\"385.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hooks/post-receive</text><rect x=\"540\" y=\"60\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/ci/runs/N</text><text x=\"615.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one per run</text><path d=\"M200 88 L288 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-lab-ah-phosphor)\"></path><text x=\"244\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">git push</text><path d=\"M480 88 L538 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-lab-ah-paper-dim)\"></path><text x=\"385\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">clone + ci/pipeline.sh</text><rect x=\"290\" y=\"170\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Docker Engine</text><text x=\"385.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linkbox:&lt;commit&gt;</text><path d=\"M385 116 L385 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-lab-ah-paper-dim)\"></path><rect x=\"40\" y=\"250\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"140.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">registry</text><text x=\"140.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost:5000</text><rect x=\"480\" y=\"250\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"580.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">kind cluster</text><text x=\"580.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kubectl</text><text x=\"150\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">lesson 8</text><text x=\"580\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">lesson 10</text><path d=\"M320 220 L320 230 L140 230 L140 248\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l01-lab-ah-amber)\"></path><path d=\"M242 285 L478 285\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l01-lab-ah-amber)\"></path><text x=\"360\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">pulls</text></svg>", "caption": "Everything the course runs is on one machine: the project, a server that runs its pipeline, and Docker."}
```

### What it needs

**Docker, git, Python 3.11 or later, uv, curl and jq.** Everything else, the scanners included, is
installed by the lesson that first uses it, from the project's own release, with its checksum
checked. Nothing in the course needs an account anywhere, a cloud subscription or a card.

### Choose where it runs

| path | what you need | what it costs your computer |
|---|---|---|
| **on your own computer (recommended)** | Linux as it is; on Windows, WSL 2 with Ubuntu; on macOS, Docker Desktop or Colima | about 15 GB of disk for images and scanner databases; 8 GB of memory is comfortable, 4 GB works with one thing running at a time |
| in a virtual machine | VirtualBox, UTM or Hyper-V, and an Ubuntu 24.04 image | the same 15 GB inside the machine plus its own system, so give it 40 GB of disk, 4 GB of memory and 2 processors |
| online | a GitHub account and a Codespace on an empty repository of your own | nothing locally; a 4-core Codespace has Docker, and its free monthly hours are spent four times as fast as a 1-core one's |

**The first path is recommended** because Docker on Linux runs containers natively, and every
transcript in the course was recorded that way: Ubuntu 24.04, a user called `ana` on a machine
called `vm`. The virtual machine is for a computer whose owner does not allow installing Docker,
such as one managed by an employer. The online path works from a borrowed computer, and it depends
on one company's free allowance, which is a reason to keep your work in a repository you could
move elsewhere.

The heaviest single piece is the image of OWASP ZAP, the dynamic scanner of lesson 4, at 3.8 GB.
Lesson 10's cluster runs in containers too and is the next heaviest, and no lesson needs both
running at once.

### Docker

If Docker is not installed yet, `docker` lesson 5 does it step by step and says what each step is
for. On Ubuntu it is Docker's own package repository and five commands, which were not run in the
recording, because the machine already had Docker Engine:

```sh
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin
sudo usermod -aG docker $USER
```

The last line lets your user talk to Docker without `sudo`, and it takes effect at your next login.
Lesson 16 comes back to it, because being in that group is worth as much as being root on the
machine. git, curl and jq come from the distribution: `sudo apt-get install git curl jq`.

Check what you have. The `docker` group in the second answer is the one that matters:

```
ana@vm:~$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.9.1, server 29.9.1
ana@vm:~$ id -nG
ana docker
ana@vm:~$ git --version
git version 2.43.0
ana@vm:~$ python3 --version
Python 3.13.16
```

### uv

uv is a Python package and project manager, and the course uses it to make virtual environments and
install packages, because it is fast and because lesson 15 needs its lock files. Its own install
script lives on astral.sh; the release on GitHub, with its checksum, does the same thing and shows
each step:

```
ana@vm:~$ curl -fsSLO https://github.com/astral-sh/uv/releases/download/0.11.32/uv-x86_64-unknown-linux-gnu.tar.gz
ana@vm:~$ curl -fsSL https://github.com/astral-sh/uv/releases/download/0.11.32/uv-x86_64-unknown-linux-gnu.tar.gz.sha256 | sha256sum --check
uv-x86_64-unknown-linux-gnu.tar.gz: OK
ana@vm:~$ tar -xzf uv-x86_64-unknown-linux-gnu.tar.gz
ana@vm:~$ mkdir -p ~/.local/bin && install -m 755 uv-x86_64-unknown-linux-gnu/uv uv-x86_64-unknown-linux-gnu/uvx ~/.local/bin/
ana@vm:~$ rm -r uv-x86_64-unknown-linux-gnu*
ana@vm:~$ uv --version
uv 0.11.32 (x86_64-unknown-linux-gnu)
```

`~/.local/bin` is on the path of every Ubuntu login shell once the directory exists. If `uv
--version` answers `command not found`, log out and in again, or run `export
PATH=~/.local/bin:$PATH` in the shell you have.

The scanners of later lessons go in the same directory, the same way: the release, its checksum,
`install`. When a lesson says "install it", that is what it means, and it shows the commands.

### Who you are to git

Every commit records a name and an address. Set yours; the recording used Ana's:

```
ana@vm:~$ git config --global user.name "Ana Lima"
ana@vm:~$ git config --global user.email ana@example.org
ana@vm:~$ git config --global init.defaultBranch main
```

The third line makes `main` the name of the first branch of every new repository, which is the
name the CI server of this lesson's last steps expects.
