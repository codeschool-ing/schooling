---
title: What stands between an account and the first release
version: 1
---

**Opening the account is the start of a list, and the list is longer than people plan for.** Each
item is quick on its own; together they decide whether the first release is this week or next
month. *Read from Apple's documentation, October 2026, and from Google's Play Console Help as
published in 2025; not run.*

## On Apple's side

- **The agreements.** The free-apps agreement is accepted at enrolment. A paid app or an in-app
  purchase needs the **Paid Applications Agreement**, accepted by the Account Holder, and then the
  bank account and the tax forms. Until all three are complete, nothing priced can be sold.
- **The App Store Connect record.** An app is created in App Store Connect with its bundle
  identifier, its name and its primary language before the first build can be uploaded to it.
  **The name must be unique across the whole App Store**, so a name somebody else holds is found
  here, not at review.
- **The membership's year.** It runs from the day of enrolment, and so does the 100-device count
  of lesson 2.

## On Google's side

- **Identity verification.** Google verifies the account's owner, or the organisation through its
  D-U-N-S number, before the account can publish. It asks for documents and can take days.
- **A testing requirement for new personal accounts.** Google's help in 2025 required a personal
  account created after November 2023 to run a **closed test with at least 12 testers, opted in
  for at least 14 days**, before it could apply for production access. Organisation accounts are
  exempt. Lesson 7 is about closed testing; this rule is the reason a first release on a new
  personal account takes two weeks at the least.
- **The payments profile.** A paid app or in-app products need a merchant account linked to the
  developer account, with its own tax details.

## Planning backwards

**Count the calendar from the slowest step, not from the code.** A D-U-N-S request, a verification
and a fourteen-day closed test can each take longer than finishing the app, and none of them can
start late and finish on time. The first thing a team does after deciding to publish is open the
accounts; the code can be finished while the paperwork is waiting.

| step | who does it | the wait |
|---|---|---|
| D-U-N-S number, for an organisation | the company | days |
| identity verification | the account owner | days |
| agreements, bank and tax | the Account Holder, the owner | an afternoon, once all the details are at hand |
| closed test on a new personal Play account | you and twelve testers | 14 days or more |
| the first review | the stores | lesson 6 |
