---
title: "SAML: the same job in signed XML"
version: 1
---

**SAML 2.0 solves the problem OpenID Connect solves, signing a person in to one application with an
account kept somewhere else, and it solved it first**: OASIS published it in 2005, nine years
before OpenID Connect. Its home is the company. When a firm buys a tool and wants its staff to sign
in with their work accounts, the tool is usually expected to speak SAML.

The vocabulary differs and the roles map across:

| SAML | what it is | nearest in OpenID Connect |
|---|---|---|
| **identity provider** (IdP) | the service that knows the person and signs them in | the authorization server |
| **service provider** (SP) | the application the person wants to use | the client |
| **assertion** | a signed XML document saying who the person is | the ID token |
| **metadata** | an XML file each side publishes: addresses, certificate | discovery and JWKS |

## The browser POST binding

The two servers never talk to each other during a sign-in. **The assertion travels through the
browser, in a form the identity provider's page posts to the service provider by itself**, and
that is why everything depends on its signature.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 500\" role=\"img\" aria-label=\"The SAML browser POST binding. Once, at set-up, the service provider and the identity provider exchange metadata with addresses and the certificate. At sign-in: the browser asks the service provider for a page, is redirected to the identity provider with a SAMLRequest, Ana signs in there, the identity provider answers with a page whose form holds the signed SAMLResponse, the browser posts it to the service provider&#x27;s /saml/acs, the service provider checks the signature with the certificate it already holds and then the audience, recipient, times, InResponseTo and ID, and answers with a session cookie. The two servers never talk during the sign-in.\"><defs><marker id=\"l09-saml-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"160\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">browser</text><text x=\"100.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Ana</text><line x1=\"100\" y1=\"60\" x2=\"100\" y2=\"480\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"300\" y=\"14\" width=\"160\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">service provider</text><text x=\"380.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">books.shelf.example</text><line x1=\"380\" y1=\"60\" x2=\"380\" y2=\"480\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"550\" y=\"14\" width=\"160\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">identity provider</text><text x=\"630.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">idp.shelf.example</text><line x1=\"630\" y1=\"60\" x2=\"630\" y2=\"480\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"380\" y1=\"92\" x2=\"630\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-saml-ah)\" marker-start=\"url(#l09-saml-ah)\"></line><text x=\"505.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">metadata, once, at set-up</text><text x=\"505.0\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">addresses and the certificate</text><line x1=\"100\" y1=\"150\" x2=\"380\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\"></line><text x=\"240.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET /library</text><line x1=\"380\" y1=\"196\" x2=\"100\" y2=\"196\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\"></line><text x=\"240.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">302 to the IdP, with a SAMLRequest</text><line x1=\"100\" y1=\"242\" x2=\"630\" y2=\"242\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\"></line><text x=\"365.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET /sso?SAMLRequest=…</text><line x1=\"630\" y1=\"288\" x2=\"100\" y2=\"288\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\" marker-start=\"url(#l09-saml-ah)\"></line><text x=\"365.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Ana signs in</text><line x1=\"630\" y1=\"334\" x2=\"100\" y2=\"334\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\"></line><text x=\"365.0\" y=\"326.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">200: a form holding the signed SAMLResponse</text><line x1=\"100\" y1=\"380\" x2=\"380\" y2=\"380\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\"></line><text x=\"240.0\" y=\"372.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /saml/acs  SAMLResponse=…</text><rect x=\"392\" y=\"390\" width=\"236\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"510\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">checks the signature with the IdP</text><text x=\"510\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">certificate it already holds, then</text><text x=\"510\" y=\"434\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Audience, Recipient, times, ID</text><line x1=\"380\" y1=\"452\" x2=\"100\" y2=\"452\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\"></line><text x=\"240.0\" y=\"444.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">302 to /library, with a session cookie</text><text x=\"20\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"20\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"20\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"20\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"20\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"20\" y=\"380\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"20\" y=\"452\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text></svg>", "caption": "The browser POST binding. The assertion reaches the service provider through the browser, so the signature, checked with a certificate exchanged beforehand, is the only thing vouching for it."}
```

The service provider holds the identity provider's certificate before any sign-in, from the
metadata exchanged when the two were set up. It verifies the assertion with **that** certificate,
never with one the message brings along, since a message can bring any certificate it likes.

## An assertion, signed and changed

The lab has no SAML library, and one is not needed to see what matters: what the identity provider
signs, and what the service provider's check does with a change. First a key and a certificate for
the identity provider. `genpkey -quiet` makes the key without printing its progress, and `req -x509`
makes a self-signed certificate from it:

```
ana@api:~/shelf$ openssl genpkey -quiet -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out saml/idp-key.pem
ana@api:~/shelf$ openssl req -x509 -new -key saml/idp-key.pem -subj /CN=idp.shelf.example -days 365 -out saml/idp-cert.pem
ana@api:~/shelf$ openssl x509 -in saml/idp-cert.pem -noout -subject -enddate
subject=CN = idp.shelf.example
notAfter=Oct 10 04:31:04 2027 GMT
```

Now the assertion. Save it as `~/shelf/saml/assertion.xml`. It is a template: the `ds:Signature`
element is there with its values empty, and signing fills them. The times in it are fixed values,
since nothing in this exercise checks them:

```xml
<!-- shelf/saml/assertion.xml -->
<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                ID="_8f2c41d6e0a94b7f" Version="2.0" IssueInstant="2026-10-10T12:00:00Z">
  <saml:Issuer>https://idp.shelf.example</saml:Issuer>
  <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
    <ds:SignedInfo>
      <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
      <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
      <ds:Reference URI="#_8f2c41d6e0a94b7f">
        <ds:Transforms>
          <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
          <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
        </ds:Transforms>
        <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
        <ds:DigestValue/>
      </ds:Reference>
    </ds:SignedInfo>
    <ds:SignatureValue/>
  </ds:Signature>
  <saml:Subject>
    <saml:NameID>ana@shelf.example</saml:NameID>
    <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
      <saml:SubjectConfirmationData InResponseTo="_req4c1e" NotOnOrAfter="2026-10-10T12:05:00Z"
                                    Recipient="https://books.shelf.example/saml/acs"/>
    </saml:SubjectConfirmation>
  </saml:Subject>
  <saml:Conditions NotBefore="2026-10-10T11:59:30Z" NotOnOrAfter="2026-10-10T12:05:00Z">
    <saml:AudienceRestriction>
      <saml:Audience>https://books.shelf.example/saml</saml:Audience>
    </saml:AudienceRestriction>
  </saml:Conditions>
  <saml:AuthnStatement AuthnInstant="2026-10-10T12:00:00Z">
    <saml:AuthnContext>
      <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</saml:AuthnContextClassRef>
    </saml:AuthnContext>
  </saml:AuthnStatement>
  <saml:AttributeStatement>
    <saml:Attribute Name="role">
      <saml:AttributeValue>reader</saml:AttributeValue>
    </saml:Attribute>
  </saml:AttributeStatement>
</saml:Assertion>
```

Read it from the top. `Issuer` names the identity provider. `Subject` names the person, and its
`SubjectConfirmationData` says which request this answers (`InResponseTo`), where it may be
delivered (`Recipient`) and until when. `Conditions` gives the window it is valid in and the one
service provider it is for (`Audience`). `AuthnStatement` says how the person proved who they
were. `AttributeStatement` carries facts about them, here a role.

The signature's `Reference` points at the assertion by its `ID`. **`--id-attr:ID` tells `xmlsec1`
which attribute holds an element's id**, since XML does not say so by itself, and signing fills
the digest and the signature value:

```
ana@api:~/shelf$ xmlsec1 --sign --privkey-pem saml/idp-key.pem --id-attr:ID urn:oasis:names:tc:SAML:2.0:assertion:Assertion --output saml/signed.xml saml/assertion.xml
ana@api:~/shelf$ sed -n '/<ds:DigestValue>/p; /<ds:SignatureValue>/,/<\/ds:SignatureValue>/p' saml/signed.xml
        <ds:DigestValue>VjIXV2lRxa4hMowfNm8k5ZxkaTdNjtJpl0a5Cfae+fs=</ds:DigestValue>
    <ds:SignatureValue>T8t3L0jchEw03By2w/qZ0Mc2EVPtDcJsy18aVy96zt72YEOukRHb0rhQiLWq3yJ9
oBZlyGeRdM+PMc4VAF8UDv8vfmdPdoLgsdVpzscl8TWPLa1J+V++Z6Tg1JxeDyQl
Zytq5m9fw2wGDzbL7fpo2wLVqWWNfIQliyXPhPbk5ocSGQ/rd707Uk7+B6SDO9Tr
Ydvm4jlg5+YzUQdYdnsYvKjAQ36uF0rfTlubVje0uv2m7OJa1BmmZ2Kp+8TGXrDF
Wt97mTdSbXkGdBkhnqld+SaZcYeGa+LDHEA/wd84WkRov42HxonjuJZnA+A7D6sO
ms3U2OutI0+LnP+uPqLigw==</ds:SignatureValue>
```

The digest is a SHA-256 of the assertion itself, so if your file is the lesson's byte for byte,
your digest is the one above. The signature value depends on the key as well, and yours differs.

The service provider's check, with the identity provider's certificate:

```
ana@api:~/shelf$ xmlsec1 --verify --pubkey-cert-pem saml/idp-cert.pem --id-attr:ID urn:oasis:names:tc:SAML:2.0:assertion:Assertion saml/signed.xml
OK
SignedInfo References (ok/all): 1/1
Manifests References (ok/all): 0/0
```

Now change one word, `reader` to `admin`, as anything on the way through the browser could:

```
ana@api:~/shelf$ sed 's/>reader</>admin</' saml/signed.xml > saml/changed.xml
ana@api:~/shelf$ diff saml/signed.xml saml/changed.xml
43c43
<       <saml:AttributeValue>reader</saml:AttributeValue>
---
>       <saml:AttributeValue>admin</saml:AttributeValue>
ana@api:~/shelf$ xmlsec1 --verify --pubkey-cert-pem saml/idp-cert.pem --id-attr:ID urn:oasis:names:tc:SAML:2.0:assertion:Assertion saml/changed.xml
func=xmlSecOpenSSLEvpDigestVerify:file=digests.c:line=355:obj=sha256:subj=unknown:error=12:invalid data:data and digest do not match
FAIL
SignedInfo References (ok/all): 0/1
Manifests References (ok/all): 0/0
Error: failed to verify file "saml/changed.xml"
```

**The digest of the signed element no longer matches the one inside the signature**, so the
reference fails and so does the file. Without the signature the change would be invisible: the
XML is still well formed, and a service provider that only parsed it would give Ana an
administrator's role.

## What the signature does not check

The times in the assertion are a window of five and a half minutes on 10 October 2026, and
whenever you run this you are almost certainly outside it; `xmlsec1` printed `OK` all the same,
because it checks signatures and knows nothing of SAML. **A valid signature says who wrote the
assertion and that nobody changed it; everything else is the service provider's to check**:

- `Audience` is this service provider, and `Recipient` is the address it arrived at;
- the time now is inside `NotBefore` and `NotOnOrAfter`;
- `InResponseTo` names a request this service provider sent, and the assertion's `ID` has not been
  seen before, which stops the same assertion being posted twice;
- the element the application reads is the element the signature covers. An XML document can carry
  more than one assertion, and a check that verifies one and reads another has verified nothing.

That last rule is why nobody should parse SAML with their own code. **Use a maintained SAML
library on the service provider's side**, and keep it updated: the mistakes in this format are in
its corners, and they have been found in libraries for years.
