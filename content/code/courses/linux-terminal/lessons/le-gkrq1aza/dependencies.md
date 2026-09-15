---
title: Dependencies, and the four ways they go wrong
version: 1
---

A package declares what it needs. The manager reads every declaration on the machine, plus every
one in the repositories, and solves for a set that satisfies all of them at once.

**That is a genuine constraint-solving problem**, which is why it sometimes says something long and
strange instead of just doing what you asked.

## The relationships

| | |
|---|---|
| `Depends` | must be installed, and configured first |
| `Pre-Depends` | must be **configured** before this one is even unpacked |
| `Recommends` | installed by default; safe to refuse |
| `Suggests` | never installed automatically |
| `Conflicts` | cannot be installed at the same time as this |
| `Replaces` | takes over files that used to belong to another package |
| `Provides` | a virtual name, so several packages can satisfy one requirement |

**`Provides` is the one worth understanding**, because it explains an answer that otherwise looks
wrong. `cowsay` depends on `perl:any`, and several packages provide `perl`. A dependency can name a
capability rather than a package, and the solver picks something that offers it.

On the rpm side the same idea goes further: a package can `Requires: /bin/sh` — **a file path, not
a package** — and any package that ships that file satisfies it.

## Seeing them before you commit

```
apt show thing                     # the Depends line
apt-cache depends thing            # what it needs, one per line
apt-cache rdepends thing           # what needs it — the reverse question
apt install --dry-run thing        # the whole plan, without doing any of it
```

**`--dry-run` is the habit worth forming.** It prints exactly the paragraph section 106 taught you
to read, and changes nothing. On a production machine it is the difference between knowing and
finding out.

`rdepends` — reverse dependencies — answers "what breaks if I remove this", which is the question
you want before typing `apt remove` on a library.

## The four failures

### 1. Half installed

You used `dpkg -i` and the dependency was not there. dpkg unpacks and refuses to configure,
leaving the package in a state where its files exist and it does not work. Section 109 is this one
in full, with the repair.

### 2. Held back

```
0 upgraded, 2 newly installed, 0 to remove and 168 not upgraded.
```

**`not upgraded` means apt decided not to.** Usually because upgrading one thing would require
removing another, and plain `upgrade` refuses to remove. `apt list --upgradable` names them and
`apt full-upgrade` is allowed to do it — after you have read what it would take away.

The other reason is a deliberate hold, which is section 111.

### 3. Unmet dependencies

```
The following packages have unmet dependencies:
 somepackage : Depends: libsomething (>= 2.0) but 1.9 is to be installed
```

This is the solver telling you there is no valid answer. **Read the version constraint**, because
it names the problem: something wants a newer library than the repositories offer. That normally
means a package from one release was installed on another — a `.deb` for a newer Ubuntu, or a
third-party repository that assumed a different base.

`apt --fix-broken install` fixes the version of this that came from an interrupted install. It
cannot fix the version that comes from genuinely incompatible sources, and the honest repair there
is to remove the package that does not belong.

### 4. The dependency nobody wants any more

```
The following package was automatically installed and is no longer required:
  libtext-charwidth-perl
Use 'apt autoremove' to remove it.
```

apt records **why** each package is there: because you asked, or because something else needed it.
Remove the thing that needed it and the dependency stays, marked as unwanted, until `autoremove`.

```
apt-mark showmanual        # what you asked for
apt-mark showauto          # what came in as a dependency
apt-mark manual thing      # "I want this even if nothing needs it"
```

**`apt-mark manual` is the fix for a specific accident**: you installed A, which pulled in B, you
came to rely on B directly, and then you removed A. Marking B manual stops the next `autoremove`
taking it.

## Removing removes more than you asked

This is the behaviour to know before you type `remove` on a library, and both families do it:

```
root@vm:~# dpkg -l cowsay libtext-charwidth-perl | tail -2
ii  cowsay                       3.03+dfsg2-8  all          configurable talking cow
ii  libtext-charwidth-perl:amd64 0.04-11build3 amd64        get display widths of characters on the
terminal
root@vm:~# apt-get remove --dry-run libtext-charwidth-perl
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages will be REMOVED:
  cowsay libtext-charwidth-perl
0 upgraded, 0 newly installed, 2 to remove and 168 not upgraded.
Remv cowsay [3.03+dfsg2-8]
Remv libtext-charwidth-perl [0.04-11build3]
```

**I asked for one package and the plan removes two.** `cowsay` depends on it, so taking the library
away means taking `cowsay` too — a manager will not knowingly leave a package whose `Depends` is
unsatisfied. Section 112 shows `dnf` doing the same thing with the same reasoning.

`--dry-run` is why this is a paragraph rather than an incident. And `rdepends` is how you ask before
you even type `remove`:

```
root@vm:~# apt-cache rdepends libtext-charwidth-perl
libtext-charwidth-perl
Reverse Depends:
  debconf-i18n
  cowsay
  libtext-wrapi18n-perl
```

Three packages depend on it and only one of them is installed, which is why the plan removed one
and not three. **`rdepends` lists everything in the repositories**, installed or not — so read it as
"who could care", and use `--dry-run` for "what would actually happen here".
