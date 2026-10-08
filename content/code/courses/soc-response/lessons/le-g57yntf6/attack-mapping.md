---
title: Naming it with ATT&CK
version: 1
---

Once behaviour is described, it needs names that everybody shares. **MITRE ATT&CK** is the public catalogue
of adversary behaviour, built from real incidents: **tactics** are the goals (Initial Access, Credential
Access, Persistence, Lateral Movement, Exfiltration and nine more), and **techniques** are the ways of
reaching them, each with an identifier such as `T1110`, and sub-techniques such as `T1110.003`.

Thursday, step by step, with the technique each step is evidence of:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Thursday night on a time axis, local time, with the ATT&amp;CK technique for each step: 02:10 guessing across 19 accounts, T1110.003 password spraying; 02:33 login as bruno, T1078 valid accounts; 02:35 SSH from gw to files, T1021.004; 02:41 612 MB sent out over HTTPS, T1048.002; 03:05 login with a key, consistent with T1098.004, SSH authorized keys.\"><path d=\"M30 70 L690 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 64 L70 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">02:10</text><rect x=\"8\" y=\"90\" width=\"124\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">guessing, 19 accounts</text><text x=\"70\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">T1110.003</text><path d=\"M205 64 L205 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"205\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">02:33</text><rect x=\"143\" y=\"90\" width=\"124\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"205\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">login as bruno</text><text x=\"205\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">T1078</text><path d=\"M340 64 L340 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"340\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">02:35</text><rect x=\"278\" y=\"90\" width=\"124\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"340\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SSH on to files</text><text x=\"340\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">T1021.004</text><path d=\"M475 64 L475 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"475\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">02:41</text><rect x=\"413\" y=\"90\" width=\"124\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"475\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">612 MB out over HTTPS</text><text x=\"475\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">T1048.002</text><path d=\"M610 64 L610 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"610\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">03:05</text><rect x=\"548\" y=\"90\" width=\"124\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">back with a key</text><text x=\"610\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">T1098.004</text></svg>", "caption": "Five steps, five techniques. The last is inferred from a log line; lesson 17 confirms it on disk."}
```

| step | technique | tactic |
|---|---|---|
| many accounts, a few tries each | **T1110.003** Password Spraying | Credential Access |
| a real account, used from outside | **T1078** Valid Accounts | Initial Access |
| SSH from `gw` to `files` | **T1021.004** Remote Services: SSH | Lateral Movement |
| a large upload over HTTPS to a new address | **T1048.002** Exfiltration Over Asymmetric Encrypted Non-C2 Protocol | Exfiltration |
| a later login with a key the account never had | **T1098.004** Account Manipulation: SSH Authorized Keys | Persistence |

The last row is labelled with care: the logs show a key **login**, not a key being **added**. The
technique is the best explanation of the evidence, and lesson 17 confirms it by finding the key on `gw`'s
disk. **Write a mapping as the evidence supports it**, and say which steps are inferred.

A mapping pays three ways. It turns an incident into **tactical intelligence** another team can use without
reading your logs. It shows **where detection exists and where it does not**: of these five steps, lesson 4
had a rule for one. And it tells the people writing rules what to write next: here, a rule for the fourth
row would have alerted on the transfer that the whole investigation turned on.
