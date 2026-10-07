---
title: Agreeing on a key in public
version: 1
---

Symmetric encryption needs both ends to hold the same key, and the network is where the key cannot be
sent. **Key agreement** solves it with a pair of keys on each side: each party makes a private key and
a public key, they exchange only the public keys, and each combines **its own private key with the
other's public key**. The mathematics makes both combinations come out the same, and somebody who saw
only the two public keys cannot compute it.

The algorithm is **X25519**, elliptic-curve Diffie-Hellman on Curve25519. `laptop` and `app` each make
a pair and print the public half:

```
ana@laptop:~$ openssl genpkey -algorithm X25519 -out ana.key; openssl pkey -in ana.key -pubout -out ana.pub; cat ana.pub
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VuAyEA84o6hHj0QxUHnxfhUd9QBDfqfZ8gk7XhmmzgzLO4Ngg=
-----END PUBLIC KEY-----
ana@app:~$ openssl genpkey -algorithm X25519 -out app.key; openssl pkey -in app.key -pubout -out app.pub; cat app.pub
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VuAyEAXqvs8rPoiR1c5rUiQoemyebaBEzVltV928cFbPRcvCg=
-----END PUBLIC KEY-----
```

The public keys are copied to each other. In the lab the copy is
made from your own computer, where each machine's home directory is a folder under `/lab`:

```sh
sudo cp /lab/app/home/$USER/app.pub /lab/laptop/home/$USER/
sudo cp /lab/laptop/home/$USER/ana.pub /lab/app/home/$USER/
```

They are all that crossed between the two machines. Each side then derives the
shared secret from its own private key and the other's public key, and shows a hash of it rather than
the secret itself:

```
ana@laptop:~$ openssl pkeyutl -derive -inkey ana.key -peerkey app.pub | sha256sum
72338c44083582a3ee3985bcc7dc586b4109b1c4618220644dcb13513c29c5a2  -
ana@app:~$ openssl pkeyutl -derive -inkey app.key -peerkey ana.pub | sha256sum
72338c44083582a3ee3985bcc7dc586b4109b1c4618220644dcb13513c29c5a2  -
```

**The same 32 bytes on both machines**, and they never travelled. That secret becomes the key for a
symmetric cipher like the one in the previous section.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Key agreement between laptop and app. Each makes a private key, which never leaves it, and a public key. Only the public keys cross the network. laptop combines its private key with app&#x27;s public key; app combines its private key with laptop&#x27;s public key. Both results are the same shared secret, and it never crossed the network.\"><defs><marker id=\"ka-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"ka-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"30\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">private key: stays here</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"510\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">private key: stays here</text><path d=\"M220 50 L500 50\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#ka-ah-phosphor)\" marker-start=\"url(#ka-ah-phosphor)\"></path><text x=\"360\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ana.pub → ← app.pub</text><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">only the public keys cross</text><rect x=\"20\" y=\"110\" width=\"200\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ana.key + app.pub</text><rect x=\"500\" y=\"110\" width=\"200\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app.key + ana.pub</text><path d=\"M120 66 L120 110\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ka-ah-paper-dim)\"></path><path d=\"M600 66 L600 110\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ka-ah-paper-dim)\"></path><rect x=\"230\" y=\"176\" width=\"260\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">the same shared secret</text><path d=\"M120 140 L120 191 L230 191\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#ka-ah-phosphor)\"></path><path d=\"M600 140 L600 191 L490 191\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#ka-ah-phosphor)\"></path></svg>", "caption": "What crossed the network is enough to check the result and not enough to compute it."}
```

Two properties of this exchange decide how it is used:

- **It proves nothing about identity.** `laptop` computed a secret shared with *whoever* holds the
  private key matching `app.pub`. If somebody had swapped `app.pub` for their own on the way, `laptop`
  would share a secret with them instead, perfectly encrypted. Knowing whose public key you hold is the
  whole subject of lessons 11 and 12.
- **Fresh pairs give forward secrecy.** When both sides make new key pairs for each session and throw
  them away afterwards, stealing a long-term key later does not unlock recordings of old sessions.
  TLS 1.3 and WireGuard both do this.
