---
title: A small exercise
version: 1
---

The question for this exercise, agreed in advance: **if somebody on the internet tries to guess
ana's password on the portal, does anything in the shop see it?** The red step is ana, on a machine on
the internet, sending six requests with six wrong passwords. The blue step is the administrator
reading the portal's log on `www`.

### Red

```
ana@outside:~$ for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w "%{http_code}\n" -u ana:wrong-$i http://www.example.com/payslips/ana; done
401
401
401
401
401
401
```

The loop sends the same request six times, each with a different wrong password, and prints only the
status code of each answer. Six times `401`: the login held, as lesson 8 showed it would.

### Blue

The question now is not whether the attack worked but whether it was **seen**:

```
root@www:~# grep -c ' 401 ' /var/log/lab/portal.log
6
root@www:~# grep ' 401 ' /var/log/lab/portal.log | cut -d' ' -f1 | sort | uniq -c
      6 203.0.113.50
```

`grep -c` counts the lines of the log containing ` 401 `: six, one per attempt. The second command
keeps only the address at the start of each of those lines and counts them per address: all six came
from `203.0.113.50`. So the log saw everything, and a person reading it would see six failed logins
from one address on the internet.

### What the exercise found

Purple is about the next question, and here it is: **could somebody act on this?** Reading the
raw log answers that:

```
root@www:~# head -3 /var/log/lab/portal.log
192.168.10.20 ana "GET /payslips/ana HTTP/1.1" 200 -
203.0.113.50 - "GET /payslips/ana HTTP/1.1" 401 -
203.0.113.50 - "GET /payslips/ana HTTP/1.1" 401 -
```

Two things are missing, and neither would have been noticed without trying.

**There is no time on any line.** Six failures in two seconds and six failures spread over a month
look identical. The first is somebody guessing; the second is a person who forgets their password
now and then. Without time, no rule can tell them apart, and lesson 11 shows that telling them apart
is the whole job of a detection.

**Failed attempts carry no username.** A successful request records `ana`; a failed one records `-`,
because the portal only notes a name after the password checks out. So the log can say an address is
guessing, but not **whose** account it is guessing. If the attacker spread their attempts across
every staff account, the log would not show that either.

Both findings go into the shop's risk register as an improvement to the portal: record the time of
every request, and record the username that was **claimed** on a failed attempt, marked as claimed.
The lab's portal leaves them out, because a log with real times would print different numbers on
every run of this course; a real portal must not. That is the honest result of the exercise: the
control worked, the detection could not have, and now the shop knows why.
