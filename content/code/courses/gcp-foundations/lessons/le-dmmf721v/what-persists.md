---
title: What persists, and what does not
version: 1
---

**Your home directory persists; the machine does not.** Each session runs on a fresh machine from Google's
image, and your home directory, a small persistent disk of a few gigabytes, is attached to it. Everything you
save under `~` is there next time. Everything else, a package installed with `apt`, a file in `/tmp`, a
program left running, is gone when the session ends, because the machine it was on is gone.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l23-sessions\" aria-label=\"Three Cloud Shell sessions, Monday, Tuesday and Friday, each drawn as a separate machine started from Google's image. Each holds things that are lost when it ends: packages installed with apt, files in /tmp, running programs. Under all three, one home directory, a small persistent disk, is attached to each machine in turn and keeps what is saved in it, including .customize_environment, which is run as root at each start. A note says that after many weeks unused the home directory is deleted too.\"><rect x=\"20.0\" y=\"20.0\" width=\"210.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"125.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a fresh machine</text><text x=\"125.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Monday</text><text x=\"125.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">apt packages, /tmp,</text><text x=\"125.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">running programs: lost</text><path d=\"M125.0 122.0 L125.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"255.0\" y=\"20.0\" width=\"210.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a fresh machine</text><text x=\"360.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Tuesday</text><text x=\"360.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">apt packages, /tmp,</text><text x=\"360.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">running programs: lost</text><path d=\"M360.0 122.0 L360.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"490.0\" y=\"20.0\" width=\"210.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"595.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a fresh machine</text><text x=\"595.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Friday</text><text x=\"595.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">apt packages, /tmp,</text><text x=\"595.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">running programs: lost</text><path d=\"M595.0 122.0 L595.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20.0\" y=\"158.0\" width=\"680.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one home directory, attached to each in turn</text><text x=\"360.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">~/.bashrc · ~/.config/gcloud · ~/.customize_environment</text><text x=\"360.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kept between sessions; deleted after many weeks unused</text></svg>", "caption": "The machine is new every time; only the home directory comes back."}
```

| | survives the session |
|---|---|
| files in `~`, including `~/.bashrc` and `~/.config` | **yes** |
| gcloud's configurations, which live in `~/.config/gcloud` | **yes** |
| packages installed with `apt`, anything outside `~` | **no** |
| processes, including a server you started | **no** |
| the home directory itself, after many weeks unused | **no**: Google deletes it, after warning by e-mail |

That last row is the one people discover too late. **Cloud Shell's home is not a backup**: it is a scratch
space that happens to last, and anything that matters belongs in a repository or a bucket.

## Making it yours on every start

A file called `.customize_environment` in your home directory is run **as root, every time the machine
starts**, in the background. It is how a package the image lacks is there every session without being
installed by hand each time. The planner's engineers keep this one:

```sh
#!/bin/sh
# Run as root by Cloud Shell each time the machine starts.
apt-get update -qq
apt-get install -y -qq bind9-dnsutils jq
```

It is not run here: there is no Cloud Shell in this course to run it. On a real one, its output goes to a log
in `/var/log`, and a command typed before it has finished may not find what it installs yet.

## Would this course's lab fit?

A question worth answering with a measurement rather than a guess. What lesson 1 installed in the lab's home,
and everything the lessons since have written there:

```
ana@laptop:~/gcp$ cd ~ && du -sh .local gcp
1008M	.local
268M	gcp
```

About a gigabyte and a quarter, most of it the gcloud installation, which Cloud Shell already has. The lab would
fit in its home. What would not survive is the Java runtime the emulator needs, installed with `apt` outside
`~`, which is the kind of thing `.customize_environment` exists for. And the course still does not use it, for
lesson 1's reason.
