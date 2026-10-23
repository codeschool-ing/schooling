---
title: Nessus, OpenVAS and Qualys, from their documentation
version: 1
---

The three names that come up whenever somebody says "vulnerability scan" are three products of
the first family. They do the same job and differ mostly in who runs the machinery and how it is
paid for. **This section describes them from their vendors' documentation; none of them was run for this course.** The details that change most often, prices and the limits of the free editions, are the ones to check on the vendor's own page before you plan around them.

### Nessus

Nessus is Tenable's scanner. It is installed on a machine you control, and its checks, which
Tenable calls plugins, arrive as a feed that Tenable updates continuously. One scanner can run
unauthenticated and credentialed scans, and Nessus Agents collect from hosts where an agent is
installed.

The editions differ in scale. **Nessus Essentials** is free and limited to a small number of IP
addresses; the limit has changed over the years, so read Tenable's page for today's. **Nessus
Professional** is a paid licence per scanner, the usual choice of a consultant or a small security
team. An organisation with thousands of hosts runs Tenable's management platforms instead (Tenable
Vulnerability Management in Tenable's cloud, or Tenable Security Center on its own servers), with
many scanners and agents reporting to one place.

### OpenVAS and Greenbone

OpenVAS is an open-source scanner, developed by Greenbone. The **Greenbone Community Edition**
packages it with its management service and a web interface, the Greenbone Security Assistant,
and is free; Greenbone documents running it as a set of containers. Its checks come from the
Greenbone Community Feed. Greenbone's commercial offer adds an enterprise feed with broader
coverage, appliances and support.

It is the one of the three a student could run at home without registering anything, which makes
it the usual first contact with a network scanner. It is also the heaviest to operate: the feed
has to be synchronised before the first scan, and the containers need memory and disk that a
small laptop already running a cluster may not have spare.

### Qualys

Qualys is a cloud platform, sold by subscription; its vulnerability product is called VMDR. The
scanning machinery comes in three forms: Qualys' own scanners on the internet, for what faces the
internet; scanner appliances, virtual or physical, placed inside your network; and the Qualys Cloud
Agent on hosts. **The results, the schedule and the reports live in Qualys' cloud**, not on a
machine of yours, which is the whole appeal for some organisations and the whole objection for
others.

| | Nessus | OpenVAS / Greenbone | Qualys |
|---|---|---|---|
| who runs the engine | you, on your machine | you, on your machine | Qualys, and appliances you place |
| how it reads a host | network, credentials, Nessus Agents | network and credentials | network, credentials, Cloud Agent |
| free option | Nessus Essentials, a few IP addresses | the Community Edition | check Qualys' own page |
| paid | Professional, and Tenable's platforms | enterprise feed, appliances | subscription |
| where results live | the scanner, or Tenable's platform | your server | Qualys' cloud |

### Scan only what you own, or what you are authorised in writing to scan

**A scan is traffic that the receiving side cannot tell apart from the first step of an attack.**
A port sweep looks the same whoever sends it, and a credentialed check is a login. Some devices,
such as old printers and industrial controllers, fall over when they are probed. So the rule is not
a formality:

- **Scan what you own**: your machine, your own containers on `127.0.0.1`, a network you
  administer. Everything linkbox does in this course is on your own machine for that reason.
- **Anything else needs written authorisation** from whoever owns it, naming the addresses in
  scope, the window of dates and hours, the kind of scan, and a person who can be called to stop it.
  "The client said it was fine" in a meeting is not authorisation; a signed scope is.
- **A cloud account has a landlord.** Each provider publishes a policy on what customers may test
  in their own accounts, and what they may not, such as flooding a shared service. Read it before
  scanning your own instances there.
- **Somebody else's system is not yours to scan**, however public it is, and however harmless the
  scan feels. That includes the service you use every day and the address you found in a log.

The same applies to the active scanning of lesson 4: it sends requests meant to provoke errors,
and it belongs only against your own staging, never against production and never against anybody
else's.
