---
title: Emergency accounts, and the policy that locks everybody out
version: 1
---

**The most common way to lose a tenant is not an attacker. It is a conditional access policy that
locks out the people who could fix it.** A block aimed at "all users outside Brazil" on the day the
only administrator is at a conference in Lisbon; a demand for a managed device before anybody's laptop
is enrolled; a second-factor service that is down for the morning. In each case the policy works
exactly as written, and nobody who could change it can sign in to do so.

Microsoft's answer, in its documentation, is **emergency access accounts**, called break-glass
accounts after the box on the wall with an alarm behind it. **None of this was run**; it is the
procedure as Microsoft describes it.

## What an emergency account is

- **Two or more of them**, so that one lost key is not the end.
- **Cloud-only, in the tenant's own `onmicrosoft.com` domain**, never synchronised from an office's
  directory or federated to another system. Lesson 12 explains those two links; an emergency account
  must not depend on either, because either can be what is broken.
- **Global Administrator**, held permanently and actively, which lesson 10 named as the exception to
  just-in-time elevation: an account that exists for the day PIM itself cannot be reached.
- **Signed in with a phishing-resistant method that is not the one everybody else uses**, such as a
  FIDO2 security key, kept in a safe in a known place. Microsoft's documentation names passkeys and
  certificate-based authentication, and both satisfy the mandatory MFA of the first section, which
  applies to these accounts like any other.

## Where they sit in the policies

**Exclude them from every conditional access policy that blocks or restricts sign-in.** The usual
way is the one the previous section's policy used: put the emergency accounts in a group, and exclude
the group, so that a new policy needs one line rather than a memory of which accounts exist. A
report-only policy needs no exclusion, because it enforces nothing.

That exclusion is a hole on purpose, and a hole needs watching. **An emergency account that signs in
is an event somebody must hear about the same minute**: Microsoft recommends alerting on every
sign-in of these accounts, from the sign-in logs. If the sign-in was a real emergency, the alert
confirms it. If it was not, the alert is the only warning the tenant gets.

## Testing that they still work

An emergency account that has not been used in two years is a key nobody has tried in the lock.
Microsoft recommends checking them on a schedule and after changes: that the key in the safe still
signs in, that the account still holds its role, and that the people who should know where the safe
is still know.

## The shop's arrangement

| | what the shop decided |
|---|---|
| accounts | two, `breakglass1@shop.onmicrosoft.com` and `breakglass2@shop.onmicrosoft.com` |
| role | Global Administrator, active and permanent |
| sign-in | a FIDO2 key each, in two safes, in two different places |
| policies | the group `sg-emergency-access` is excluded from every enforced policy |
| watching | every sign-in by either account raises an alert to the platform team |
| testing | every quarter, and after any change to conditional access |

**The order matters as much as the table.** The emergency accounts are created, tested and excluded
before the first enforced policy, and the first policy runs in report-only for a week before it is
switched on. A tenant that switches a block on first and creates the way back afterwards may not get
to the second step.
