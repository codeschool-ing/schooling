---
title: The server proves who it is, and both sides seal the transcript
version: 1
---

**After the hellos, the server sends its certificate chain, signs the whole conversation so far
with the certificate's private key, and closes with a MAC over everything.** The client checks all
three, then sends its own MAC. Four encrypted messages carry lessons 3, 6, 7, 8 and 9 at once. The
figure lays out the whole exchange of the previous section's capture, message by message:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"The TLS 1.3 handshake between the client and portal.vereda.example. The client sends ClientHello with its supported versions, cipher suites, the server name and an X25519 key share. The server answers with ServerHello, choosing TLS 1.3, TLS_AES_256_GCM_SHA384 and its own X25519 key share; from here both derive handshake keys and the rest is encrypted. The server then sends EncryptedExtensions, Certificate with the portal and issuing CA certificates, CertificateVerify signed with its P-256 key over the transcript, and Finished. The client checks the chain, the dates and the name, verifies the signature and the Finished MAC, and sends its own Finished, followed immediately by application data.\"><defs><marker id=\"hs-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"hs-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"90\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">client</text><text x=\"630\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">portal.vereda.example</text><polyline points=\"90,32 90,405\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"630,32 630,405\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"92,55 628,55\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-wire)\"></polyline><text x=\"360\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ClientHello</text><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">versions, suites, SNI, X25519 share</text><polyline points=\"628,105 92,105\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-wire)\"></polyline><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ServerHello</text><text x=\"360\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">TLS 1.3, AES-256-GCM, X25519 share</text><polyline points=\"628,175 92,175\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">EncryptedExtensions</text><polyline points=\"628,210 92,210\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Certificate</text><text x=\"360\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">portal + Vereda Issuing CA 1</text><polyline points=\"628,255 92,255\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CertificateVerify</text><text x=\"360\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">P-256 signature over the transcript</text><polyline points=\"628,300 92,300\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"291\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Finished</text><text x=\"360\" y=\"311\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">MAC over the transcript</text><polyline points=\"92,345 628,345\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"336\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Finished</text><text x=\"360\" y=\"356\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the client&#x27;s MAC</text><polyline points=\"92,385 628,385\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"376\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">application data</text><rect x=\"150\" y=\"131\" width=\"420\" height=\"2\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"0.5\"></rect><text x=\"360\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">encrypted from here, with keys from the X25519 exchange</text><text x=\"20\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checks chain,</text><text x=\"20\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dates, name</text></svg>", "caption": "One round trip: a hello each way, then everything else is encrypted."}
```

## EncryptedExtensions

The first encrypted message carries the server's answers to extensions that do not need to be in
the clear, such as which application protocol it chose (`h2` for HTTP/2 when the client offered it).
In the lab it is empty, two bytes long.

## Certificate

The server sends its chain: in the capture, `portal.vereda.example` and `Vereda Issuing CA 1`. Not
the root: the client must already have that, and a root sent by the server would prove nothing,
because anybody can send one. The client now runs every check of lesson 9:

- the chain leads to a root in its trust store, each signature verifying with the key above;
- every certificate is within its dates at the client's clock;
- the name the client asked for, here `portal.vereda.example`, is in the Subject Alternative Name;
- the key usages allow a TLS server;
- revocation, if the client checks it.

## CertificateVerify

A chain proves that a key belongs to a name. It does not prove that the machine answering **holds**
that key: the certificate is public, and anybody can send a copy. So the server signs a hash of the
**transcript**, every handshake message so far, with the certificate's private key. The capture
shows the algorithm: `ecdsa_secp256r1_sha256`, the P-256 key of lesson 9.

This is the signature that lesson 7 said defeats a man in the middle. The transcript includes both
key shares, so the signature binds the server's identity to **this** exchange. An attacker in the
middle ran a different exchange with the client and cannot produce a signature over it.

## Finished, both ways

Each side sends a **Finished** message: an HMAC, keyed from the handshake secret, over the whole
transcript. If anything in the hellos was changed in transit, for example a cipher suite list
trimmed to force a weaker choice, the two sides computed their transcripts over different bytes, the
MACs disagree, and the connection is dropped. The server's Finished arrives with its first flight;
the client sends its own and can send its first application data in the same flight, which is the
"one round trip" of TLS 1.3.

## And the client?

In ordinary web traffic, only the server proves its identity; the user signs in later, inside the
encrypted connection. TLS can authenticate the client too: the server sends a
`CertificateRequest`, and the client answers with its own certificate and `CertificateVerify`. This
is **mutual TLS**, used between internal services and for devices, and it is what 802.1X does on a
corporate Wi-Fi network in lesson 16.
