---
title: Finding the single point of failure
version: 1
---

A **single point of failure**, a SPOF, is a part whose failure alone stops the service. Finding them is
the first job of availability design, and they are rarely where people look first, because people look
at the servers.

Here is the lab's data centre as a request for `www.example.com` sees it, with every part coloured by
whether it has a twin:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" aria-label=\"The lab&#x27;s data centre as a request sees it. Users reach the ISP router, isp at 192.0.2.1, which has one link into the data centre, a single segment 192.0.2.0/24. Inside are the DNS server ns at 192.0.2.53, two load balancers lb1 and lb2 at 192.0.2.11 and .12 sharing www.example.com at 192.0.2.80, and three web servers web1 to web3 at 192.0.2.21 to .23, each balancer connected to every web server. The ISP router, its link, the segment and the DNS server are drawn as single; the balancers and web servers as having a twin.\"><rect x=\"20\" y=\"128\" width=\"96\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"68.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">users</text><path d=\"M116 150 L140 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"140\" y=\"128\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">isp</text><text x=\"190.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.1</text><path d=\"M240 150 L300 150\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"270\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">one link</text><rect x=\"300\" y=\"30\" width=\"400\" height=\"236\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"312\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">data centre, one segment</text><text x=\"688\" y=\"47\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.0/24</text><path d=\"M300 150 L320 90\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M300 150 L320 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M300 150 L320 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"320\" y=\"70\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ns</text><text x=\"370.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.53</text><rect x=\"320\" y=\"130\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lb1</text><text x=\"370.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.11</text><rect x=\"320\" y=\"190\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lb2</text><text x=\"370.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.12</text><path d=\"M420 150 L560 90\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420 150 L560 150\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420 150 L560 210\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420 210 L560 90\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420 210 L560 150\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420 210 L560 210\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"560\" y=\"70\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web1</text><text x=\"615.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.21</text><rect x=\"560\" y=\"130\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web2</text><text x=\"615.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.22</text><rect x=\"560\" y=\"190\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web3</text><text x=\"615.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.23</text><text x=\"320\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">www.example.com = 192.0.2.80</text><rect x=\"20\" y=\"284\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"40\" y=\"289\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">single: its failure alone stops the site</text><rect x=\"380\" y=\"284\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"400\" y=\"289\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">has a twin that can take over</text></svg>", "caption": "Five machines have a twin and four things do not. The single ones are all on the way in, which is where every request has to pass."}
```

The servers are fine. Three web servers behind two balancers survive the loss of any one of them, and
lesson 16 measures it: when the balancer on `lb1` was killed, `lb2` took over and the site answered again
after 2.694 seconds, and when `web2` stopped, the balancer sent every request to `web1` and `web3`
instead. **Everything else in the drawing is single.** There is one router to the internet, `isp`, on one
link. There is one DNS server, `ns`: if it stops, a browser that has not already cached the address
cannot find `www.example.com` at all, and five healthy machines are unreachable by name. And every
machine in the room hangs off one segment, `192.0.2.0/24`, which in a real room is a switch or a pair of
them.

## A method, not a hunch

Walk the path of one request from the user's machine to the answer and back, and at each box and each
line ask one question: **if this alone failed, would the request still succeed?** Then walk it a second
time for what the path depends on without being on it. The name lookup happens before the request. The
certificate has to be valid, and the clock it is checked against has to be right. And under all of it
there is the power.

The second walk finds most of the ones people forget:

| often forgotten | what it takes down with it |
|---|---|
| one ISP, or two ISPs whose cables enter the building together | everything that talks to the outside |
| one DNS server, or two on the same network | every name, while every address still works |
| the default gateway of an office LAN | every host on it, however many routers are plugged in |
| one power feed or one UPS | the whole rack |
| one person who knows how the failover works | the recovery, at three in the morning |

The third row is in the lab. Every host at head office has exactly one default gateway, `192.168.10.1`,
and lesson 15 opens with the laptop's routing table saying so. A second router on the same LAN changes
nothing for a host that only ever sends to the first, so **redundancy the hosts cannot use is not
redundancy**. Lesson 15 fixes it by making the gateway's address itself move between two routers.

## Not every one is worth removing

Each SPOF removed costs money and adds a part that can itself fail: the failover mechanism. A second
ISP line costs a monthly fee. A second DNS server in another place is cheap and is nearly always worth
it. A second data centre can double the bill. The decision is the arithmetic of the previous section
against the cost of an hour of downtime to this particular business, and lesson 17 turns that decision
into a promise somebody signs. **A list of the SPOFs you have kept on purpose is a design; a list you
never made is a surprise.**
