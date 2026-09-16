---
title: `$EDITOR`, and the editor something else chose for you
version: 1
---

Half the time you open an editor, you did not open it — something opened it for
you and is waiting.

```sh
git commit          # a message
git rebase -i       # a plan
crontab -e          # a schedule (lesson 13)
visudo              # sudoers, with a syntax check on the way out
sudoedit /etc/x     # a root-owned file, edited as you
systemctl edit x    # a unit override
```

**Which editor those open is decided by two environment variables and a chain of
fallbacks**, and knowing the chain is the difference between a confident ten
seconds and a bad five minutes.

## The variables

```
ana@vm:~$ echo "EDITOR=[$EDITOR] VISUAL=[$VISUAL]"
EDITOR=[] VISUAL=[]
```

Neither is set here, which is the default on a fresh machine — and it is why
what happens next surprises people.

| | |
|---|---|
| `$VISUAL` | a **full-screen** editor. Checked first by most programs |
| `$EDITOR` | any editor, including a line editor like `ed` |

The distinction is from when some terminals could not do full-screen. Today they
are the same thing and **setting both to the same value is the honest move**.

## What happens when neither is set

```
ana@vm:~$ update-alternatives --display editor 2>&1 | head -6
editor - auto mode
  link best version is /bin/nano
  link currently points to /bin/nano
  link editor is /usr/bin/editor
  slave editor.1.gz is /usr/share/man/man1/editor.1.gz
  slave editor.da.1.gz is /usr/share/man/da/man1/editor.1.gz
```

On Debian and Ubuntu there is a `/usr/bin/editor`, managed by the alternatives
system from lesson 2 section 11, and **here it points at nano**. So an unset
`$EDITOR` on this machine gets you nano.

On Red Hat and SUSE there is no `editor` alternative and the fallback is
usually `vi`. Same command, different editor, depending on the distribution —
which is the argument for not relying on it.

`sudo update-alternatives --config editor` changes the machine's default
interactively.

## Setting it

```
ana@vm:~$ EDITOR=nano; export EDITOR; echo "EDITOR is now $EDITOR"
EDITOR is now nano
```

That lasts until the shell exits. For it to stick, it goes in your shell's
startup file — lesson 5 section 05:

```sh
# ~/.bashrc, or ~/.profile
export EDITOR=nano
export VISUAL=nano
```

**Set it deliberately, today, to whichever of the three you chose.** The day you
find out which editor `git commit` opens should not be the day you are in a
hurry with twelve staged files.

`git` has its own, which wins over both:

```sh
git config --global core.editor nano
```

## `visudo` and `sudoedit`, which are special

Two of the tools above do more than open a file, and both exist because editing
the file directly is dangerous.

**`visudo`** edits `/etc/sudoers` and **checks the syntax before installing it**.
Lesson 4 section 12's warning: a `sudoers` file with a syntax error can lock
every user out of `sudo` on that machine, and `visudo` refuses to install one.

It uses `$EDITOR` like anything else, and `sudo EDITOR=nano visudo` is the
spelling that gets you nano — because `sudo` strips the environment by default
(lesson 4 section 12), so exporting it in your own shell is not enough.

**`sudoedit`** — also spelled `sudo -e` — is the right way to edit a root-owned
file:

```sh
sudoedit /etc/hosts
```

It copies the file to a temporary one, runs **your** editor as **you** on the
copy, and then installs the result as root. Compare with `sudo vim /etc/hosts`,
which runs the whole editor as root, with your configuration and any plugins in
it, and with `:!sh` one keystroke away.

For a one-line change either works. `sudoedit` is the one that is correct.

## The chain, in full

Most programs check, in order:

1. the program's own setting — `core.editor` for git, `EDITOR` in `/etc/crontab`
2. `$VISUAL`
3. `$EDITOR`
4. a compiled-in default, or `/usr/bin/editor`, or `vi`

**Step 4 is why you should never reach it.** It is different on every
distribution and it is the one that produces the "how do I get out of this"
moment.

## Two habits

**Set `EDITOR` and `VISUAL` in your profile.** Two lines, once, on every machine
you use regularly.

**On a machine that is not yours, check before you commit to anything:**

```
ana@vm:~$ echo "${VISUAL:-${EDITOR:-nothing set}}"
nothing set
ana@vm:~$ which editor && readlink -f /usr/bin/editor
/usr/bin/editor
/usr/bin/nano
```

Two commands, and between them they tell you exactly what `git commit` is about
to open: nothing is set, so the fallback applies, and the fallback here resolves
to nano. The `${VISUAL:-${EDITOR:-…}}` is lesson 9 section 15's default-value
expansion, nested — and it is the same order of preference the programs
themselves use.