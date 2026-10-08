---
title: The pyramid of pain
version: 1
---

In 2013 David Bianco drew the idea as a pyramid. Each layer is a kind of indicator, ordered by **how much
it costs the adversary when a defender detects it and they have to change it**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The pyramid of pain, six layers from top to bottom: TTPs, tough for an adversary to change; tools, challenging; network and host artefacts, annoying; domain names, simple; IP addresses, easy; hash values, trivial. The higher the layer a defender detects, the more it costs the adversary to evade.\"><rect x=\"270.0\" y=\"10\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"23\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">TTPs</text><text x=\"360\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tough</text><rect x=\"230.0\" y=\"54\" width=\"260\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tools</text><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">challenging</text><rect x=\"190.0\" y=\"98\" width=\"340\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">network and host artefacts</text><text x=\"360\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">annoying</text><rect x=\"150.0\" y=\"142\" width=\"420\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">domain names</text><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">simple</text><rect x=\"110.0\" y=\"186\" width=\"500\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">IP addresses</text><text x=\"360\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">easy</text><rect x=\"70.0\" y=\"230\" width=\"580\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hash values</text><text x=\"360\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">trivial</text></svg>", "caption": "What it costs the adversary to change each kind of indicator, after David Bianco's pyramid of pain."}
```

At the bottom, a new hash costs nothing: recompile, re-pack, change a byte. An IP address costs a few
minutes and a little money. A domain, slightly more. **Network and host artefacts**, such as a distinctive
user agent or a file always dropped in the same folder, mean changing how the tools behave. **Tools** mean
replacing or rewriting them. And at the top, **TTPs** (tactics, techniques and procedures) are the way the
adversary works: changing those means learning a new way to do the job.

Two things follow for a SOC. Detections built on the bottom layers are cheap to write and cheap to evade;
**invest at the top**, where a detection survives the adversary's next address. And **use the bottom layers
for what they are good at**: confirming, quickly and certainly, that a known thing is here. Lesson 8's
match on `203.0.113.200` was exactly that.

Thursday has examples at three heights. `203.0.113.66` is an address: block it and the next attempt comes
from another one. The habit of trying names from the company's own website is closer to a **procedure**.
And "guess many accounts, log in, move to the file server, send a large archive out" is the shape of the
**technique** chain the last sections of this lesson name.
