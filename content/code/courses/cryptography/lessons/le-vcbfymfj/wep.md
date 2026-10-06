---
title: Four generations, and why the first one fell
version: 1
---

**Wi-Fi security has had four names in twenty-five years, and each one exists because the one
before it failed.** WEP was broken within four years of its release. WPA was a repair that had to
run on WEP's hardware. WPA2 brought AES and lasted fourteen years as the standard. WPA3 fixes the
one weakness WPA2 kept, which is the subject of the next two sections.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A timeline of Wi-Fi security. WEP, 1997, with RC4 and a CRC, broken by 2001, drawn in red. WPA, 2003, RC4 with TKIP, an emergency repair, deprecated in 2012. WPA2, 2004, AES-CCMP, the standard until 2018. WPA3, 2018, AES with SAE replacing the passphrase-derived key, drawn in blue.\"><defs><marker id=\"gen-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><polyline points=\"30,150 700,150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#gen-ah-wire)\"></polyline><rect x=\"40\" y=\"40\" width=\"150\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">WEP</text><text x=\"115\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">RC4 + CRC-32</text><text x=\"115\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">broken by 2001</text><polyline points=\"115,120 115,146\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"115\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1997</text><rect x=\"205\" y=\"40\" width=\"150\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">WPA</text><text x=\"280\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">RC4 + TKIP</text><text x=\"280\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a repair, retired</text><polyline points=\"280,120 280,146\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"280\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2003</text><rect x=\"370\" y=\"40\" width=\"150\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">WPA2</text><text x=\"445\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">AES-CCMP</text><text x=\"445\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passphrase is everything</text><polyline points=\"445,120 445,146\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"445\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2004</text><rect x=\"535\" y=\"40\" width=\"150\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">WPA3</text><text x=\"610\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">AES + SAE</text><text x=\"610\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">current</text><polyline points=\"610,120 610,146\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></polyline><text x=\"610\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2018</text></svg>", "caption": "Each generation exists because the one before it failed. Red: broken; blue: current."}
```

## WEP: the right primitive, used wrongly

WEP, *Wired Equivalent Privacy* (1997), encrypted each frame with RC4, a stream cipher. RC4 needs
a key that never repeats, for the same reason as the counter modes of lesson 1. WEP's answer was
to stick a 24-bit IV in front of the shared key and send the IV in clear with the frame. That made
three mistakes at once:

- **24 bits run out.** There are only about 16.7 million IVs. A busy network goes through them in
  hours, and many cards started at zero every time they were switched on, so repeats came much
  sooner. Every repeat is a reused keystream.
- **The key and the IV were combined by concatenation**, and RC4's first output bytes leak
  information about its key when keys are related like that. With enough frames the shared key
  itself could be computed, and published tools did it in minutes.
- **The integrity check was a CRC-32**, a checksum for line noise rather than a MAC. A CRC is
  linear, so changing chosen bits of a frame and fixing the checksum to match needs no key at all.

On top of those, every device on the network used the same key, and nothing changed it
automatically. Changing a WEP key meant visiting every device.

**The lesson for a defender is short: WEP is not a security setting.** A device that can only
speak WEP is treated as a device with no encryption. It goes on an isolated network of its own,
with nothing on that network worth reading, until it is replaced.

## WPA and TKIP: a repair under a constraint

The industry needed a fix in 2003 for millions of cards that could only run RC4 in hardware. WPA
introduced **TKIP**, which kept RC4 and changed everything around it. It mixed a fresh key for
every frame from a 48-bit counter, added a real message check called Michael and refused frames
whose counter went backwards. It was an emergency measure designed to be replaced, and it was. The
2012 standard deprecated TKIP, and current equipment refuses it.

## WPA2: AES and CCMP

WPA2 (2004) replaced the cipher entirely: **CCMP**, which is AES in counter mode with a CBC-MAC tag.
That is authenticated encryption, the property lesson 1 asked of GCM, built from the same block
cipher with a different construction. Nothing practical has been found against CCMP itself in twenty
years. What WPA2 kept is how the key is agreed when the network has a password. The next section
computes that key, and the one after it shows why the password is then the whole of the security.

| | cipher | integrity | status |
| --- | --- | --- | --- |
| WEP | RC4, 24-bit IV | CRC-32 | broken; treat as open |
| WPA | RC4 with TKIP | Michael | deprecated since 2012 |
| WPA2 | AES-CCMP | CBC-MAC | sound, if the passphrase is |
| WPA3 | AES-CCMP or GCMP | CBC-MAC or GMAC | current |
