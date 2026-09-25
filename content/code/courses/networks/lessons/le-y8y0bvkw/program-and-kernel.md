---
title: Where the program stops and the kernel starts
version: 1
---

A program never builds a packet. It asks the kernel for a **socket**, an endpoint it can read from and
write to, and tells it where to connect. `strace` prints every request a program makes to the kernel,
and filtered to those two calls, `curl` fetching a page looks like this:

```
ana@laptop:~$ strace -f -e trace=socket,connect curl -s -o /dev/null http://www.example.com/
socket(AF_UNIX, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, 0) = 3
connect(3, {sa_family=AF_UNIX, sun_path="/var/run/nscd/socket"}, 110) = -1 ENOENT (No such file or directory)
socket(AF_UNIX, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, 0) = 3
connect(3, {sa_family=AF_UNIX, sun_path="/var/run/nscd/socket"}, 110) = -1 ENOENT (No such file or directory)
socket(AF_INET6, SOCK_DGRAM, IPPROTO_IP) = -1 EAFNOSUPPORT (Address family not supported by protocol)
strace: Process 25328 attached
[pid 25328] socket(AF_UNIX, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, 0) = 7
[pid 25328] connect(7, {sa_family=AF_UNIX, sun_path="/var/run/nscd/socket"}, 110) = -1 ENOENT (No such file or directory)
[pid 25328] socket(AF_UNIX, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, 0) = 7
[pid 25328] connect(7, {sa_family=AF_UNIX, sun_path="/var/run/nscd/socket"}, 110) = -1 ENOENT (No such file or directory)
[pid 25328] socket(AF_INET, SOCK_DGRAM|SOCK_CLOEXEC|SOCK_NONBLOCK, IPPROTO_IP) = 7
[pid 25328] connect(7, {sa_family=AF_INET, sin_port=htons(53), sin_addr=inet_addr("198.51.100.53")}, 16) = 0
[pid 25328] +++ exited with 0 +++
socket(AF_INET, SOCK_STREAM, IPPROTO_TCP) = 5
connect(5, {sa_family=AF_INET, sin_port=htons(80), sin_addr=inet_addr("192.0.2.80")}, 16) = -1 EINPROGRESS (Operation now in progress)
+++ exited with 0 +++
```

Read it in order:

1. Two `AF_UNIX` sockets try `/var/run/nscd/socket`, a local cache for name lookups, and get
   `ENOENT`: this machine does not run one, and the lookup carries on without it.
2. `socket(AF_INET6, …)` fails with `EAFNOSUPPORT`. **The lab machine has no IPv6 at all**, and this
   is where a program finds out.
3. **`SOCK_DGRAM` is UDP, and it goes to port 53 of `198.51.100.53`**: the DNS question, lesson 4's
   subject, asked in a thread of its own (`pid 25328`).
4. **`SOCK_STREAM` is TCP, and it goes to port 80 of `192.0.2.80`**: the web server, at the address
   the DNS answer gave. `EINPROGRESS` means the kernel has started the handshake and `curl` will be
   told when it finishes.

Everything the next sections look at happened below that last line, inside the kernel, without `curl`
knowing. The program named a destination address and port. **The kernel chose the source port**, from
a range it keeps for the purpose:

```
ana@laptop:~$ cat /proc/sys/net/ipv4/ip_local_port_range
32768   60999
```

A connection is those four numbers: source address and port, destination address and port. That is
how one laptop can hold two hundred connections to the same web server at once: each has its own
source port.
