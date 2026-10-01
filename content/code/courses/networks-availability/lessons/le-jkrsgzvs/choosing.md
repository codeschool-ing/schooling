---
title: Choosing, and what comes after the VPN
version: 1
---

Both kinds of VPN rest on one assumption: once a packet is through the tunnel, it is on the network, and
the network's firewall is what stands between it and everything else. A remote-access user with a valid
login reaches every address the pool is allowed to reach, and so does whoever has her stolen laptop.

**Zero trust network access, ZTNA, drops that assumption.** Instead of putting the device on the
network, a broker checks the person and the device each time they open an application, and connects
them to that application alone. Nothing else on the network is reachable from the session, and the
application needs no port open to the internet, because a connector inside the company's network dials
out to the broker. It is a different kind of product rather than a VPN setting, and none of it ran in
this lab.

**ZTNA does not replace site to site.** A till and a printer have no person to check. It replaces remote
access to particular applications, and a company commonly runs both: tunnels between its offices, and
per-application access for its people.

| the situation | the choice |
|---|---|
| two offices whose devices all need the other office | site to site |
| a branch of devices that cannot run a client: tills, printers, cameras | site to site |
| staff at home using many internal systems, and the company must see or filter all their traffic | remote access, full tunnel, with a resolver on the company side |
| the same staff, with video calls and a small head-office uplink | remote access, split tunnel, with split DNS |
| a contractor who needs one web application | per-application access, not a tunnel into the network |
| staff whose home networks may use the office's numbers | renumber or translate before rollout, not after the first ticket |

Every row leaves one question open, and it is the same one in each. The tunnel has a router at each
end, and in this lab it has one link to the internet at each office. What happens when one of them
fails is the subject of lessons 14 to 16.
