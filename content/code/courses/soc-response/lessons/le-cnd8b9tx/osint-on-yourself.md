---
title: OSINT, pointed at yourself
version: 1
---

**OSINT**, open-source intelligence, is what can be learned from public sources: websites, public records,
certificate logs, search engines, social networks. For a SOC its most useful target is **its own
company**, seen from outside, because that is the view anybody preparing an attack starts from.

What is worth checking about your own organisation, regularly:

| what | why it matters | where it shows |
|---|---|---|
| **public DNS names** | every published name is a door somebody can knock on | the company's DNS, and certificate transparency logs, which list every certificate issued for its domains |
| **services reachable from the internet** | a forgotten test server is the usual way in | search engines that index open services |
| **staff details** | names, roles and email formats are the raw material of phishing | the company's site and professional networks |
| **leaked credentials** | a password reused from a breached site opens a door that looks legitimate | breach notification services, which can alert on a company domain |
| **code and documents** | keys and internal hostnames left in public repositories or files | public code hosting, document metadata |

Thursday's guessing run started with names, and several were real: ana, bruno, carla, diego, helena. Where
did they come from? The company's own website lists its team. That is an OSINT finding about yourself,
and the fix is not secrecy but **making the names useless on their own**: no password-only SSH from the
internet, which is lesson 14's subject.

Three limits keep this work defensible. Collect **passively**: read what is published, do not probe
systems. Look at **your own organisation, or one that authorised you in writing**; the same techniques
pointed at somebody else's are reconnaissance. And remember that profiles of staff are **personal data**
under the LGPD: collect what the defence needs, keep it as briefly as the purpose allows, and do not build
a file on people because a tool made it easy.
