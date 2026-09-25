---
title: The chain of trust
version: 1
---

The laptop has never seen `www.example.com`'s certificate before. It trusts it because of who signed
it, and who signed them. `openssl s_client` prints the walk:

```
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com </dev/null 2>&1 | grep -E "^depth|^ *[0-9] s:|^ *i:|Verify return"
depth=2 O = Example Trust Services, CN = Example Root CA
depth=1 O = Example Trust Services, CN = Example Issuing CA 1
depth=0 CN = www.example.com
 0 s:CN = www.example.com
   i:O = Example Trust Services, CN = Example Issuing CA 1
 1 s:O = Example Trust Services, CN = Example Issuing CA 1
   i:O = Example Trust Services, CN = Example Root CA
Verify return code: 0 (ok)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The chain of trust for www.example.com. At depth 0, the server&#x27;s certificate, www.example.com, valid for 90 days, signed by Example Issuing CA 1, and sent by the server. At depth 1, Example Issuing CA 1, signed by the root, also sent by the server. At depth 2, Example Root CA, signed by itself, valid until 2036, which is not sent: the laptop already has it, in its trust store. The laptop checks each signature upwards until it reaches a certificate it already trusts.\"><defs><marker id=\"ch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"150\" y=\"20\" width=\"300\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"164\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Example Root CA</text><text x=\"164\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">signed by itself, valid until 2036</text><text x=\"20\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depth 2</text><text x=\"470\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">already on the laptop, in its trust store</text><rect x=\"150\" y=\"116\" width=\"300\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"164\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Example Issuing CA 1</text><text x=\"164\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">signed by the root</text><text x=\"20\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depth 1</text><text x=\"470\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sent by the server</text><path d=\"M300 114 L300 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"312\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">signed</text><rect x=\"150\" y=\"212\" width=\"300\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"164\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">www.example.com</text><text x=\"164\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">signed by Issuing CA 1, valid 90 days</text><text x=\"20\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depth 0</text><text x=\"470\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sent by the server</text><path d=\"M300 210 L300 176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"312\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">signed</text></svg>", "caption": "The server sends its own certificate and the intermediate; the root must already be on the client. Verification walks up the arrows and succeeds only if it ends at a root the client trusts."}
```

Read the `s:` (subject) and `i:` (issuer) pairs. **The server sent two certificates**: its own, `0`,
issued by `Issuing CA 1`, and `Issuing CA 1` itself, `1`, issued by the `Root CA`. It did not send the
root, and should not: **a root is trusted only because it is already on the client**, put there by
the operating system or the browser. The `depth=` lines are the laptop's checks, from the root at depth
2 down to the site at depth 0, and `Verify return code: 0 (ok)` is the result.

Why the middle certificate? The root's private key is the most valuable thing a certificate authority
has, so it is kept offline, and used only to sign a few **intermediate** certificates. The intermediates
sign the everyday certificates. If an intermediate is ever compromised, it can be revoked and replaced
without asking every computer in the world to change its list of roots.
