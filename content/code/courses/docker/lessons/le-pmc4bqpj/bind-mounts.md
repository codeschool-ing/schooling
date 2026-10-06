---
title: Bind mounts
version: 1
---

**A bind mount makes a directory of the host appear inside the container, the same directory, not
a copy.** A change on either side is the change on both, at once. That is what makes bind mounts
the tool for development, where you edit on the host and the container should see it, and also
what makes them easy to get wrong.

## Same files, both sides

Ana makes a small site directory, starts a container with it mounted on `/srv`, then edits the file
on the host while the container is running:

```
ana@vm:~$ mkdir site && echo "<h1>Opening hours</h1>" > site/index.html
ana@vm:~$ docker run -d --name web -v "$PWD/site":/srv alpine:3.22 sleep 3600
a4069892959733ac5270ac9422d2e9d29cb3f33205e62fff2bdd509a0ae1bd6f
ana@vm:~$ docker exec web cat /srv/index.html
<h1>Opening hours</h1>
ana@vm:~$ echo "<p>Mon-Fri 9-18</p>" >> site/index.html
ana@vm:~$ docker exec web cat /srv/index.html
<h1>Opening hours</h1>
<p>Mon-Fri 9-18</p>
```

The second `cat` shows the line she appended from the host, with no restart and no copy. The path
before the colon is the host's, and has to be absolute, which is why `"$PWD/site"` is written out
rather than `site`.

## Who owns what the container writes

A process in a container writes files as its own user, and lesson 1 showed that the kernel only
knows the number. Ana's container runs as root, so:

```
ana@vm:~$ docker exec web sh -c "echo generated > /srv/report.txt"
ana@vm:~$ ls -l site
total 8
-rw-r--r-- 1 ana  ana  43 Oct  6 13:42 index.html
-rw-rw-rw- 1 root root 10 Oct  6 13:42 report.txt
ana@vm:~$ rm site/report.txt
```

**`report.txt` belongs to `root` on the host**, in Ana's own directory. She could delete it here
because the directory is hers, but she cannot edit it, and on a CI machine the next job running as
an ordinary user fails to clean up the workspace. `--user` runs the container's process as Ana's
own user and group numbers instead:

```
ana@vm:~$ docker run --rm --user "$(id -u):$(id -g)" -v "$PWD/site":/srv alpine:3.22 sh -c "echo generated > /srv/report.txt"
ana@vm:~$ ls -l site
total 8
-rw-r--r-- 1 ana ana 43 Oct  6 13:42 index.html
-rw-r--r-- 1 ana ana 10 Oct  6 13:42 report.txt
```

Now the file is hers. **When a container writes into a bind mount, run it as the host user who
owns the directory**, or the files end up owned by whatever user the image runs as, which is root
unless lesson 14's advice was followed.

## A mount hides what was there

A bind mount is laid over the directory it lands on, and whatever the image had there becomes
invisible for as long as the mount is in place. Mounting the site over `/etc` makes the point
loudly:

```
ana@vm:~$ docker run --rm -v "$PWD/site":/etc alpine:3.22 ls /etc
hostname
hosts
index.html
report.txt
resolv.conf
```

Alpine's whole `/etc`, its users, its configuration, is gone from view; what is left are Ana's two
files and the three files Docker always places in `/etc` itself, lesson 4's host name and network
settings. Nothing in the image was changed, and a container without the mount sees all of it again.
The lesson is the quieter version of the same thing: mounting a source directory over the place a
Dockerfile installed dependencies hides those dependencies, and the program fails in a way that
looks like a broken image. Lesson 24 runs into it and works around it.

## Read-only when the container should only read

```
ana@vm:~$ docker run --rm -v "$PWD/site":/srv:ro alpine:3.22 sh -c "echo x >> /srv/index.html"
sh: can't create /srv/index.html: Read-only file system
```

`:ro` at the end makes the mount read-only inside the container, whatever the container's user is.
**Use it whenever the container has no business writing**: configuration files, certificates, a
directory of input data.
