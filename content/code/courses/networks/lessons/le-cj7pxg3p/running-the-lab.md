---
title: Building the lab and walking into it
version: 1
---

Before the first build, check that the four files arrived whole. A paste that stopped early is the
most common way this goes wrong, and it is easy to see in the line counts. The checksums go
further: if yours match these, your files are the bytes this course ran.

```
ubuntu@netlab:~$ wc -l ~/netlab/*
  172 /home/ubuntu/netlab/dns.sh
  262 /home/ubuntu/netlab/netlab
  202 /home/ubuntu/netlab/services.sh
  137 /home/ubuntu/netlab/web.sh
  773 total
ubuntu@netlab:~$ sha256sum ~/netlab/*
daf483d8acf2d462d38865bdca7bbb5c58d06a712cb5a1a0f1a74e3cb1fbcfa3  /home/ubuntu/netlab/dns.sh
7db7f1e9c08a4d7e9ae56a5ad210fffb62b4df31b33b99b2736403e5391b685c  /home/ubuntu/netlab/netlab
3ceccc37953adaac60fce0cc4b4216f1392cb969c2ed4dba7db8c34d01cdeca6  /home/ubuntu/netlab/services.sh
7e8aecfb9c0a408b30171beea77bc2f941bb7e312ac036f9cea29da7e0731309  /home/ubuntu/netlab/web.sh
```

Now build it. **`up` prints nothing when it works**, and takes about ten seconds. Then `shell`
opens a shell on one of the machines, as `ana`, the office's support technician:

```
ubuntu@netlab:~$ sudo bash ~/netlab/netlab up
ubuntu@netlab:~$ sudo bash ~/netlab/netlab shell laptop
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ana@laptop:~$ hostname
laptop
ana@laptop:~$ ip -br addr
lo               UNKNOWN        127.0.0.1/8 
eth0@if424       UP             192.168.10.20/24 
ana@laptop:~$ curl -sI https://www.example.com/ | head -1
HTTP/2 200 
ana@laptop:~$ exit
exit
ubuntu@netlab:~$ sudo bash ~/netlab/netlab exec router root 'ip route'
default via 203.0.113.1 dev eth1 
192.168.10.0/24 dev eth0 proto kernel scope link src 192.168.10.1 
203.0.113.0/24 dev eth1 proto kernel scope link src 203.0.113.2 
```

Read the prompts, because they say where each command ran. `ubuntu@netlab` is your virtual
machine. `sudo bash ~/netlab/netlab shell laptop` changed the prompt to **`ana@laptop`**: from
there on, every command runs on the laptop, with the laptop's address and the laptop's view of the
network, until `exit` brings you back. The two lines about `sudo` are Ubuntu's greeting for a new
account, and they appear once. The last command shows the other form: **`exec` runs one command
on one machine and comes back**, here as `root` on the router.

From now on, a transcript that starts with `ana@laptop:~$` means "in a shell on `laptop`", and one
that starts with `ana@www:~$` means a shell on `www`. When a transcript shows a command running on
one machine while another machine does something, open a second terminal on your computer with
`multipass shell netlab` and start a second machine's shell there. When `sudo` inside the lab asks
for a password, it is `ana`'s, `office-2026`; the transcripts do not show the question because it is
asked on the terminal and not printed to the output.

Four commands are all the lab needs:

| command | what it does |
|---|---|
| `sudo bash ~/netlab/netlab up` | builds the lab; does nothing if it is already up |
| `sudo bash ~/netlab/netlab reset` | tears it down and builds it again, with every fault gone |
| `sudo bash ~/netlab/netlab down` | tears it down |
| `sudo bash ~/netlab/netlab shell HOST` | a shell on one machine; add `root` after the name to be root there |

**The lab lives in memory and does not survive a restart** of the virtual machine. After one, run
`up` again. And when a lesson has broken something on purpose, as several do, `reset` is the way
back to the network in the drawing. Some lessons set up a fault before you look at it, a route
removed or a server stopped; each one says what to type to set it up yourself.
