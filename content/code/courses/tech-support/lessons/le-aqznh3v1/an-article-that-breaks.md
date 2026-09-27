---
title: An article that breaks things
version: 1
---

Lesson 1 found a stale line in Carla's `/etc/hosts`, pointing `intranet` at an address where nothing
answers. It is worth asking where such a line comes from. The office's knowledge base:

```
ana@host:~$ ls kb; grep -rl intranet kb
intranet-on-a-new-computer.md
printing-from-a-new-computer.md
shared-folder-full.md
kb/intranet-on-a-new-computer.md
ana@host:~$ cat kb/intranet-on-a-new-computer.md
# Intranet on a new computer

Add the intranet to the hosts file:

    echo "10.30.0.200 intranet" | sudo tee -a /etc/hosts

Then open http://intranet/ in the browser.

Last reviewed: 2024-03-11
```

The article gives the old address, `10.30.0.200`, where the intranet lived when it was written. Anyone
setting up a computer by hand would follow it. Followed on `pc2`:

```
ana@pc2:~$ echo "10.30.0.200 intranet" | sudo tee -a /etc/hosts
10.30.0.200 intranet
ana@pc2:~$ curl -sS -m 10 http://intranet/
curl: (7) Failed to connect to intranet port 80 after 3094 ms: Couldn't connect to server
```

The same fault as lesson 1, **3094 milliseconds and nothing**, produced by following the team's own
documentation. That is the worst thing a KB can do: nobody suspects the article, because the article is
what they were told to trust. Lesson 1 fixed one computer; the article would have broken the next one.
