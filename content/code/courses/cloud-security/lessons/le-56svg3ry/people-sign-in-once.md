---
title: People sign in once, somewhere else
version: 1
---

**A person who works in an AWS account should not be an IAM user in it.** They should sign in to
the organisation's identity provider, and receive short-lived credentials for a role in each account
they work in. The `cloud` course's lesson 7 described the mechanism: an identity provider such as
Microsoft Entra ID, Google Workspace or Okta vouches for the person in SAML 2.0 or OpenID Connect,
and AWS trusts the statement. This section is about what that arrangement fixes for a defender, and
what it does not.

## What it fixes

**Leaving is one change.** dani, the contractor in this lesson, had an IAM user with a password and
an access key. Her contract ended in March, and her account at the clinic's identity provider was
disabled that week, by the same process that removes everybody. Her IAM user was not part of that
process, because nothing connects the two. If she had signed in through federation, disabling her
at the identity provider would have closed every account at once.

**Credentials expire.** A role session lasts between fifteen minutes and the role's maximum, twelve
hours at most. An access key lasts until somebody deletes it. A session found in a log tomorrow has
already expired; an access key found tomorrow is the one lesson 7 is about.

**The second factor is enforced in one place.** The identity provider asks for it at every sign-in.
Twenty IAM users each need their own MFA device configured and checked.

## How AWS arranges it

AWS's service for people is **IAM Identity Center**. Its pieces, in the order a sign-in meets them:

| piece | what it is |
|---|---|
| identity source | where people and groups live: Identity Center's own directory, Active Directory, or an external provider |
| permission set | a named collection of policies, such as `ReadOnly` or `ClinicDeveloper`, defined once |
| assignment | a group, given a permission set, in one account |
| role | what Identity Center creates in each account from the assignment; the person's session is a session of that role |

So "caio may deploy to the production account" is one assignment: the developers group, the
`ClinicDeveloper` permission set, the production account. Removing caio from the group removes it
from every account the group reaches. **None of this was run**: moto answers Identity Center's API
with empty lists, and there is no identity provider in this course.

## What it does not fix

**A session already issued keeps working until it expires.** Disabling a person at the identity
provider stops the next sign-in, not the current one. That is the argument for sessions measured in
hours rather than the twelve-hour maximum, and it is why AWS documents a way to revoke a role's
active sessions: an inline policy that denies everything to sessions issued before a given time.

**Machines are not people.** A nightly job, a CI pipeline and a function cannot type a password and
approve a push notification. They need roles they assume through the platform they run on, which is
lesson 4's federation between workloads and lesson 13's execution roles. When there is no such
route, somebody creates an IAM user with an access key, and that user is outside the identity
provider's process exactly as dani's was.

**One user per account stays outside it on purpose.** A *break-glass* identity exists for the day the
identity provider is down: an IAM user or the root user, with a hardware MFA key kept in a safe and
credentials nobody uses. It is the one exception a review expects to find, and it should be the only
one, with an alarm on every sign-in.
