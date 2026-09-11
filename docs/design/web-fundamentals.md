---
format: 5
course: web-fundamentals
---

# web-fundamentals

**Web and Internet Fundamentals** · `co-gkdcy0n2` · 40 h declared · beginner · 11 lessons
· `foundations` · **free**

## Reach

In **12 tracks**, at position 1 in ten of them — `ai`, `backend`, `cloud-engineering`, `data`,
`devops`, `frontend`, `mobile`, `networks-infra`, `prompt`, `qa` — and further along in `dba` (2)
and `it-support` (3). Reached directly in all twelve; it is never behind a choice.

Free by `C-28`, and it is **the** free course of the platform rather than one of eight: no other
entry course comes close to this reach.

**Depends on it:** `html-css`.

## Assumes, and leaves ready

**Assumes nothing.** Everyday computer and internet use. It is the floor.

**Leaves ready,** for `html-css`: what a request and a response are, what a browser does with the
answer, and what a domain is. `html-css` does not re-explain HTTP.

## Shape

| | |
|---|---|
| declared hours | 40 h |
| lessons | 11 |
| **hours per lesson** | **3.64** |
| section budget | ~86, about 7.8 a lesson — **and 86 are designed**, which is the evidence the budget rests on |
| sections | **86** — 54 reading, 21 video, 11 practice |
| exercises | ~385–425, floor 350 |
| video | estimated, not a target (`C-36`) |
| avatar visible | ~20–25% overall, and **100% in an opening** — see below |

Exercise types: `quiz`, `multiple-choice`, `ordering`, `matching`, `cloze`, `labelling`,
`numeric`. Not `code` or `expected-output` — there is no programming here, which is why this
course is unaffected by the two types with no grader.

## Execution

| | |
|---|---|
| runtime | **none** |
| browser · database | no · no |
| exercises **blocked** without a sandbox | **0** |
| exercises that would **improve** with one | ~20 — `curl`, `dig`, `ping`, `traceroute` as `expected-output` |
| diagrams to draw | ~32 |

## Ageing

**No.** The screen shows diagrams and annotated stills, not a third party's product. Nothing here
expires while its script stays right — the opposite of every `aws-`, `azure-` and `gcp-` course,
and worth recording as the contrast.

## Sections

Four volumes. **The volumes are a reading device; the lessons and their ids are the contract with
the portal and do not move.** The numbering 01–86 is the path a student walks, in the order they
walk it.

### An opening is short, and it is the most expensive minute in the course

Every lesson opens with a video, and every opening is **60–90 seconds**, almost entirely in
`full` mode — the presenter talking to the person, no screen, no cues.

That length is a decision rather than a default, and the reason is a cost the rest of the design
does not have. `C-30` makes absence the lever: across the course the presenter is on screen
perhaps a fifth of the time. **An opening is on screen for all of it.** At two and a half
minutes each, eleven openings would be about 9% of the runtime and near 40% of the avatar
budget — the most avatar-expensive material in the course, in the place where an extra minute
buys least. At 60–90 seconds they cost about a fifth of that, and an opening that cannot say what
the lesson is for in ninety seconds is not an opening.

Keeping all eleven is also a decision. Uniform orientation is worth something to a beginner, and
the pattern is one the market has validated — it is not the always-present avatar, which was
decoration; this is a student knowing where they are.

### And the demonstration goes where the concept ends

**The second video sat in the penultimate slot in seven of eleven lessons, and that looked like a
template.** It was checked lesson by lesson, and mostly it is not: a demonstration shows what an
explanation has already established, so it falls late for a reason that belongs to the material
rather than to a shape. Lessons 1 and 6 have it mid-lesson because there is more to say
afterwards, which is the same rule producing a different answer.

**One real change came out of the check.** Lesson 3 had no second video and its last reading is
*reading a speed test, a ping and a traceroute honestly* — which is a demonstration described as
prose. It is a video now, which is what moved the shape from 54/20/11 to 53/21/11 — and `hops`
arriving later put the readings back at 54.

The position is not fixed and no lesson owes anybody a second video: lesson 9 has none, because
comparing four kinds of hosting is a table and not something to watch.

---

## Volume I — The wire

**Lesson 1 · Client, server and host: who asks and who answers** — `le-tt74bvn7`

| | slug | kind | covers |
|---|---|---|---|
| 01 | `intro` | video | The question this course answers — **opening** |
| 02 | `roles` | reading | Client and server are roles in a moment, not properties of a machine |
| 03 | `host` | reading | Host, node, endpoint — the words for a machine on a network |
| 04 | `request-response` | reading | The shape of one exchange, end to end |
| 05 | `who-asks` | video | A whole exchange, drawn — and the server that becomes a client |
| 06 | `many-clients` | reading | One server, many clients: concurrency as the ordinary case |
| 07 | `peer-to-peer` | reading | Where the model does not apply, and why the web is not it |
| 08 | `drill` | practice | Naming the role in twelve situations |

**Lesson 2 · Packet, frame and socket** — `le-v2fa0w8t`

| | slug | kind | covers |
|---|---|---|---|
| 09 | `intro` | video | Why there is a unit of transmission at all — **opening** |
| 10 | `packets` | reading | The packet: header, payload, and what a router reads |
| 11 | `frames` | reading | The frame: one hop's envelope, and the switch that never opens it |
| 12 | `hops` | reading | How a packet crosses a network it does not belong to |
| 13 | `mtu` | reading | MTU and fragmentation: the size that decides the cut |
| 14 | `sockets` | reading | Address plus port, and what "listening" means |
| 15 | `tcp-udp` | reading | Ordered and acknowledged, or fast and unacknowledged |
| 16 | `handshake` | video | Opening a connection, and what UDP skips |
| 17 | `drill` | practice | Read a header and say where it stops |

**`hops` is the section this sheet did not have, and C-37 is what it cost.** The word *router*
appeared once in all 85 — as "what a router reads" — so a student met the hops in lesson 3, where
`traceroute` prints them, and was never told what produces them. `networks-addressing` owns
routing properly and is in ONE of the twelve tracks that start here; six of them reach no course
that covers it at all. It is not BGP at this level: it is the next hop, the routing table as a
list of "for that range, go there", the default gateway as the last line of it, and why the
latency of lesson 3 is the sum of a dozen independent decisions.

**Lesson 3 · Bandwidth, latency and throughput** — `le-61gshrr6`

| | slug | kind | covers |
|---|---|---|---|
| 18 | `intro` | video | Three numbers people use as if they were one — **opening** |
| 19 | `bandwidth` | reading | Capacity per second, and why it is not speed |
| 20 | `latency` | reading | Round trip, and the floor distance imposes |
| 21 | `throughput` | reading | What you actually get, and what eats the difference |
| 22 | `jitter-loss` | reading | The numbers behind a bad call |
| 23 | `measuring` | video | Reading a speed test, a ping and a traceroute honestly |
| 24 | `drill` | practice | Say which of the three explains each symptom |

**Lesson 4 · IP address, MAC address and ARP** — `le-ss19f9x3`

| | slug | kind | covers |
|---|---|---|---|
| 25 | `intro` | video | Why one address is not enough — **opening** |
| 26 | `ipv4` | reading | Notation, ranges, and what a private address is |
| 27 | `subnet` | reading | Mask and CIDR: deciding what is local |
| 28 | `ipv6` | reading | Why it exists and how to read one |
| 29 | `mac` | reading | The address burned into the card |
| 30 | `arp` | reading | Turning an IP into a MAC on the local segment |
| 31 | `nat` | video | One house, one public address — and what NAT breaks |
| 32 | `drill` | practice | Given an address and a mask, say what is local |

**Lesson 5 · Layered networks: from the cable to the browser** — `le-n74cj30g`

| | slug | kind | covers |
|---|---|---|---|
| 33 | `intro` | video | Layers, and why they exist — **opening** |
| 34 | `why-layers` | reading | What layering buys, and what it costs |
| 35 | `osi` | reading | The seven layers of OSI, and where they are useful |
| 36 | `tcp-ip` | reading | The four of TCP/IP, which is the one that runs |
| 37 | `encapsulation` | reading | One message wearing four headers |
| 38 | `tracing` | video | An HTTP request followed down the stack and back up |
| 39 | `drill` | practice | Put each header on the layer that wrote it |

## Volume II — The conversation

**Lesson 6 · HTTP and HTTPS: methods, headers and status codes** — `le-mcwtvwbv`

| | slug | kind | covers |
|---|---|---|---|
| 40 | `intro` | video | HTTP is a conversation you can read — **opening** |
| 41 | `anatomy` | reading | The anatomy of a request and of a response |
| 42 | `methods` | reading | GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS — safety and idempotence |
| 43 | `status` | reading | Codes by family, and the ones that actually appear |
| 44 | `headers` | reading | Type, length, host, user agent |
| 45 | `content-negotiation` | reading | Negotiating language and format |
| 46 | `tls` | reading | What HTTPS adds: encryption, integrity, identity |
| 47 | `certificates` | video | The chain, and the limits of what the padlock promises |
| 48 | `versions` | reading | HTTP/1.1, /2 and /3 — what changed and why |
| 49 | `drill` | practice | Choose a method and a code for twenty situations |

**Lesson 7 · Cookies, sessions and browser cache** — `le-hptsw8ct`

| | slug | kind | covers |
|---|---|---|---|
| 50 | `intro` | video | State in a protocol that has none — **opening** |
| 51 | `cookies` | reading | Setting, sending and scoping a cookie |
| 52 | `attributes` | reading | Expires, Secure, HttpOnly, SameSite — the attributes that are security |
| 53 | `sessions` | reading | Session on the server, identifier in the cookie |
| 54 | `tokens` | reading | Tokens and local storage: the other way, and its price |
| 55 | `caching` | reading | Cache-Control, ETag and conditional requests |
| 56 | `cache-in-practice` | video | Cache and SameSite seen in the network panel |
| 57 | `drill` | practice | Decide a cookie's attributes per scenario |

## Volume III — The name and the machine

**Lesson 8 · Domains: registration, DNS, propagation and subdomains** — `le-z9qkkeww`

| | slug | kind | covers |
|---|---|---|---|
| 58 | `intro` | video | What happens before the first packet — **opening** |
| 59 | `name-structure` | reading | TLD, domain, subdomain: reading a name right to left |
| 60 | `registration` | reading | Registry, registrar, registrant — and what you actually buy |
| 61 | `resolution` | reading | Recursive resolution: root, TLD, authoritative |
| 62 | `records` | reading | A, AAAA, CNAME, MX, TXT, NS — what each one answers |
| 63 | `ttl` | reading | TTL and "propagation", which is caching with a better name |
| 64 | `subdomains` | video | Resolution and pointing, start to finish |
| 65 | `drill` | practice | Choose the right record for each need |

**Lesson 9 · Hosting: shared, VPS, cloud and CDN** — `le-5he7q8tg`

| | slug | kind | covers |
|---|---|---|---|
| 66 | `intro` | video | Where a site actually lives — **opening** |
| 67 | `shared` | reading | What is shared, and what that costs you |
| 68 | `vps-dedicated` | reading | A machine's worth of control |
| 69 | `cloud` | reading | IaaS, PaaS and serverless as three sizes of responsibility |
| 70 | `static-hosting` | reading | Static hosting and object storage, and when they are enough |
| 71 | `cdn` | reading | What a CDN caches, where, and what it cannot help |
| 72 | `drill` | practice | Choose the hosting for eight different projects |

## Volume IV — The browser

**Lesson 10 · How the browser builds the page: DOM, CSSOM and rendering** — `le-yw79hrg1`

| | slug | kind | covers |
|---|---|---|---|
| 73 | `intro` | video | What happens after the bytes arrive — **opening** |
| 74 | `parsing` | reading | Parsing HTML into the DOM, incrementally |
| 75 | `cssom` | reading | The CSSOM, and why CSS blocks rendering |
| 76 | `render-tree` | reading | The render tree: what is in it and what is not |
| 77 | `layout-paint` | reading | Layout, paint and composite |
| 78 | `scripts` | reading | Where a script blocks, and what `defer` and `async` change |
| 79 | `critical-path` | video | The critical path, on a timeline |
| 80 | `drill` | practice | Order the steps between the byte and the pixel |

**Lesson 11 · Developer tools: network, console and elements** — `le-88yzj4ty`

| | slug | kind | covers |
|---|---|---|---|
| 81 | `intro` | video | The tools that came with the browser — **opening** |
| 82 | `elements` | reading | Reading and editing the live DOM |
| 83 | `network` | reading | Waterfall, timings, headers and payloads |
| 84 | `console` | reading | Errors, logs and running a line of JS |
| 85 | `diagnosing` | video | Two real faults, found from nothing |
| 86 | `drill` | practice | Diagnose ten pages from the network panel |

---

## Exercises

| where | how many |
|---|---|
| in each of the 54 reading sections | ≥ 4 → ~255 |
| in each of the 11 practice sections, all `drillable` | 12–16 → ~154 |
| total proposed | ~385–425 |
| floor, below which it is not published | 350 |

## What it does not cover, on purpose

`C-37` asks for this list, and the reason it exists is that the list was empty when `hops` was
missing — an absence and a boundary look identical until somebody writes the boundary down.

| left out | whose it is | why it is not here |
|---|---|---|
| routing protocols — RIP, OSPF, BGP | `networks-addressing` | `hops` teaches the next hop and the table as a list of ranges. Which protocol filled the table in is a question about running a network, and nobody on ten of these twelve tracks ever will. |
| subnetting arithmetic beyond a mask | `networks-addressing` | Lesson 4 reads a mask and says what is local. Counting hosts per range is a network engineer's exercise. |
| VLANs, trunking, spanning tree | `networks-addressing` | Lesson 2 names the switch to explain where a frame stops. Segmenting a switch is running one. |
| CORS | `front-quality`, `apis` | It is a rule a BROWSER applies to a response, so it needs the response first. Lesson 6 gives HTTP and lesson 7 gives cookies; CORS is the course after those, not inside them. |
| WebSockets, SSE, long polling | `architecture`, `go-back` | They are what you reach for when request-response is the wrong shape — which cannot be taught before request-response IS the shape. |
| Writing a server | every backend course | This course explains what arrives and what answers. Making the thing that answers is the rest of the catalogue. |

Each of these is reachable from at least one track that starts here, and none of them is needed to
read a network panel, which is what lesson 11 asks the student to do.

## Flags

None. **This course can be written today**, and it is the only one whose sections are designed.
