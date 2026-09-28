---
title: How a request is decided
version: 1
---

A request rarely meets one policy. A user belongs to two groups, each with its own policies, and has
one of their own attached; the bucket they are reading has a bucket policy of its own. The provider
has to turn all of that into one answer, and it does it with three rules:

1. Everything starts denied. A request that no statement mentions is refused. This is called an
   implicit deny, and it is the answer to every request nobody thought about.
2. An explicit `Allow` that matches grants it, from any policy that applies.
3. An explicit `Deny` that matches refuses it, and nothing can undo that. Not a second `Allow`,
   not a more specific one, not one attached closer to the person.

**A request is allowed only when something allows it and nothing denies it.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A decision flow for an authenticated request. It starts denied. First question: does any policy that applies carry an explicit Deny that matches this action, resource and circumstances? If yes, the answer is DENY and nothing else is read. If no, the second question: does any policy carry an Allow that matches? If yes, ALLOW. If no, the request stays where it started: DENY, by default, which is called an implicit deny.\"><defs><marker id=\"evl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">an authenticated request</text><text x=\"130\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">starts as: denied</text><path d=\"M130 70 L130 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#evl-ah)\"></path><rect x=\"20\" y=\"100\" width=\"220\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">an explicit Deny matches,</text><text x=\"130\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in any policy that applies?</text><path d=\"M240 128 L430 128\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#evl-ah)\"></path><text x=\"335\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">yes</text><rect x=\"430\" y=\"100\" width=\"270\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"565\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"700\">DENY</text><text x=\"565\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">explicit: no Allow can undo it</text><path d=\"M130 156 L130 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#evl-ah)\"></path><text x=\"146\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no</text><rect x=\"20\" y=\"190\" width=\"220\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">an Allow matches,</text><text x=\"130\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in any policy that applies?</text><path d=\"M240 218 L430 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#evl-ah)\"></path><text x=\"335\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">yes</text><rect x=\"430\" y=\"190\" width=\"270\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"565\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"700\">ALLOW</text><text x=\"565\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the request goes through</text><path d=\"M130 246 L130 270\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#evl-ah)\"></path><text x=\"146\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no</text><rect x=\"20\" y=\"270\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"130\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"700\">DENY</text><text x=\"130\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">implicit: nothing allowed it</text></svg>", "caption": "The order the policies were written in, and which one was attached first, change nothing: every policy that applies is read, a matching Deny ends it, and without a matching Allow the answer is the one the request started with."}
```

## The wrong model: the closest policy wins

People who know file permissions or CSS expect the most specific rule to override the general one,
so a policy on the user should beat a policy on the group. There is no such ranking. Every policy
that applies is read, their statements are pooled, and the three rules decide. Three cases, all with
the same user, `ana`, in the group `analysts`:

| the group `analysts` says | `ana`'s own policy says | `ana` asks for | result |
|---|---|---|---|
| Allow `s3:*` on the reports bucket | Deny `s3:DeleteObject` there | `s3:DeleteObject` | refused, explicitly |
| Allow `s3:*` on the reports bucket | Deny `s3:DeleteObject` there | `s3:GetObject` | allowed |
| Allow `s3:GetObject` on the reports bucket | nothing | `s3:PutObject` | refused, implicitly |

The first row is the rule people doubt. The group's `s3:*` covers deleting, and it does not matter:
a matching `Deny` anywhere ends the question. The second row shows that the `Deny` removes only
what it names. The third shows the implicit deny doing its job: nobody wrote "no uploads", and
there are none, because nothing allowed them.

## Using a Deny on purpose

Because an explicit deny wins over everything, it is the tool for a rule that must hold whatever
anybody else allows. This statement refuses deletions in the reports bucket to any session opened
without a second factor, however broad the `Allow` that would otherwise have covered it:

```json
{
  "Effect": "Deny",
  "Action": "s3:DeleteObject",
  "Resource": "arn:aws:s3:::example-reports/*",
  "Condition": {
    "BoolIfExists": { "aws:MultiFactorAuthPresent": "false" }
  }
}
```

`BoolIfExists` rather than `Bool` matters here. A request signed with a long-lived access key
carries no MFA key at all, and plain `Bool` would find nothing to compare and not apply; the
`IfExists` form treats a missing key as a match, so the deny catches those requests too.

## Where the rules stop being the whole story

Two policies from different owners meet when a request crosses accounts. A user in one account
reading a bucket in another needs an `Allow` on **both** sides: their own identity policy has to
allow the action, and the bucket policy has to allow their account or them. Inside a single account,
an `Allow` from either the identity's policies or the resource's policy is enough.

AWS also has limits that sit above the policies in this lesson and never grant anything on their own:
a **permission boundary** caps what a user's or role's own policies can give it. A service control
policy does the same for whole accounts in an organisation. With either in
place, a request needs an `Allow` from every layer that applies, and a `Deny` in any layer still
wins. They are where `aws-foundations` and `cloud-security` pick this up; the three rules above do
not change inside them.
