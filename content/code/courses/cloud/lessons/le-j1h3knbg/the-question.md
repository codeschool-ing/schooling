---
title: Who wants to do what, to which thing
version: 1
---

Everything that happens in a cloud account is an API call. Clicking *Delete* in a console, running
a command in a terminal, a program saving a file through the provider's library: each of them
becomes an HTTPS request to the provider's API, and each request is judged on its own. **A request
carries four facts: who is asking, what they want to do, which thing they want to do it to, and
under what circumstances.** The vocabulary for those four is the same at every provider:

| | the word | an example |
|---|---|---|
| who | the **principal** | the user `ana`, or a role a server is using |
| what | the action | `s3:GetObject`, read one object from a bucket |
| which thing | the resource | the object `2026/q3.csv` in the bucket `example-reports` |
| under what circumstances | the condition | signed in with MFA, from the office's address, over TLS |

## Access is a property of one request, not of a person

The picture most people arrive with is a person who "has access to production", as if access were
a badge somebody wears. The provider never asks that question. It asks whether *this* request, from
*this* principal, for *this* action on *this* resource, *now*, is allowed. "Ana may read the objects
under `2026/` in the reports bucket, when she has signed in with MFA" is the shape of every answer,
and each of its four parts can be the reason a request fails.

Take one command, which copies an object out of a bucket like the ones in lesson 5:

```sh
aws s3 cp s3://example-reports/2026/q3.csv .
```

It becomes one request. The principal is whichever identity's credentials signed it. The action is
`s3:GetObject`. The resource is named by an **ARN**, an Amazon Resource Name, which here is
`arn:aws:s3:::example-reports/2026/q3.csv`; the empty fields between the colons are the region and
the account number, which a bucket's name does not need because bucket names are global. The
circumstances come along without anybody writing them: the address the request came from, the time,
whether the session was opened with a second factor, whether it travelled over TLS. AWS calls those
**context keys** and names them `aws:SourceIp`, `aws:CurrentTime`, `aws:MultiFactorAuthPresent` and
`aws:SecureTransport`, and a policy can test any of them.

## Two gates, in this order

The request passes two checks, and they answer different questions.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 800 300\" role=\"img\" aria-label=\"A request on the left carries four things: who is asking, the user ana; what, the action s3:GetObject; which thing, the object example-reports/2026/q3.csv; and the circumstances, signed in with MFA from an office address. It passes two gates in turn. The first, authentication, asks who is asking and checks the signature against a credential the provider knows; a request it cannot tie to an identity is refused there. The second, authorisation, asks whether that identity may do this, by reading every policy that applies; a request no policy allows is refused there with AccessDenied. Only a request that passes both reaches the service, which returns the object.\"><defs><marker id=\"gat-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"230\" height=\"206\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">the request</text><text x=\"34\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">who</text><text x=\"34\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">ana</text><text x=\"34\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what</text><text x=\"34\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">s3:GetObject</text><text x=\"34\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">which thing</text><text x=\"34\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">example-reports/2026/q3.csv</text><text x=\"34\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">circumstances</text><text x=\"34\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">signed in with MFA</text><text x=\"34\" y=\"203\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">from an office address</text><rect x=\"290\" y=\"60\" width=\"170\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"375\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">authentication</text><text x=\"375\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">who is asking?</text><text x=\"375\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">checks the signature</text><text x=\"375\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">against a known credential</text><rect x=\"500\" y=\"60\" width=\"170\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">authorisation</text><text x=\"585\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">may they do this?</text><text x=\"585\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reads every policy</text><text x=\"585\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">that applies</text><rect x=\"706\" y=\"70\" width=\"80\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"746\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">the service</text><text x=\"746\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">returns</text><text x=\"746\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the object</text><path d=\"M250 115 L290 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gat-ah)\"></path><path d=\"M460 115 L500 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gat-ah)\"></path><path d=\"M670 115 L706 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gat-ah)\"></path><path d=\"M375 170 L375 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#gat-ah)\"></path><rect x=\"282\" y=\"222\" width=\"186\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"375\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused: no identity</text><text x=\"375\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the policies are never read</text><path d=\"M585 170 L585 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#gat-ah)\"></path><rect x=\"492\" y=\"222\" width=\"186\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"585\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused: AccessDenied</text><text x=\"585\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no policy allowed it</text></svg>", "caption": "Every call to a cloud API passes two gates. The first settles who is asking; the second decides whether that identity may do this to this thing, now. The rest of this lesson is about the second gate."}
```

**Authentication asks who is asking.** Every request is signed with a secret the caller holds (AWS
calls its scheme Signature Version 4), and the provider checks the signature against a credential it
knows. A request with no signature, a wrong one or an expired credential never reaches the second
gate; nothing in any policy is read for it.

**Authorisation asks whether that identity may do this.** The provider collects every policy that
applies to the request and decides. Most of this lesson is about that decision: what a policy says,
how several of them combine, and how to write ones that allow the job and nothing next to it.

You met the same split in HTTP, in the `networks` course, under names that confuse everybody once.
Status `401 Unauthorized` means the first gate failed: the server does not know who you are, and
"unauthorised" is a historical misnomer for "unauthenticated". Status `403 Forbidden` means the
second one did: it knows exactly who you are, and the answer is no. Cloud APIs do not all keep the
two numbers apart, so read the error code rather than the status. S3 answers a signature it cannot
verify with a 403 whose code is `SignatureDoesNotMatch`, the first gate; it answers a correctly
signed request that no policy allows with a 403 whose code is `AccessDenied`, the second.

This is also a different layer from lesson 6. A security group decides which **packets** reach a
virtual machine; identity and access decide which **API calls** succeed. A VM behind a perfect
security group can still be deleted by anybody holding a credential that allows
`ec2:TerminateInstances`, and no firewall rule will see it happen, because that request goes to the
provider's API and never to the machine.
