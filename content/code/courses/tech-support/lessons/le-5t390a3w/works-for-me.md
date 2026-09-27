---
title: The trap on your side: it works for me
version: 1
---

The technician connects to Bruno's computer, `pc1`, and prints a test page:

```
ana@pc1:~$ lpstat -d; echo "a test page" | lp
system default destination: office
request id is office-3 (0 file(s))
```

The system's default printer is `office`, and the test page was accepted there. It is tempting to
stop here and reply *"I printed from your computer and it worked"*, which tells Bruno he is wrong about
something he watched fail.

The test ran **as `ana`**, the technician, and not as Bruno. On the same computer, two people can have
different settings, different permissions, different files and different defaults. **Reproduce as the
user, or you have reproduced somebody else's problem**: that is lesson 1's first step, applied to
*who*, not only to *where*.
