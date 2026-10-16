---
title: A real account, and the order to protect it in
version: 1
---

**You do not need an AWS account for any lesson in this course.** This section is for later, or for
the student who wants to see the real console beside moto. **None of it was run for the course**,
because there is no account behind it, so there are no transcripts here, only the steps and the
reasons for their order. The screens they mention are AWS's, and AWS redesigns them; the names of
the settings change less often than their places.

## Before the account exists

An AWS account is created at `aws.amazon.com` with an e-mail address, a password, a phone number
that receives a code, and a payment card. Two decisions are cheap now and dear later:

- **Use an address that is not a person's.** The address becomes the **root user**, the identity
  that owns the account and can do anything in it, including close it. A shared mailbox such as
  `aws-root@yourcompany.example` survives the day the person who opened the account leaves.
- **Know which plan you are choosing.** At the time this course was written, a new account starts
  either on a **free plan**, with a sum of credits that expire after some months and limits on what
  it can create, or on a paid plan with the long-standing **free tier**: a set of services free up
  to a monthly amount. **The free tier is one possibility, not a promise**: AWS changed its terms in
  2025 and may again, so read the current page before relying on any number in it, and never on a
  number from a course.

## The first hour, in this order

1. **Protect the root user with MFA**, a second factor. In the console it is under the account
   name, *Security credentials*, *Multi-factor authentication*. A passkey or an authenticator app on
   a phone both work. Until this is done, the account is one leaked password away from belonging to
   somebody else, and the card behind it with it.
2. **Never create an access key for the root user.** The same page offers one. A key is a password
   that cannot have a second factor, and lesson 12 explains why even an ordinary user's key is the
   last resort; for root it is the worst one.
3. **Create a budget with an alert, before anything that can cost money.** In *Billing and Cost
   Management*, *Budgets*: a monthly cost budget of a few dollars, with an e-mail alert at 80% of
   the actual cost and another at 100% of the forecast. Lesson 13 builds the same budget in moto and
   says what each kind of alert means. **An alert does not stop spending**; it tells you, which is
   why it comes first, while the amount is still small.
4. **Make an everyday identity, and stop using root.** Lesson 11 turns on IAM Identity Center and
   creates a user for yourself with a permission set; from then on the root user's password goes
   somewhere safe and is used only for the few tasks that need it, such as closing the account.

## Pointing the lab at it, and back

The command line you installed talks to AWS the moment `AWS_ENDPOINT_URL` is not set and real
credentials are. **Use a separate terminal that never reads `env.sh`**, sign in there with
`aws configure sso` as lesson 25 shows, and keep the moto terminals as they are. Two terminals with
two prompts are harder to confuse than one terminal whose variables you have to remember.

Everything in this course that moto merely records, AWS will run and bill: a NAT gateway charges by
the hour from the moment it exists, a load balancer the same, and every public IPv4 address too.
Lessons 17 and 22 give their prices. **Delete what you create the same day**, and look at the bill
page the next morning: it is the one screen that tells you what you forgot.
