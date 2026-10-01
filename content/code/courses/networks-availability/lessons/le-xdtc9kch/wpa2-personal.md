---
title: WPA2-Personal, one passphrase for everybody
version: 1
---

On an **open network nothing is encrypted**. Every frame after the radio header can be read by any receiver in range. That is why a coffee shop's Wi-Fi is only as private as whatever runs on top of it,
HTTPS for instance (lesson 5 of `networks`). WPA2-Personal adds encryption with one shared secret, the
**passphrase**: 8 to 63 characters, typed on every device.

## From passphrase to key

The passphrase is not the key. Both the AP and the client turn it into a 256-bit **PMK**, the pairwise
master key, with the same function, and the whole derivation fits in one line of Python:

```schooling-example
{"language": "python", "file": "psk.py", "parts": [{"code": "import hashlib\nimport math", "note": "Nothing to install: PBKDF2 is in Python's standard library, because it is an ordinary way to turn a password into a key."}, {"code": "def pmk(passphrase, ssid):\n    return hashlib.pbkdf2_hmac(\"sha1\", passphrase.encode(), ssid.encode(), 4096, 32)", "note": "The whole WPA2-Personal key derivation. The passphrase is hashed 4,096 times with HMAC-SHA1, salted with the network's name, and 32 bytes come out: the PMK, 256 bits."}, {"code": "print(\"password @ IEEE     \", pmk(\"password\", \"IEEE\").hex())\nprint(\"password @ IEEE-2   \", pmk(\"password\", \"IEEE-2\").hex())\nprint()", "note": "The first line is the test vector the 802.11 standard publishes, passphrase `password` on the network `IEEE`, and the key printed below is the one the standard gives. The second changes only the network's name."}, {"code": "choices = [\n    (\"8 lowercase letters\", 26, 8),\n    (\"10 letters and digits\", 62, 10),\n    (\"5 words from 7776\", 7776, 5),\n    (\"20 printable characters\", 94, 20),\n]", "note": "Four ways to choose a passphrase. Each is an alphabet and a length, and the size of the space somebody would have to search is the alphabet raised to the length."}, {"code": "for name, alphabet, length in choices:\n    bits = length * math.log2(alphabet)\n    print(f\"{name:24} {bits:6.1f} bits  {float(alphabet) ** length:9.1e} candidates\")", "note": "Bits are the same count on a logarithmic scale: every extra bit doubles the space. Which one to aim for is the argument of the section below."}], "output": "password @ IEEE      f42c6fc52df0ebef9ebb4b90b38a5f902e83fe1b135a70e23aed762e9710a12e\npassword @ IEEE-2    9906cb57a6ddbdc32db106d33afe45b8b2713ea52d1abb8a4b8ed6025c7b8c4b\n\n8 lowercase letters        37.6 bits    2.1e+11 candidates\n10 letters and digits      59.5 bits    8.4e+17 candidates\n5 words from 7776          64.6 bits    2.8e+19 candidates\n20 printable characters   131.1 bits    2.9e+39 candidates"}
```

The first line of the output matches the test vector in the 802.11 standard, so the function above is the
real one. The second line shows why the network's name goes in: **the same passphrase on a network with a
different SSID gives an unrelated key.** The name is the salt, which makes work done against one network
useless against another. A network still called by the router's factory name shares its salt with every
other one that kept it.

## The four-way handshake

Knowing the PMK is what a client has to prove, and it proves it without sending it. When a client
associates, the AP and the client exchange four EAPOL-Key messages:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 378\" role=\"img\" aria-label=\"A sequence between a client on the left and an access point on the right, both of which already hold the PMK. Message 1, from the AP: ANonce, a random number. Message 2, from the client: SNonce and a MIC; the client can now compute the PTK. Message 3, from the AP: the group key, GTK, encrypted, and a MIC, which proves the AP holds the PMK. Message 4, from the client: an acknowledgement and a MIC. Then the keys are installed and traffic is encrypted with the PTK. The PMK itself never crosses the air.\"><defs><marker id=\"hs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"80\" y=\"16\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client</text><text x=\"150.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">the station</text><rect x=\"480\" y=\"16\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">access point</text><text x=\"550.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">AP</text><path d=\"M150 56 L150 330\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M550 56 L550 330\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"250\" y=\"66\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">both already hold the PMK</text><text x=\"350\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1  ANonce, a random number</text><path d=\"M550 124 L156 124\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"350\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2  SNonce, and a MIC</text><path d=\"M150 174 L544 174\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"350\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">client can now compute the PTK</text><text x=\"350\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3  the group key (GTK), encrypted, and a MIC</text><path d=\"M550 224 L156 224\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"350\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the MIC proves the AP holds the PMK</text><text x=\"350\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4  acknowledgement, and a MIC</text><path d=\"M150 274 L544 274\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><rect x=\"200\" y=\"318\" width=\"300\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"331\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">keys installed: traffic encrypted with the PTK</text><text x=\"350\" y=\"362\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the PMK itself never crosses the air</text></svg>", "caption": "The four-way handshake of WPA2, which WPA3 keeps. Each side proves it holds the PMK by computing a MIC with keys derived from it; the key is never sent. Drawn from the standard: the lab has no radio to capture one."}
```

Each side contributes a random number, the ANonce and the SNonce. From the PMK, the two nonces and the
two MAC addresses, both compute the same **PTK**, the pairwise transient key, fresh for this association.
Part of the PTK signs each message from 2 onwards with a MIC, a message integrity code, so a side that got
the PMK wrong produces a MIC the other rejects. Message 3 also delivers the **GTK**, the group key for
broadcast frames, encrypted. After message 4, data is encrypted with AES in CCMP mode.

## Why the length of the passphrase matters

Messages 1 and 2 cross the air in clear: both nonces, both addresses and a MIC computed from the PMK. So
**one recorded handshake lets anybody test guesses at the passphrase offline**, as fast as their hardware
runs PBKDF2, with no further contact with the network and nothing in any log. The defence is not a
setting. It is a passphrase whose search space is too large to cover, and the example's table puts
numbers on it.

**Eight lowercase letters is 37.6 bits, 2.1e+11 candidates**, and that is if they were random. Five words
picked at random from a list of 7,776 is 64.6 bits, about 136 million times as many. Twenty random
printable characters is 131.1 bits. A person's own choice, a word with a year after it, is far smaller than
its alphabet suggests, because the guesses are tried in order of likelihood. **Use a random passphrase of
20 characters or more, or five or more words chosen at random**, and store it in a password manager.

Two weaknesses survive any length, because they come from the key being shared:

- Anybody who knows the passphrase can read other clients' traffic if they recorded those clients'
  handshakes, since everything else that goes into the PTK is sent in clear. WPA2-Personal keeps out
  strangers, not colleagues.
- There is no forward secrecy. A passphrase that leaks next year decrypts a recording made this year.

And when one person leaves, the only way to revoke them is to change the passphrase on every device.
WPA3 answers the first two; 802.1X, in the section on enterprise, answers the third.
