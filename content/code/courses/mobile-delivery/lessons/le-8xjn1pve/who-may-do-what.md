---
title: Who may do what
version: 1
---

**An account is a set of permissions, and the default is that everybody gets too many.** Two
people run a small app and both are admins; a contractor is added to upload one build and keeps
access for two years. The roles exist so that each person can do their job and no more. *Read from
App Store Connect's role documentation, October 2026, and the Play Console Help as published in
2025; not run.*

## App Store Connect

Apple gives each user one or more **roles**, and each role is a fixed bundle of permissions:

| role | what it is for |
|---|---|
| **Account Holder** | the one person who enrolled: signs legal agreements, renews the membership, requests API access |
| Admin | a second in charge: manages users and sees every app |
| App Manager | manages apps, builds, testers and releases |
| Developer | uploads builds and uses the developer resources |
| Marketing | edits the store listing and promotional material |
| Finance | sees sales, payments and tax |
| Sales | sees sales reports only |
| Customer Support | answers customer reviews |

**There is exactly one Account Holder, and only that person can sign Apple's agreements or renew
the membership.** When Apple publishes a new version of the developer agreement, uploads stop
until the Account Holder accepts it. If that person has left the company and nobody can sign in as
them, the team waits on a transfer of the role. **Choose the Account Holder on purpose**: somebody
who will be there in two years, whose Apple Account is protected by two-factor authentication,
and who reads the e-mail Apple sends.

## Play Console

Google's model is a list of users, each with **permissions** chosen one by one, at the account
level or per app: view the app, release to testing tracks, release to production, manage the store
listing, reply to reviews, see financial data. There is one **account owner**, who can do
everything and cannot be removed by anybody else.

The finer grain is useful: a tester coordinator can release to the testing tracks without being
able to release to production, which is a permission Apple's fixed roles do not separate as neatly.

## The rules that keep it safe

- **One person, one login.** A shared account cannot say who pressed release, and both consoles
  keep an activity log only by user.
- **The least role that does the job.** A designer who changes screenshots gets Marketing, not
  Admin.
- **Access ends when the work ends.** A contractor's user is removed on their last day, and the
  list of users is read by somebody every quarter.
- **Two-factor authentication on every account that can release.** Apple requires it for its
  developer accounts; on Google's side, it protects the Google Account that signs in.
