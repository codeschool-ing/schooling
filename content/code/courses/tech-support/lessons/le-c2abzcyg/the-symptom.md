---
title: A system that stopped answering
version: 1
---

At 01:09, several people in sales report the same thing: the sales system in the browser shows an error.
From one of their computers:

```
ana@pc1:~$ date "+%H:%M"; curl -sS -o /dev/null -w "%{http_code}\n" http://srv1/sales/
01:09
502
```

**502** is the web server's way of saying *I am here, and the thing behind me did not answer*, the
networks course's lesson on HTTP. So the web server on `srv1` is up; whatever it passes `/sales/` to is
not. Many users and one whole system is already a reason to move quickly, lesson 6.
