---
title: Reproduce: see it yourself
version: 1
---

The first thing is to see what Carla sees, on her computer, with a command that asks what her browser
asks:

```
ana@pc1:~$ date "+%H:%M"; curl -sS -m 10 http://intranet/
00:18
curl: (7) Failed to connect to intranet port 80 after 3108 ms: Couldn't connect to server
ana@pc1:~$ curl -sS -m 10 http://intranet/
curl: (7) Failed to connect to intranet port 80 after 3137 ms: Couldn't connect to server
```

Now there is **a message, and a time**. `curl` tried to connect to `intranet` on port 80 and gave up
after 3108 milliseconds, and a second try took 3137: the same fault, the same way, twice. That is
what *reproduced* means. It is also more than the ticket said: "won't open" could have been a blank
page, an error from the server or a login screen, and each of those is a different fault.

Two habits make this step worth its time:

- **Copy the message, never paraphrase it.** `Couldn't connect to server` after three seconds says
  that nothing answered at all. "It gave an error" says nothing.
- **Note the time.** Logs are searched by time, and "this morning" matches hours of them.

If you cannot reproduce a fault, that is a finding too, and not the end: ask when it happens, from where
and to whom, lesson 2, and record the attempt in the ticket, lesson 5.
