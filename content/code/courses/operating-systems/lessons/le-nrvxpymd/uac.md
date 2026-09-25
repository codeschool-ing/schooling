---
title: User Account Control
version: 1
---

Before Windows Vista, an administrator's session ran **everything** as administrator: the browser, the
e-mail attachment, the game. **User Account Control**, *UAC*, changed that, and it is the reason a
Windows administrator sees a prompt that a Linux administrator does not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"How User Account Control works. When an administrator signs in, Windows gives the session two tokens: a standard one, which everything runs with, and a full one. A program that needs more shows a prompt, and answering Yes runs that one program with the full token. A standard user has only a standard token; the same prompt asks for an administrator&#x27;s name and password, and that one program runs with the administrator&#x27;s full token.\"><defs><marker id=\"ua-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">an administrator signs in</text><rect x=\"20\" y=\"34\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">standard token</text><text x=\"190\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">everything runs with this</text><rect x=\"20\" y=\"80\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">full token</text><path d=\"M182 95 L380 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ua-ah)\"></path><text x=\"190\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Run as administrator: &quot;Yes&quot;</text><rect x=\"382\" y=\"80\" width=\"318\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"541\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">that one program runs with it</text><text x=\"20\" y=\"158\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a standard user</text><rect x=\"20\" y=\"174\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">standard token</text><path d=\"M182 189 L380 189\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ua-ah)\"></path><text x=\"190\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">asks for an administrator&#x27;s name and password</text><rect x=\"382\" y=\"174\" width=\"318\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"541\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">that one program runs as the administrator</text></svg>", "caption": "Being an administrator on Windows means being asked, not being trusted by default. A standard user is asked for somebody else's password instead, which is the point."}
```

When an administrator signs in, Windows builds **two tokens**, the bundles of groups and privileges a
program carries. Everything starts with the **standard** one. When a program needs more, installing
software, writing to `C:\Program Files`, changing a system setting, Windows shows a prompt:

- **For an administrator**, the prompt asks **Yes or No**. That is the *consent* prompt. Yes starts
  that one program with the full token, and nothing else changes.
- **For a standard user**, the same prompt asks for **an administrator's name and password**. That is
  the *credential* prompt, and it is how Ana installs something on the reception PC without the
  receptionist ever being an administrator.

The screen dims around the prompt. That is the **secure desktop**: other programs cannot draw on it or
click it, so malware cannot answer Yes on your behalf.

## Why the daily account should be standard

UAC's Yes is only a question, and people learn to click it without reading. **A standard account turns
that reflex into a password somebody else holds.** The office's arrangement becomes:

1. Every person works in a **standard** account.
2. Ana has an **administrator** account she uses only when a prompt asks for it, and her own standard
   account for everything else, e-mail included.
3. The built-in Administrator stays disabled.

Right-click a program and choose **Run as administrator** to start it elevated deliberately, which is
how an elevated Terminal is opened for lesson 13's commands.
