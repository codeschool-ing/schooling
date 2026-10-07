---
title: Roots, issuing CAs and the chain between them
version: 1
---

**Certificate authorities are arranged in a hierarchy: a root signs one or more issuing CAs, and the
issuing CAs sign servers.** Each certificate names the one above it as its issuer, and following
those names upwards is the chain a browser checks. Vereda runs a small one of its own, built by the
lab, and it has the same shape as every public CA.

## Three levels

```
ana@lab:~/lab$ for c in root issuing1 portal; do openssl x509 -in pki/$c.pem -noout -subject -issuer; echo; done
subject=C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA

subject=C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA

subject=C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
```

Read the pairs from the bottom. The portal's certificate was issued by *Vereda Issuing CA 1*. The
issuing CA's certificate was issued by *Vereda Root CA*. And the root's certificate was issued by
itself: subject and issuer are the same name. A root is **self-signed**, because there is nobody
above it to sign. Its authority does not come from its certificate at all; it comes from being on a
list of roots somebody decided to trust, the subject of the next section.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Vereda&#x27;s chain of three certificates. At the top, Vereda Root CA, self-signed, kept offline and placed in the trust store of clients that should trust it. It signs Vereda Issuing CA 1, which has pathlen 0. That signs portal.vereda.example, which is not a CA. The server sends its own certificate and the issuing CA&#x27;s; the client holds only the root.\"><defs><marker id=\"chain-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"300\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Vereda Root CA</text><text x=\"56\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">self-signed, CA:TRUE, pathlen:1</text><rect x=\"40\" y=\"110\" width=\"300\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Vereda Issuing CA 1</text><text x=\"56\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CA:TRUE, pathlen:0</text><rect x=\"40\" y=\"200\" width=\"300\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">portal.vereda.example</text><text x=\"56\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CA:FALSE, TLS server only</text><polyline points=\"190,82 190,108\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#chain-ah-wire)\"></polyline><text x=\"204\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">signs</text><polyline points=\"190,172 190,198\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#chain-ah-wire)\"></polyline><text x=\"204\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">signs</text><rect x=\"420\" y=\"20\" width=\"280\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"436\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">in the client&#x27;s trust store</text><text x=\"436\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">offline, in an HSM, at Vereda</text><rect x=\"420\" y=\"110\" width=\"280\" height=\"152\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"436\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sent by the server</text><text x=\"436\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">portal-chain.pem</text><polyline points=\"342,51 418,51\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"342,141 418,141\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"342,231 418,231\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></polyline></svg>", "caption": "Each certificate is signed by the one above; the root by itself."}
```

## What each level is allowed to do

The certificates say what their keys may be used for, in extensions marked `critical`, which a
verifier must understand or refuse:

```
ana@lab:~/lab$ openssl x509 -in pki/root.pem -noout -ext basicConstraints,keyUsage
X509v3 Basic Constraints: critical
    CA:TRUE, pathlen:1
X509v3 Key Usage: critical
    Certificate Sign, CRL Sign
ana@lab:~/lab$ openssl x509 -in pki/issuing1.pem -noout -ext basicConstraints
X509v3 Basic Constraints: critical
    CA:TRUE, pathlen:0
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -ext basicConstraints,extendedKeyUsage
X509v3 Basic Constraints: critical
    CA:FALSE
X509v3 Extended Key Usage: 
    TLS Web Server Authentication
```

- the root is a CA (`CA:TRUE`) whose key may sign certificates and revocation lists, with
  `pathlen:1`: at most one more CA may sit below it;
- the issuing CA is a CA with `pathlen:0`: it may sign servers but not create further CAs;
- the portal's certificate is **not** a CA (`CA:FALSE`), and its key may only authenticate a TLS
  server. A server certificate that could sign other certificates would let anybody who compromised
  one web server mint certificates for any name.

## Checking the chain

`openssl verify` walks it, given the root as trusted and the issuing CA as an untrusted helper:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -show_chain -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal.pem
pki/portal.pem: OK
Chain:
depth=0: C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example (untrusted)
depth=1: C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1 (untrusted)
depth=2: C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA
```

`depth=0` is the portal, `depth=2` the root. The two lower certificates are marked `(untrusted)`
because they are only believed once the signature above them checks out; the root is trusted because
it was passed with `-CAfile`. A server must send its own certificate **and** the issuing CA's; the
client is expected to hold only the root. A server that forgets the intermediate is the commonest
chain error there is, and the next section produces it on purpose.

## Why not sign servers with the root directly

- **The root key is the one thing that cannot be replaced quickly.** Replacing a root means getting
  a new one into every trust store, which takes years. So it lives offline, in a hardware security
  module in a safe, and is switched on a few times a year to sign issuing CAs and revocation lists.
- **An issuing CA can be revoked and replaced** in an afternoon, by the root, if its key leaks.
- **Issuing CAs can be specialised**: one for servers, one for client devices, one per region, each
  with constraints on what it may sign.

The same reasons apply to an **internal** CA like Vereda's. Companies run one for services that
never face the public internet: internal APIs, mutual TLS between services, VPN clients, Wi-Fi with
802.1X (lesson 16). Tools such as step-ca, HashiCorp Vault and Microsoft AD CS do the work; the
decisions are the ones above, plus one more: an internal root has to be **distributed** to every
client that should trust it, because no browser ships it.
