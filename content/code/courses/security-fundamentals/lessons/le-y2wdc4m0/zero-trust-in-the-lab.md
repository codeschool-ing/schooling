---
title: The same requests, two policies
version: 1
---

The lab's portal can run the staff handbook under either of two policies, chosen by a file on the
server. This section runs the same requests under both. Everything else stays the same, including
the firewall, which is left open so that the only thing compared is the portal's own policy.

### Trust by location

The first policy is the one lesson 5's warning was about: any request from the office network gets
the handbook, and nothing else does.

```
root@www:~# cat /srv/portal/mode
perimeter
ana@laptop:~$ curl -s http://www.example.com/handbook
staff handbook: page 1 of 40
ana@outside:~$ curl -s http://www.example.com/handbook
only from the office network
ana@outside:~$ curl -s -u ana:lab-ana-pass http://www.example.com/handbook
only from the office network
```

The laptop in the office gets the handbook without being asked anything. The machine on the internet
is refused, which looks right, until the last line: **ana, with her correct password, is refused
too.** The portal never looked at the password, because the policy does not ask who you are. It asks
where you are.

Read both results together and the problem is plain. Anything on the office network, a visitor's
phone, an infected laptop, a compromised printer, gets what ana gets. ana at home gets nothing.

### Every request proves who it is

Now the administrator switches the policy:

```
root@www:~# echo zerotrust > /srv/portal/mode
```

and the same requests run again:

```
ana@laptop:~$ curl -s http://www.example.com/handbook
sign in first
ana@laptop:~$ curl -s -u ana:lab-ana-pass http://www.example.com/handbook
staff handbook: page 1 of 40
ana@outside:~$ curl -s -u ana:lab-ana-pass http://www.example.com/handbook
staff handbook: page 1 of 40
```

The laptop in the office, asking with nothing, is told to sign in, exactly as a stranger would be.
With ana's password it gets the handbook. From the internet, with the same password, it gets the
same handbook. **The answer now depends on who is asking, and not on where.**

The portal's log shows the change from the defender's side:

```
root@www:~# cat /var/log/lab/portal.log
192.168.10.20 - "GET /handbook HTTP/1.1" 200 -
203.0.113.50 - "GET /handbook HTTP/1.1" 403 -
203.0.113.50 - "GET /handbook HTTP/1.1" 403 -
192.168.10.20 - "GET /handbook HTTP/1.1" 401 -
192.168.10.20 ana "GET /handbook HTTP/1.1" 200 -
203.0.113.50 ana "GET /handbook HTTP/1.1" 200 -
```

In the first three lines, the second field is `-`: the portal served or refused the handbook without
ever knowing who asked. In the last two, every successful request carries a name. When something
goes wrong, the second log says whose account it was; the first can only say which network.

### What this lab does not show

This is one piece of Zero Trust, not the whole of it. The portal checks identity with a password and
nothing more: it does not check the device, it does not ask for a second factor, and it does not
weigh the context. A real design would refuse ana's password from an unmanaged device, ask for the
second factor of lesson 9, and notice that the same account was used from two places at once.
The previous section's table lists the signals; the lab uses the first.
