---
title: A decade of the same mistake
version: 1
---

**The most common way data has leaked from the cloud involves no attack at all. Somebody makes a
storage bucket readable by everyone, somebody else finds it, and the data is downloaded with an
ordinary request that the bucket answers as designed.** Nothing was broken into. The provider's
security held. The setting did what it said.

The wrong picture is of a breach as somebody defeating a defence. Here the defence was switched off
by its owner, usually for a reason that made sense on the day: a file to share with a vendor, a
website to serve, a test that needed to work by five o'clock. That is why it kept happening for so
long, to companies with security teams, and why this lesson's title calls it the mistake of the
decade.

## Four that were published

In 2017 the security firm UpGuard published a series of reports on exposed Amazon S3 buckets its
researchers had found. Four of them, as UpGuard and the press reported them at the time:

| when | whose data | what was in it |
|---|---|---|
| June 2017 | Deep Root Analytics, a data firm working for the US Republican National Committee | records on about 198 million American voters |
| June 2017 | Booz Allen Hamilton, a contractor of the US National Geospatial-Intelligence Agency | files that included credentials to government systems |
| July 2017 | Verizon, through NICE Systems, a vendor handling its call centre | customer records: UpGuard estimated 14 million, Verizon about 6 million |
| October 2017 | Accenture | four buckets holding keys, passwords and internal data |

**Three of the four were a vendor's bucket holding a customer's data.** That is the pattern worth
keeping. The company whose name was in the headline did not create the bucket, and its own security
programme never saw it. Lesson 10 returns to that shape with storage people open for themselves.

In each case the researchers found the bucket because it answered them, and reported it to the
owner, which is the responsible way to do it. They did not need a vulnerability, a password or any
skill beyond knowing the address. **Anything a researcher can find that way, somebody without good
intentions can find the same way**, and nobody publishes a report about the copies they took.

## How the provider answered

The fix did not come from one more warning in a document. It came, over six years, from changing
what the default is:

| when | what AWS changed, by its announcements |
|---|---|
| November 2018 | **S3 Block Public Access**: four switches, per bucket and per account, that refuse or ignore public grants whatever the policies and ACLs say |
| January 2023 | every new object encrypted at rest by default, with S3-managed keys |
| April 2023 | every new bucket created with Block Public Access on and ACLs disabled |

Since April 2023 a new bucket takes **two deliberate steps** to become public: switching the
guardrail off, and then writing the grant. Lesson 1's `put-bucket-policy` would have been refused
on a real account for exactly that reason.

That does not retire the subject. Buckets created before 2023 keep the settings they had. A
guardrail can be switched off by anyone allowed to, and in a hurry somebody always is. The same
mistake exists under other names in every provider, which lesson 5 compares. And the storage of the
next lesson lives outside these guardrails entirely. **The rest of this lesson is the mechanism, so that you can find
the ones that are still open.**
