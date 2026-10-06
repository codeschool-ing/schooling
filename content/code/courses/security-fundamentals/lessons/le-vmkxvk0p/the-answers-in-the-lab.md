---
title: The answers in the lab
version: 1
---

The portal's payslip pages are a small, complete example of both checks. The requests below are
sent with `curl` from the office laptop. `-u name:password` sends a username and password with the
request; `-i` asks `curl` to show the reply's status line and headers as well as its body, and
`-w "%{http_code}\n"` prints only the status code.

### No identity at all

```
ana@laptop:~$ curl -si http://www.example.com/payslips/ana
HTTP/1.0 401 Unauthorized
WWW-Authenticate: Basic realm="staff"
Content-Type: text/plain
Content-Length: 14

sign in first
```

`401 Unauthorized` is HTTP's code for "authentication required", despite its name. The header
`WWW-Authenticate` tells the client how to authenticate: here, with a username and password, the
method called Basic. A wrong password gets the same answer:

```
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" -u ana:wrong-guess http://www.example.com/payslips/ana
401
```

The portal does not say whether the user exists or the password was wrong. Lesson 9 comes back to
why that matters.

### Identity proved, permission checked

```
ana@laptop:~$ curl -s -u ana:lab-ana-pass http://www.example.com/payslips/ana
payslip for ana, September 2026
ana@laptop:~$ curl -si -u ana:lab-ana-pass http://www.example.com/payslips/bruno
HTTP/1.0 403 Forbidden
Content-Type: text/plain
Content-Length: 18

not yours to read
```

The same ana, with her correct password, gets her own payslip and is refused bruno's. The refusal is
`403 Forbidden`: **the portal knows exactly who is asking and has decided the answer is no.** That
is the whole difference between the two codes. 401 says "I don't know who you are"; 403 says "I know
who you are, and you may not".

### A role that changes the answer

bruno runs finance and is in the `hr` group, and the portal's rule lets `hr` read any payslip:

```
ana@laptop:~$ curl -s -u bruno:lab-bruno-pass http://www.example.com/payslips/ana
payslip for ana, September 2026
```

Same page, a different identity, a different decision. Authentication did the same job for both
users; authorisation came to different answers because the rules treat their roles differently.

### What a refusal reveals

The shop has no employee called carla. Two people ask for her payslip:

```
ana@laptop:~$ curl -s -w "%{http_code}\n" -u ana:lab-ana-pass http://www.example.com/payslips/carla
not yours to read
403
ana@laptop:~$ curl -s -w "%{http_code}\n" -u bruno:lab-bruno-pass http://www.example.com/payslips/carla
no such payslip
404
```

ana is refused with 403 and bruno is told 404, "no such payslip". The difference is deliberate. ana
may not read anybody else's payslip, so the portal refuses her **before** checking whether the
payslip exists. Had it checked existence first, a 404 for carla and a 403 for bruno would tell ana
which names are on the payroll, which is itself information she has no right to. bruno may read any
payslip, so telling him one does not exist reveals nothing he could not see anyway.

### The record

```
root@www:~# cat /var/log/lab/portal.log
192.168.10.20 - "GET /payslips/ana HTTP/1.1" 401 -
192.168.10.20 - "GET /payslips/ana HTTP/1.1" 401 -
192.168.10.20 ana "GET /payslips/ana HTTP/1.1" 200 -
192.168.10.20 ana "GET /payslips/bruno HTTP/1.1" 403 -
192.168.10.20 bruno "GET /payslips/ana HTTP/1.1" 200 -
192.168.10.20 ana "GET /payslips/carla HTTP/1.1" 403 -
192.168.10.20 bruno "GET /payslips/carla HTTP/1.1" 404 -
```

Each line of the log has the address, the authenticated user (or `-` if there was none), the page
and the answer. The first two lines have no name, because those requests never authenticated. Every
later line has one, and that is what lets anybody reviewing the log say who asked for what.
