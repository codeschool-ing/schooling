---
title: The double charge of 30 September, minute by minute
version: 1
---

On 30 September at 17:20, the Billing team's pipeline deployed release `D047`, carrying four changes. It is in `deploys.csv`, marked as failed, with service restored at 18:15. This section, and the next two lessons, take that failure apart. The minutes below and the people's words are written for the course; the deployment, its time and its restore are the ones `billing.py` produced.

It was the last day of the month, when the monthly subscription charges run. One of the four changes, `BIL-218`, had added a retry when the card provider took too long to answer. Under the month-end load, the provider was slow, and the retry charged again cards whose first charge had in fact gone through.

## The first fifteen minutes

**17:38.** A shop owner calls support: she has been charged twice for her subscription. The support agent, Lia, checks her account and sees both charges.

**17:41.** Lia posts in the Billing team's channel, with the shop's id and both charge ids. **She does not wait** to find a second case; one double charge on a payments product is enough to ask.

**17:44.** Rafa, on call that week, acknowledges and looks. He finds eleven more duplicate charges in the last twenty minutes.

**17:46.** Rafa declares an incident with the chat command, which creates the channel `#inc-0930-double-charge`, and sets it to **SEV2**: real money, but he does not yet know how many shops.

**17:49.** Bia joins and takes **incident commander**. She names the roles in one message: Rafa technical lead, Duda scribe, Caio communications. Caio's first job is to tell support what to say: "We know about double charges since 17:20, we are working on it, refunds will follow."

**17:53.** Rafa reports 140 duplicate charges and rising. Bia raises the incident to **SEV1** and asks Caio to tell the head of engineering and to put a notice on the status page.

That is fifteen minutes from the first call, and nobody yet knows the cause. Nobody needs to. The right people are working, each knows their job, the support team has a sentence to say, and the users have a notice. **What happens next is a decision between fixing and undoing**, and lesson 14 takes it from there.

## What went right, and what did not

The response had the shape this lesson describes: an early question from support, a cheap declaration, a severity raised as facts arrived, roles named in one message. Two things are worth noticing for later.

**Detection came from a customer.** The deployment went out at 17:20 and the first signal was a phone call eighteen minutes later. No alert fired. Lesson 18 is about which alerts should exist, and a duplicate charge is a strong candidate.

**The time to restore in `deploys.csv` started at 17:20**, the deployment, not at 17:46, the declaration. Lesson 5 said to decide when the restore clock starts, and here is why it matters: measured from the declaration, this incident looks twice as fast as it was for the shops.
