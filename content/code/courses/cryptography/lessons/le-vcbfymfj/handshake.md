---
title: The four-way handshake, and what a recording of it gives away
version: 1
---

**The PMK never crosses the air. When a device joins, it and the access point prove to each other
that they hold it and derive fresh keys for that session, in four messages called the four-way
handshake.** It is a sound design for that job. What it cannot do is protect a weak passphrase,
and this section shows why.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The four-way handshake between a device on the left and an access point on the right, both already holding the PMK. Message 1, from the access point: the ANonce, in clear. Message 2, from the device: the SNonce and a MIC, in clear. Message 3, from the access point: its MIC and the group key, encrypted. Message 4, from the device: a confirmation. Messages 1 and 2 are marked in red as what a recording captures: both nonces and a MIC that tests a passphrase guess.\"><defs><marker id=\"hs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"hs-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">device</text><text x=\"125\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">holds the PMK</text><rect x=\"510\" y=\"20\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">access point</text><text x=\"595\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">holds the PMK</text><polyline points=\"125,66 125,300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"595,66 595,300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></polyline><rect x=\"140\" y=\"82\" width=\"440\" height=\"104\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><polyline points=\"593,110 127,110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-amber)\"></polyline><text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 ANonce</text><polyline points=\"127,160 593,160\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-amber)\"></polyline><text x=\"360\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 SNonce + MIC</text><polyline points=\"593,220 127,220\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 MIC + group key (encrypted)</text><polyline points=\"127,270 593,270\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"259\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4 confirm, install keys</text><text x=\"360\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">both now derive the PTK from PMK, ANonce, SNonce and both addresses</text></svg>", "caption": "Messages 1 and 2, in red, are all a recording needs to test passphrase guesses offline."}
```

## Four messages

1. The access point sends a random number, the **ANonce**.
2. The device picks its own random number, the **SNonce**. It now has everything it needs to derive the
   session key, the **PTK** (*pairwise transient key*), from the PMK, both nonces and both hardware
   addresses. It sends the SNonce with a **MIC**, a message check computed with part of the PTK.
3. The access point derives the same PTK, checks the MIC, and so learns that the device knew the PMK.
   It replies with its own MIC and the **group key** (GTK), encrypted, which every device uses for
   broadcast traffic.
4. The device confirms, and both install the keys. From here on, frames are encrypted with CCMP under
   the PTK.

Every session gets a new PTK because the nonces are new. The PMK itself is only used to derive keys,
the role a server's RSA key played in TLS before lesson 7's Diffie-Hellman became the rule.

## What somebody nearby records

Everything in messages 1 and 2 is in clear: both nonces, both addresses, and a MIC. Somebody within
radio range who records a device joining therefore holds a test. They take a guessed passphrase,
compute the PMK from it and the SSID with the function of the previous section, derive the PTK and
compute the MIC. If it matches the recorded one, the guess was right.

**That test runs offline, as fast as the guesser's hardware allows, and the network never sees it.**
There is no failed login to count, no lockout and no log line. Nothing a defender monitors will show
it. On some access points even a joining client is unnecessary, because the first message carries a
value derived from the PMK as well. The conclusion is the same either way: the passphrase has to
survive guessing at full speed, for as long as the network keeps it.

The arithmetic at the previous section's two million guesses a second:

| passphrase | possibilities | time to try them all |
| --- | --- | --- |
| 8 lowercase letters | 26⁸ ≈ 2.1 × 10¹¹ | about 29 hours |
| 10 random letters and digits | 62¹⁰ ≈ 8.4 × 10¹⁷ | about 13,000 years |
| 5 random words from a 7,776-word list | 7,776⁵ ≈ 2.8 × 10¹⁹ | about 450,000 years |

Those figures assume a **random** passphrase. A phrase a person chose, like a song lyric or the
clinic's address, sits early in any list of guesses, whatever its length. Lesson 5's rule holds here
without its safety net: there is no slow hash to save a guessable password.

## The handshake also shares too much

Somebody who **knows** the passphrase and records another device's handshake can derive that
device's PTK too, and read its traffic. On a WPA2-Personal network, every person with the passphrase
can therefore decrypt every other person's session that they saw begin. There is no forward secrecy:
the PMK, plus a recording, opens everything. For a reception network carrying patients' phones that
is a shared café. For staff carrying clinical records it is not acceptable, which is why staff
networks use 802.1X (lesson 16) or WPA3 (next section).

## KRACK: an implementation bug in a sound protocol

In 2017 the **KRACK** research showed that many implementations, when message 3 arrived twice,
installed the same key again and reset its packet counter. That counter is the nonce of CCMP, so
the bug was a nonce reuse, the mistake lesson 1 warned about and lesson 17 returns to. The protocol
was fine; the code that ran it was not. Vendors patched clients and access points within months. The
defender's lesson is the boring one: a device that no longer receives updates still has the bug.
