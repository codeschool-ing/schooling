---
title: Roles, the identity nobody logs into
version: 1
---

A **role** is an identity with permissions and with no password and no long-lived keys. Nobody signs
in as a role. It is **assumed**: something that already has an identity asks for the role, and if it
is allowed to, it receives a set of temporary credentials that act as the role until they expire.

The wrong picture comes from the word. In everyday English, and at Google Cloud and Azure as the
section on other providers shows, a role is a bundle of permissions, something like "editor". At AWS
it is not a bundle: it is a principal, the same kind of thing as a user, which is why it can appear
in the audit log making calls. The difference from a user is only how its credentials come to exist.

## What assuming a role hands out

At AWS the service that hands out temporary credentials is STS, the Security Token Service, and
the call is `sts:AssumeRole`. What comes back is four things:

- an access key id, which for temporary credentials begins with `ASIA`, where a user's long-lived one
  begins with `AKIA`;
- a secret access key;
- a session token, which has to travel with every request signed by the other two;
- an expiry.

By default the session lasts one hour. The caller can ask for as little as fifteen minutes, or for
more, up to a maximum set on the role between one and twelve hours. **When the time runs out the
credentials stop working, whoever holds them.** A credential copied out of a server's memory is worth
an hour to the person who copied it, not a year, and nobody had to remember to rotate anything.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 350\" role=\"img\" aria-label=\"Three columns: the caller, which is a virtual machine or a person; the token service, STS; and the service being used, S3. One: the caller asks STS for sts:AssumeRole on the role report-reader, signing the request with its own identity. Two: STS reads the role's trust policy and checks that this caller is one the role trusts. Three: STS answers with temporary credentials, an access key id, a secret key and a session token, with an expiry one hour away. Four: the caller signs its call to S3 with those credentials, and S3 authorises it against the role's permission policy, not against the caller's own. After the expiry the credentials stop working and the caller has to assume the role again.\"><defs><marker id=\"rol-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">the caller</text><text x=\"110\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a VM, or a person</text><rect x=\"310\" y=\"16\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">STS</text><text x=\"400\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the token service</text><rect x=\"570\" y=\"16\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"660\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">S3</text><text x=\"660\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the service being used</text><path d=\"M110 62 L110 336\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M400 62 L400 146\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M400 192 L400 336\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M660 62 L660 300\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"128\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1  asks to assume the role</text><text x=\"146\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">signed as itself</text><text x=\"146\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">sts:AssumeRole  role/report-reader</text><path d=\"M110 134 L400 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rol-ah)\"></path><rect x=\"310\" y=\"146\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2  reads the trust policy:</text><text x=\"400\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">may this caller assume it?</text><path d=\"M400 240 L110 240\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rol-ah)\"></path><text x=\"128\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3  temporary credentials</text><text x=\"146\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">key id, secret, session token</text><text x=\"146\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">expire in one hour</text><path d=\"M110 290 L660 290\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rol-ah)\"></path><text x=\"430\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4  the call, signed with them</text><rect x=\"560\" y=\"300\" width=\"190\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"655\" y=\"313\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5  checked against the role’s</text><text x=\"655\" y=\"328\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">permission policy</text></svg>", "caption": "Nobody logs in to a role. A caller that the trust policy names asks for it, gets credentials that expire, and uses them; the service then judges the call by what the ROLE may do. Steps 1 to 3 happen again before the hour runs out."}
```

## Two policies on every role

A role carries two documents, and they answer different questions.

**The trust policy says who may assume the role.** It names principals: another AWS account, a
service of the provider, or an outside identity provider. This one lets virtual machines from lesson 4
assume the role, and nobody else:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**The permission policy says what the role may do once assumed**, and it is written like any other
policy; the next section takes one apart. Both have to say yes. A role whose trust policy names you
and whose permission policy allows nothing gets you in to do nothing; a role whose permission policy
allows everything is harmless to somebody its trust policy does not name.

That split is also where most of the danger is. A trust policy that says `"Principal": {"AWS": "*"}`
trusts every AWS account in the world, and then the only thing standing between a stranger and the
role's permissions is whatever conditions the policy adds. Reading a trust policy is reading the
list of who can become this identity.

## What uses a role

Anything that is not a person sitting at the console, and increasingly the people too:

- a virtual machine, through the role attached to it, which AWS calls an instance profile;
- a function, through its execution role, which lesson 8 gives to every function it writes;
- a person from another account, who assumes a role in this one instead of having a user here;
- a person signed in through the organisation's identity provider;
- a build pipeline outside the cloud, which proves who it is with a token its own platform issued.

The last three are the section on federation. In each case the question the trust policy answers is
the same: which already-known identity may become this one, and under what conditions.
