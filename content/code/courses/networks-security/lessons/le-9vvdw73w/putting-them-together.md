---
title: Two partial views make one picture
version: 1
---

Neither sensor tells the whole story of this lesson on its own. Put side by side, their records of
the same afternoon read like this:

| time | network sensor on the DMZ | host sensor on `www` |
|---|---|---|
| request 1 | alert 1000101, `/admin/` over HTTP, answered 200 | access log: `/admin/`, 200 |
| request 2 | a TLS connection to `www.example.com`, nothing more | access log: `/admin/`, 200 |
| configuration change | nothing | AIDE: `sites-enabled/shop` changed, 602 bytes to 744 |
| new listener | nothing, until somebody connects | port 8081, owned by `socat` |

**The host saw more, and the network saw it independently.** If `www` were compromised, its access log
and its AIDE reports could be edited to hide all four rows; the network sensor's record of request 1
and of the TLS connection could not, because the intruder never touched `sensor`. That is the argument
for running both and for sending the host's records off the host.

**Correlation** is the name for putting the rows together, and it is where most detection value comes
from: one weak signal on the network plus one weak signal on the host, at the same time, about the same
machine, is a strong one. Doing it by hand, as this table does, works for an afternoon. Doing it for a
company is what a central log platform, a **SIEM**, exists for, and lesson 23 decides what to feed it.

A last practical point: **a HIDS on every host is a lot of agents to maintain**, and the hosts that
most need one are rarely the easiest to install it on. Printers, cameras, network appliances and old
industrial systems run no agent at all. For those, the network sensor is the only witness there is.
