---
title: TCP or UDP: who needs what
version: 1
---

The choice is made by whoever designs the protocol, not by the user, but knowing it explains a lot of
behaviour:

| protocol | transport | why |
|---|---|---|
| web (HTTP/1.1, HTTP/2), email, SSH, file transfer | TCP | every byte has to arrive, in order |
| DNS | UDP, TCP for big answers | one small question, one small answer; a handshake would triple the cost |
| video and voice calls | UDP | a late packet is useless; better to skip it than wait |
| online games | UDP | the newest position matters, not the one from a moment ago |
| HTTP/3 | UDP, port 443 | its own reliability, built on top, faster to start than TCP plus TLS |

**The pattern is timing.** TCP is right when a missing byte ruins the result and waiting for it is
acceptable. UDP is right when a late answer is as bad as none, or when the program would rather
handle loss its own way.

HTTP/3 is the interesting case. It needs everything TCP gives, and builds it again inside a protocol
called **QUIC**, over UDP, so that the connection and the encryption are set up together in fewer round
trips. That is why a firewall that allows TCP 443 and blocks UDP 443 does not break the web: browsers
try HTTP/3, get nothing, and fall back to HTTP/2 over TCP, a little slower to start.
