---
title: Testing the layers in the lab
version: 1
---

A layered defence is tested the way it is designed: **assume each layer has already failed, and
see whether the next one holds.** This section does that against the shop's staff portal, from a
machine on the internet. The goal is bruno's payslip, which only bruno and the finance team should
read.

### Layer 1: nobody gets in without signing in

The first attempt is a stranger with nothing:

```
ana@outside:~$ curl -s http://www.example.com/payslips/bruno
sign in first
```

`curl` asks the portal for `/payslips/bruno` and the portal answers `sign in first`. The login is
doing its job.

### Layer 2: signing in is not the same as being allowed

Now assume the first layer has failed: ana's password leaked, perhaps reused on another site that
was breached. The attacker has a real username and password:

```
ana@outside:~$ curl -s -u ana:lab-ana-pass http://www.example.com/payslips/ana
payslip for ana, September 2026
ana@outside:~$ curl -s -u ana:lab-ana-pass http://www.example.com/payslips/bruno
not yours to read
```

The leaked password works, and it opens **ana's** payslip, which is the damage that leak does. It
does not open bruno's: the portal checks not only who is asking but whether that person may read
that payslip, and answers `not yours to read`. Lesson 8 gives these two checks their names,
authentication and authorisation; here it is enough that they are two layers and the second held
when the first fell.

### Layer 3: the program cannot read what it does not need

Assume worse: a bug in the portal lets an attacker make it read any file on the server. The
salaries spreadsheet lives on the same machine. The administrator checks who may read it, then
tries to read it as the account the portal runs as, `shop`:

```
root@www:~# ls -l /srv/hr/salaries.csv
-rw-r----- 1 bruno hr 33 Sep 30 17:00 /srv/hr/salaries.csv
root@www:~# setpriv --reuid=shop --regid=shop --clear-groups cat /srv/hr/salaries.csv
cat: /srv/hr/salaries.csv: Permission denied
```

`ls -l` shows the file belongs to bruno and the group `hr`, and `rw-r-----` means bruno may read
and write it, members of `hr` may read it, and everybody else, `shop` included, may do nothing.
`setpriv` runs `cat` under the `shop` account, exactly as the portal would, and the operating
system refuses: `Permission denied`. A bug in the application is now a bug that can read only what
`shop` can read. That is least privilege, the subject of lesson 6, working as a layer.

### Layer 4: somebody would see it

None of the layers above told anyone anything. The fourth is the portal's log:

```
root@www:~# cat /var/log/lab/portal.log
203.0.113.50 - "GET /payslips/bruno HTTP/1.1" 401 -
203.0.113.50 ana "GET /payslips/ana HTTP/1.1" 200 -
203.0.113.50 ana "GET /payslips/bruno HTTP/1.1" 403 -
```

Three lines, one per request: the address it came from, the user if somebody signed in, the page
and the answer the portal gave (401, 200, 403). The second and third lines are the ones that
matter. **ana's account, used from an address on the internet rather than from the office, asked
for somebody else's payslip.** No layer above was breached, and the log still holds the evidence
that ana's password is in the wrong hands. A detective control that somebody reads, or that raises
an alert, is what turns that into a changed password the same afternoon instead of a discovery
months later.
