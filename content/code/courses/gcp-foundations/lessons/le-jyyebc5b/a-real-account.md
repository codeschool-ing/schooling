---
title: A real account, and the order to protect it in
version: 1
---

**You do not need a Google Cloud account for any lesson in this course.** This section is for later,
or for the student who wants to see the real thing beside the lab. **None of it was run for the
course**, because there is no account behind it. So there are no transcripts here, only the steps and
the reasons for their order. The screens they mention are Google's, and Google redesigns them; the
names of the settings change less often than their places.

## Before the account exists

Google Cloud is opened at `console.cloud.google.com` with a Google account and a payment card. Two
decisions are cheap now and dear later:

- **Know whose Google account it is.** A personal Gmail address works, and it makes you the owner of
  everything you create, with no organisation above it; lesson 2 explains what that costs. A company
  should start from a domain it controls, with Cloud Identity or Google Workspace, which lesson 10
  describes, so that the estate belongs to the company and not to whoever happened to sign up.
- **Know what the free offer is.** At the time this course was written, a new customer receives a sum
  of credit to spend in the first ninety days, and separately a **free tier**: a few services free up
  to a monthly amount, such as one small virtual machine in certain US regions. **The free tier is one
  possibility, not a promise.** Google has changed its terms before and may again. Read the current
  page before relying on any number in it, and never rely on a number from a course.

## The first hour, in this order

1. **Turn on two-step verification for the Google account**, at `myaccount.google.com`, under
   *Security*. A passkey or a security key is the strongest choice; an authenticator app on a phone
   is the next. Until this is done, the account is one leaked password away from belonging to somebody
   else, and the card behind it with it.
2. **Create a budget with alerts, before anything that can cost money.** In *Billing*, *Budgets and
   alerts*: a monthly budget of a few dollars on the billing account, with an e-mail at 50%, 90% and
   100% of the actual spend. Lesson 12 writes the same budget as Terraform and says what each kind of
   threshold means. **A budget does not stop spending**; it tells you, which is why it comes first,
   while the amount is still small.
3. **Never download a service account key.** The console offers one on every service account's page,
   and lesson 8 is about why it is the last resort. A new organisation created in 2024 or later
   refuses key creation by default, through the organisation policy of lesson 4; a personal account
   with no organisation has no such guard.
4. **Sign the CLI in somewhere other than the lab.** The lab's `gcloud` keeps its settings in
   `~/gcp/gcloud` and has never held a credential. Open a separate terminal that never reads `env.sh`,
   run `gcloud auth login` there, and the real account lives in `~/.config/gcloud`. Two terminals
   with two directories behind them are harder to confuse than one terminal whose variables you have
   to remember.

## What costs money from the moment it exists

Everything Terraform only plans in this course, Google will create and bill. A virtual machine is
billed by the second while it runs and its disk while it exists; a Cloud NAT gateway, a load
balancer's forwarding rule and an unused static external address each charge by the hour. Lessons 17
and 20 give their prices. **Delete what you create the same day**, and look at the billing reports
page the next morning: it is the one screen that tells you what you forgot. Deleting the whole
project, as lesson 3 shows, is the surest way, because nothing inside a project survives it.
