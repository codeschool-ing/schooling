---
title: `dpkg`, the layer that does exactly what you say
version: 1
---

`apt` is a program that decides what to do and then calls `dpkg` to do it. Everything in this
section is about using `dpkg` directly, which you will, because sooner or later somebody hands you
a `.deb`.

**`dpkg` has never heard of a repository.** It installs the file you give it and nothing else. That
is not a limitation to work around; it is the layering, and the whole of this section is one
demonstration of what it costs and how to hand the cost back.

## The failure, end to end

```
root@vm:~# cd /tmp && apt-get download cowsay
Get:1 http://archive.ubuntu.com/ubuntu noble/universe amd64 cowsay all 3.03+dfsg2-8 [18.6 kB]
Fetched 18.6 kB in 0s (39.3 kB/s)
root@vm:/tmp# ls *.deb
cowsay_3.03+dfsg2-8_all.deb
root@vm:/tmp# dpkg -i cowsay_3.03+dfsg2-8_all.deb
Selecting previously unselected package cowsay.
(Reading database ... 58861 files and directories currently installed.)
Preparing to unpack cowsay_3.03+dfsg2-8_all.deb ...
Unpacking cowsay (3.03+dfsg2-8) ...
dpkg: dependency problems prevent configuration of cowsay:
 cowsay depends on libtext-charwidth-perl; however:
  Package libtext-charwidth-perl is not installed.

dpkg: error processing package cowsay (--install):
 dependency problems - leaving unconfigured
Errors were encountered while processing:
 cowsay
```

Read it in the order it happened. **`Unpacking` succeeded** — the files are on the disk now.
**Configuring did not**, because the dependency from section 104 is missing. dpkg says so precisely,
names the package, and stops.

`apt-get download` is worth noticing on its own: it fetches a `.deb` into the current directory and
installs nothing. That is how you get a package file to inspect, to copy to a machine with no
network, or — as here — to break something on purpose.

## The state that results

```
root@vm:/tmp# dpkg -l cowsay | tail -1
iU  cowsay         3.03+dfsg2-8 all          configurable talking cow
```

**`iU`**, and the two letters are the two steps from section 106:

| | |
|---|---|
| `i` | **desired**: somebody wants this installed |
| `U` | **status**: unpacked, and not configured |

Section 107's legend spells this out every time `dpkg -l` runs, and this is the moment it earns its
three lines. **An uppercase second letter is bad**, which the legend also says.

## And half installed is not theoretical

```
root@vm:/tmp# cowsay hi
Can't locate Text/CharWidth.pm in @INC (you may need to install the Text::CharWidth module) (@INC en
tries checked: /etc/perl /usr/local/lib/x86_64-linux-gnu/perl/5.38.2 /usr/local/share/perl/5.38.2 /u
sr/lib/x86_64-linux-gnu/perl5/5.38 /usr/share/perl5 /usr/lib/x86_64-linux-gnu/perl-base /usr/lib/x86
_64-linux-gnu/perl/5.38 /usr/share/perl/5.38 /usr/local/lib/site_perl) at /usr/games/cowsay line 14.
BEGIN failed--compilation aborted at /usr/games/cowsay line 14.
```

**Four lines of perl, and not one of them says "package".** The command exists, it runs, and it
fails inside itself looking for a library that is not there.

That is the reason this section is worth the space. Met on its own — in a log, on somebody else's
machine, a week later — this error looks like a bug in `cowsay`. It is not. It is a package that
was never configured, and `dpkg -l` says so in two letters.

**When a program fails looking for something it should have, check the package state before you
check anything else.** It costs one command.

## The repair

```
root@vm:/tmp# apt-get -y -qq --fix-broken install
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package libtext-charwidth-perl:amd64.
(Reading database ... 58922 files and directories currently installed.)
Preparing to unpack .../libtext-charwidth-perl_0.04-11build3_amd64.deb ...
Unpacking libtext-charwidth-perl:amd64 (0.04-11build3) ...
Setting up libtext-charwidth-perl:amd64 (0.04-11build3) ...
Setting up cowsay (3.03+dfsg2-8) ...
root@vm:/tmp# dpkg -l cowsay | tail -1
ii  cowsay         3.03+dfsg2-8 all          configurable talking cow
root@vm:/tmp# cowsay hi
 ____
< hi >
 ----
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

**`apt-get --fix-broken install` — often written `apt-get -f install` — is the command to know.**
It looks at what is unconfigured, works out what is missing, fetches it, and then finishes the
configuration that was waiting. Two packages set up, `iU` becomes `ii`, and the program works.

There is a shorter way to avoid the whole thing:

```
apt install ./cowsay_3.03+dfsg2-8_all.deb
```

**A path with a `/` in it tells `apt` to install a local file** — with dependency resolution, from
the repositories, the way it does for anything else. The `./` is required; without it apt looks for
a package by that name.

**So: use `apt install ./file.deb` for a local package, and keep `dpkg -i` for when you mean it.**

## The rest of `dpkg`

```
dpkg -i file.deb           # install this file, and nothing else
dpkg -r thing              # remove, keeping configuration
dpkg -P thing              # purge
dpkg -l [pattern]          # what is installed, with status letters
dpkg -L thing              # files this package owns
dpkg -S /path/to/file      # which package owns this file
dpkg -c file.deb           # what is in this file, without installing
dpkg -I file.deb           # this file's metadata
dpkg --configure -a        # finish configuring everything that is half done
```

**`dpkg --configure -a` is the other repair**, and it is for a different cause: an install that was
interrupted — a reboot, a full disk, a `Ctrl+C` — leaving packages unpacked and unconfigured with
nothing actually missing. It retries the configuration step for all of them.

The rule of thumb between the two: **`--configure -a` when nothing is missing and something was
interrupted, `--fix-broken install` when something is missing.** Running the wrong one first is
harmless; it will tell you.

`rpm` is the same layer on the other family, with the same property — `rpm -i` does not resolve
dependencies either — and section 112 shows it refusing for exactly the same reason.
