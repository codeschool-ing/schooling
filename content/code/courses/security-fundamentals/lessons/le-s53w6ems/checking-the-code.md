---
title: Checking the code
version: 1
---

The server does not receive a code from the phone and look it up anywhere. It computes the code
itself, from its own copy of the secret and its own clock, and compares. In the lab the server
`www` checks the code ana's app showed at 13:00:00:

```
root@www:~# oathtool --totp -b --now '2026-10-06 13:00:00 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ 593771; echo "exit $?"
0
exit 0
root@www:~# oathtool --totp -b --now '2026-10-06 13:02:00 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ 593771; echo "exit $?"
oathtool: password "593771" not found in range 59709724 .. 59709724
exit 2
```

Given a code to check, `oathtool` answers with where in the window it found it and exits 0, or says
`not found` and exits with an error. At 13:00:00 the code matches; two minutes later the same code is
refused, because four steps have passed and the server now expects a different one. A code typed
from a screenshot, a note or a phishing page two minutes old is worthless.

### When the clocks disagree

The phone's clock and the server's are never exactly the same, and a person takes a few seconds to
type. A code shown at 12:59:45 belongs to the previous step, and by the time it arrives the server
is in the next one:

```
ana@laptop:~$ oathtool --totp -b --now '2026-10-06 12:59:45 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
907684
root@www:~# oathtool --totp -b --now '2026-10-06 13:00:00 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ 907684; echo "exit $?"
oathtool: password "907684" not found in range 59709720 .. 59709720
exit 2
root@www:~# oathtool --totp -b -w 1 --now '2026-10-06 13:00:00 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ 907684; echo "exit $?"
1
exit 0
```

With no tolerance the server refuses the code, which would lock out a person who did nothing wrong.
With a window of one step, `-w 1`, it accepts it and reports finding it one step away. Real servers
allow a small window, usually a step either way, and no more: every extra step is thirty more seconds
in which a stolen code still works.

### Proving the implementation

How does anybody know that `oathtool`, or an authenticator app, or the server's code, computes TOTP
correctly? The RFC publishes **test vectors**: a known secret, a known time, and the code that must
come out. Here is the first one, for the time 59 seconds after 1970 with eight digits:

```
ana@laptop:~$ oathtool --totp -d 8 --now '1970-01-01 00:00:59 UTC' 3132333435363738393031323334353637383930
94287082
```

`94287082` is the value printed in Appendix B of RFC 6238. An implementation that gets it wrong is
wrong, whatever else it does. The platform this course runs on checks its own TOTP code against the
same vectors, which is a good habit for anything security depends on: **test against the
specification, not against your own idea of it.**

### What the server must protect

The server keeps a copy of every user's secret, and anyone who steals those secrets can compute every
user's codes forever. So the secrets are stored encrypted, the database holding them is among the most
protected on the system, and turning MFA off or resetting it is an action recorded with who did it.
The secret is the factor; the six digits are only its shadow.
