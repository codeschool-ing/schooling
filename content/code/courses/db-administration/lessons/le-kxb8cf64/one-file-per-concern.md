---
title: One file per concern, in git
version: 1
---

The cure for drift is a habit with two halves. **Every value a server needs is written in a file
kept somewhere other than the server**, and the server is made from that file rather than edited
by hand. The rest of this lesson builds both halves for the `shop` server: here, the file and the
repository it lives in; next, the script that puts it in place.

## Which file on the server

The tempting choice is `postgresql.conf` itself, since every parameter is already in it, commented
out at its default. **Leave it as Ubuntu wrote it.** It runs past eight hundred lines, and
`pg_createcluster` generates it for one major version. A value changed in the middle of it is one
line lost among eight hundred, in a file nobody can compare with the one the next version
generates. Near its end is the way out, which lesson 5 pointed at:

```
ana@db:~$ wc -l /etc/postgresql/16/main/postgresql.conf
828 /etc/postgresql/16/main/postgresql.conf
ana@db:~$ grep -n '^include_dir' /etc/postgresql/16/main/postgresql.conf
818:include_dir = 'conf.d'			# include files ending in '.conf' from
```

Every file in `/etc/postgresql/16/main/conf.d/` whose name ends in `.conf` is read after the main
file, **in the order of the file names**, and where two files set the same parameter the later
one wins. `postgresql.auto.conf` is read after all of them. So a team that divides the work names
its files to say who goes first: `10-memory.conf`, `20-logging.conf`, `90-local.conf` for the one
value that differs on one machine. The number is the order, which makes overriding a deliberate act
rather than an accident of `ls`.

This server is small enough for one file, and it says what the `shop` server changes and why:

```conf
# 50-shop.conf: what the shop's server sets differently from Ubuntu's
# defaults. provision.sh copies it into /etc/postgresql/16/main/conf.d/.
listen_addresses = '*'               # the application connects from 10.0.0.0/24
shared_buffers = 1GB                 # a quarter of a 4 GB machine (lesson 6)
work_mem = 16MB
maintenance_work_mem = 256MB
log_min_duration_statement = 500ms   # lesson 19
log_lock_waits = on
```

**The comments say why, never what.** `shared_buffers = 1GB` already says what; the reason is
lesson 6's arithmetic, and a year from now the reason is the part somebody needs before they
change the number. Two of these values take effect only when the server starts again, which the
next section's script has to deal with.

`pg_hba.conf` gets no file of its own. PostgreSQL 16 can include files from it, but Ubuntu's
does not, and in that file **the order of the lines is the meaning** — the first line that matches
a connection decides it, as lesson 5 showed. So the script will add one exact line, at the end,
where nothing above it matches the same connections.

## The original lives in git

The copy that counts is in a repository. On a team it lives on a Git server and the database
server never holds the only copy; for this lesson it lives in your home directory, in a directory
called `shop-db` with the file at `shop-db/conf.d/50-shop.conf`. Tell git who you are once, and
call the first branch `main`:

```sh
git config --global user.name "Ana"
git config --global user.email ana@example.com
git config --global init.defaultBranch main
```

Then make the directory, save the file into it with your editor, and commit:

```
ana@db:~$ mkdir -p shop-db/conf.d
ana@db:~$ git -C shop-db init
Initialized empty Git repository in /home/ana/shop-db/.git/
ana@db:~$ git -C shop-db add conf.d/50-shop.conf
ana@db:~$ git -C shop-db commit -m "The shop server's settings, one file"
[main (root-commit) cca080c] The shop server's settings, one file
 1 file changed, 8 insertions(+)
 create mode 100644 conf.d/50-shop.conf
```

`git -C shop-db` runs git as though you had changed into `shop-db` first. The hash after
`root-commit` will be a different one on your machine. From now on **the answer to "what is this server
set to, and since when, and why" is `git log`**, and the server is only a copy of it.

## The door this closes

`ALTER SYSTEM` still works, and in an emergency it is the fastest way to change a value without a
shell on the machine. One rule keeps it from becoming drift: **the value goes into the repository
the same day, and `ALTER SYSTEM RESET` takes it out of `postgresql.auto.conf`.** That file is read
last, so a value left there overrides every file in `conf.d`, including the one you just
committed. It goes on doing so long after everybody has forgotten it, exactly as `work_mem = 64MB`
did in the previous section.
