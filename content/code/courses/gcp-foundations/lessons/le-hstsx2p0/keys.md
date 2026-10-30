---
title: Why a downloaded key is the last resort
version: 1
---

**A service account key is a file that proves you are the account, to anybody who holds it, for as long as
it exists.** It is a JSON file holding a private key, created on the account's page or with `gcloud iam
service-accounts keys create`, and by default it never expires. Everything this lesson praised about
attached accounts and impersonation, the short life, the named borrower, the second factor of the person
behind it, the key has none of.

| | attached account | impersonation | downloaded key |
|---|---|---|---|
| where the credential lives | nowhere: the metadata server mints one | Google, for an hour | a file, wherever it was copied |
| how long it works | about an hour, renewed | an hour, or up to twelve | until somebody deletes the key |
| who used it | the machine it is attached to | logged with the borrower's name | whoever had the file |
| second factor | not applicable | the borrower's own | none |

The column on the right is why keys are how service accounts get stolen. **A key ends up in a repository,
a container image, a CI variable, a laptop's Downloads folder**, and every copy works. Google's own advice,
and the secure-by-default policy of lesson 4, is to create none: an organisation created in 2024 or later
refuses `iam.serviceAccountKeys.create` until somebody lifts the constraint.

## The cases that seem to need one

Almost every reason somebody reaches for a key has a better answer in this course:

- **a person running a script as the account**: impersonation, previous section;
- **code running in Google Cloud**: an attached account, first section;
- **code running outside Google Cloud with an identity of its own**, GitHub Actions, another cloud, a
  datacentre with Active Directory: **Workload Identity Federation**, lesson 9, which trades the outside
  identity's token for a Google one with no key at all.

What is left is genuinely rare: an old appliance or a third-party product that accepts only a key file.

## When there is no other way

Then the key is handled as the secret it is, and the controls are on the account rather than on people's
good intentions:

- **one key, on an account that does one thing**, holding the narrowest roles that work;
- **an expiry**: the organisation policy `iam.serviceAccountKeyExpiryHours` makes keys stop working after
  a set time, so rotation stops being optional;
- **rotation as a routine**: create the new key, deploy it, confirm the old one is no longer used, delete
  it. Google records each key's last use, which is how the third step is checked rather than assumed;
- **a secret manager**, never a file in a repository. Secret Manager stores it, and grants to read it are
  IAM like any other.

**If a key leaks, delete it first and investigate second.** Deleting the key ends every copy at once, and
the audit logs of what it did are still there afterwards. Google also scans public repositories for
service account keys and notifies the project's contacts when it finds one; that message is not a test.

None of this section ran: creating a key needs a real account, and this course creates none. There is no
key file, real or imitated, anywhere in these lessons.
