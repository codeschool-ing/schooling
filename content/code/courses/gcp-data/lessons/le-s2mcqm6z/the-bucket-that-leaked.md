---
title: The bucket that leaked
version: 1
---

**The public buckets that reached the news were, as a rule, a configuration somebody chose, not a
break-in.** Nobody guessed a password. A bucket was readable by anybody because a grant, an ACL or a
URL said so, and it stayed that way because nothing anybody looked at said otherwise. Reports of
exposed buckets holding customer records, backups and logs, on every provider, ran for years before
public access prevention and uniform access became the defaults, and they share a few shapes.

## The shapes of a leak

**A grant to `allUsers` on the bucket.** Typically made to publish one folder of product images for
a website, on the bucket instead of on a bucket of its own, which made every object public. It is
one command, `add-iam-policy-binding` with `--member=allUsers`, and the previous sections showed the
emulator answering it with `404`, so here it is described rather than run.

**An ACL on objects.** Before uniform bucket-level access, a bucket whose IAM was perfectly private
could hold public objects, each with its own `allUsers` grant, set by whichever program wrote them
with `--predefined-acl=publicRead`. Nobody looking at the bucket's IAM would see them. This lesson's
section on who may read showed the emulator accepting exactly such an ACL.

**`allAuthenticatedUsers`, read as "our users".** A grant meant for colleagues, made to anybody with
a Google account.

**A signed URL that lived too long, or a key that leaked.** A URL valid for seven days, pasted into a
support ticket or a public issue, is a seven-day public link to the object. A service account key
committed to a repository is worse: it signs as many URLs as anybody likes, until the key is deleted.

## Preventing it

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Five nested boxes, from the outside in: organisation policy constraints, public access prevention, uniform bucket-level access, the IAM allow policy with its conditions, and the object. On Cloud Storage each layer refuses a public request on its own. In the emulator the organisation does not exist, the two bucket settings are accepted and not kept, IAM answers 404, and the object is served to any request.\" data-fig=\"l04-layers\"><text x=\"20.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">the internet</text><text x=\"700.0\" y=\"18.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">Cloud Storage refuses at each layer</text><rect x=\"20\" y=\"34\" width=\"680\" height=\"276\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">organisation policy constraints</text><text x=\"688.0\" y=\"52.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">emulator: no organisation at all</text><rect x=\"42\" y=\"84\" width=\"636\" height=\"226\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">public access prevention</text><text x=\"666.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">emulator: accepted, not kept</text><rect x=\"64\" y=\"134\" width=\"592\" height=\"176\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">uniform bucket-level access</text><text x=\"644.0\" y=\"152.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">emulator: accepted, not kept</text><rect x=\"86\" y=\"184\" width=\"548\" height=\"126\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"98.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">IAM allow policy, and its conditions</text><text x=\"622.0\" y=\"202.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">emulator: 404, no IAM</text><rect x=\"108\" y=\"234\" width=\"504\" height=\"76\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the object</text><text x=\"600.0\" y=\"252.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">emulator: served to any request</text></svg>", "caption": "What stands between the internet and an object, from the outside in, and what fake-gcs-server does with each layer. On Cloud Storage any one of them refuses on its own; in the emulator none does."}
```

The order matters, from the broadest net to the narrowest:

1. **The organisation policies of the previous section**: public access prevention and uniform
   bucket-level access enforced on everything, and keys that cannot be downloaded.
2. **Public access prevention and uniform access on every bucket anyway**, so that a bucket stays
   protected in a project moved out from under the policy.
3. **IAM grants to groups and service accounts, narrowed by a condition** where a principal needs one
   prefix.
4. **Signed URLs short and narrow**: minutes, signed by impersonation, by an account that can read
   one prefix.

## Detecting it

Prevention fails, so somebody has to be told when it does. Google's documentation describes the
tools, and none of them can be run against an emulator:

| tool | what it answers |
|---|---|
| Cloud Audit Logs, Admin Activity | who changed a bucket's IAM, ACLs or settings, and when; always on, kept for 400 days, not billed |
| Cloud Audit Logs, Data Access | who read or wrote which object; off by default for Cloud Storage, and billed as log volume once on |
| Security Command Center | findings such as a public bucket ACL, raised by its Security Health Analytics scans |
| Cloud Asset Inventory | every IAM policy in the organisation that names `allUsers` or `allAuthenticatedUsers`, in one search |
| Sensitive Data Protection | which objects hold personal data, such as names, CPF numbers and card numbers, by inspecting them |

**They answer different questions, and the difference is the point.** Asset Inventory says a door is
open. Sensitive Data Protection says what is behind it. The audit logs say who changed the door and
who walked through, which is the question that decides whether an exposure became a leak. **Data
Access logs only answer it if they were on before it happened.** The documentation for usage logs adds
a further gap: requests for public objects are not recorded in the audit logs at all, and usage logs,
written to a bucket with `--log-bucket`, are the way to track them. A bucket that holds
anything personal has one or the other on from its first day.

The search an analyst runs first, from `gcp-foundations` lesson 25, looks like this; it needs an
organisation and was not run here:

```sh
gcloud asset search-all-iam-policies --scope=organizations/123456789012 --query='policy:allUsers'
gcloud asset search-all-iam-policies --scope=organizations/123456789012 --query='policy:allAuthenticatedUsers'
```

## The one check that is always worth running

**Ask for an object with no credentials, from outside, and expect a refusal.** It is the test of
whether something is public and the only one worth trusting, because it checks the result rather
than the settings that were meant to produce it:

```sh
curl -s -o /dev/null -w '%{http_code}\n' https://storage.googleapis.com/quitanda-curated-prod/reports/daily.csv
```

Against Cloud Storage a private object answers with an error code and no bytes. **In this lab the
check cannot fail**: the section on who may read showed fake-gcs-server handing a private report to
a request signed by nobody, so every object here is what a leaked one looks like. That is the last
thing this lesson's emulator teaches, and the most useful: a test that cannot tell a private object
from a public one is not a test of privacy, and the only place that question has an answer is the
real service.
