---
title: Watching, and ending it
version: 1
---

Often the user should do the typing and the technician only watch: to learn where a setting is, or
because what is on the screen is theirs to decide. Elisa makes the access read-only:

```
ana@pc1:~$ sudo -u elisa tmux -S /tmp/help server-access -r ana; tmux -S /tmp/help send-keys -t help "echo typed" Enter
client is read-only
ana@pc1:~$ sudo -u elisa tmux -S /tmp/help server-access -l
ana (R)
elisa (W)
```

`client is read-only`: the technician sees the session and can no longer type into it. The list says so
in one letter each, `R` for the technician and `W` for Elisa. Remote support tools have the same switch,
usually called view-only or *request control*.

When the help is over, the access ends, and it is the user who ends it:

```
ana@pc1:~$ sudo -u elisa tmux -S /tmp/help server-access -d ana; tmux -S /tmp/help send-keys -t help "hostname" Enter
access not allowed
```

`access not allowed` again, the state it started in. **Ending the session is part of the job**: a
remote tool left connected, or a permission left granted, is access nobody is supervising. Before
leaving, say that you are disconnecting, and check that the user sees it has ended.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" aria-label=\"The four states of a remote session, left to right. Refused: the default, nobody is let in. Allowed: the user said yes; you type, they see. Watch only: you see, they type. Ended: the user took it back. Each change is made by the user, not by the technician.\"><defs><marker id=\"st-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"158\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">refused</text><text x=\"32\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.8\" fill=\"var(--paper-dim)\">the default: nobody is let in</text><path d=\"M180 53 L194 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"196\" y=\"20\" width=\"158\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"208\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">allowed</text><text x=\"208\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.8\" fill=\"var(--paper-dim)\">they said yes; you type, they see</text><path d=\"M356 53 L370 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"372\" y=\"20\" width=\"158\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"384\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">watch only</text><text x=\"384\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.8\" fill=\"var(--paper-dim)\">you see, they type</text><path d=\"M532 53 L546 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"548\" y=\"20\" width=\"158\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ended</text><text x=\"560\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.8\" fill=\"var(--paper-dim)\">the user took it back</text><text x=\"360\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">each change is made by the user, not by the technician</text></svg>", "caption": "The same four states exist in every remote support tool, whatever it calls them. What makes them consent is who moves between them: the person whose computer it is."}
```
