---
title: The day a key leaks
version: 1
---

**Each of the three mistakes ends the same way: a key that has to be treated as known to somebody
else. What happens next depends far less on the cryptography than on whether anybody knows what that
key protects and has ever replaced it before.**

## Before the day: an inventory

A key nobody has listed is a key nobody will rotate. Vereda keeps one table, reviewed every six months,
with a row per key: what it protects, where it lives, who can use it, how it is replaced, and when it
last was. The table is short for a clinic, perhaps twenty rows, and most of them came from earlier
lessons: the TLS keys of lesson 10, the webhook key of lesson 6, the SSH keys of lesson 12, the LUKS
passphrases and the KMS master key of lesson 14, the RADIUS shared secret of lesson 16.

The last column matters most. **A key that has never been rotated is one nobody knows how to rotate**,
and the first attempt should not happen during an incident. Rotating on a schedule, even when nothing
leaked, is how the procedure gets tested.

## On the day

1. **Establish what the key protects and since when it was exposed.** For the portal key that was
   `git log -S`: five weeks, and every clone made in that window.
2. **Issue a new key and deploy it.** Where signatures or MACs are checked, accept both keys for a short
   overlap so that messages already in flight still verify, then stop accepting the old one. A key id
   in each message, like the `kid` of a JSON Web Token, makes that overlap explicit.
3. **Revoke the old key wherever it is recognised**: at the provider that issued it, in a CRL for a
   certificate (lesson 9), in `authorized_keys` and `allowed_signers` for SSH keys, in the KMS for a
   data key.
4. **Deal with what the old key already protected.** Data encrypted under it is re-encrypted under the
   new one, as the agenda export was. Anything signed with it stays signed; what changes is that a
   signature made after the leak can no longer be trusted, so timestamps and logs decide what to keep.
5. **Look back.** The provider's logs, the KMS audit trail and the access logs show whether the old key
   was used from anywhere it should not have been. If it was, the incident is no longer only about the
   key, and under the LGPD a leak of personal data has its own deadline to report it.
6. **Fix the cause**: the scanner that would have refused the commit, the nonce taken from state that a
   restore rewound, the homemade function replaced by the library.

## What revoking means, key by key

| key | revoking means |
| --- | --- |
| a provider's API or webhook key | regenerating it at the provider |
| a TLS certificate's private key | a new key and certificate, the old one revoked at the CA |
| an SSH key | removing its line from every `authorized_keys` and `allowed_signers` |
| a data key under envelope encryption | re-encrypting its data, then deleting the wrapped key |
| a KMS master key | rotating it; disabling the old version once nothing depends on it |
| a Wi-Fi passphrase | a new passphrase on the access point and on every device |
