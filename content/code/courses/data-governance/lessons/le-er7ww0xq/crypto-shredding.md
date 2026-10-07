---
title: Destroying a key on purpose
version: 1
---

Some data has to be erased in places nobody can reach to delete it from: last year's backups, a
copy in another region, a tape in a vault. Lesson 7 has the legal reason — a customer's right to
have their data deleted — and lesson 10 the retention rules. This section has the technique,
which only a key-management service makes possible: **if the data was encrypted with a key that
belongs to it alone, destroying the key erases every copy at once.** It is called
**crypto-shredding**.

A key for one customer, and something encrypted with it:

```
ana@lab:~/gov$ bao write -f transit/keys/ipe-customer-4711
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791343895]
latest_version            1
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      ipe-customer-4711
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ printf '%s\n' vault:v1:yyUANlXaryMx87hy+lIDWOk/ON96J4uh8NOXPUujRtbVwIatK6+yf4criKkZV9qrxc+rQPg=
vault:v1:yyUANlXaryMx87hy+lIDWOk/ON96J4uh8NOXPUujRtbVwIatK6+yf4criKkZV9qrxc+rQPg=
ana@lab:~/gov$ bao write transit/keys/ipe-customer-4711/config deletion_allowed=true
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          true
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791343895]
latest_version            1
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      ipe-customer-4711
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ bao delete transit/keys/ipe-customer-4711
Success! Data deleted (if it existed) at: transit/keys/ipe-customer-4711
ana@lab:~/gov$ bao write transit/decrypt/ipe-customer-4711 ciphertext=vault:v1:yyUANlXaryMx87hy+lIDWOk/ON96J4uh8NOXPUujRtbVwIatK6+yf4criKkZV9qrxc+rQPg=
Error writing data to transit/decrypt/ipe-customer-4711: Error making API request.

URL: PUT https://bao.ipe.example:8200/v1/transit/decrypt/ipe-customer-4711
Code: 400. Errors:

* encryption key not found
```

Transit refuses to delete a key until its configuration says `deletion_allowed true`, a second,
deliberate step that makes an accidental deletion impossible. Then the key goes, and the
ciphertext — wherever its copies are, backups included — answers `encryption key not found`. Not
"access denied", which a different token might get past: there is no key left anywhere to decrypt
with.

## The price of being able to do this

**A key per customer is many keys.** Ipê has 6,012 customers, so 6,012 keys, each to create,
protect, back up and audit. Services handle that scale, but somebody has to design for it, and it
only makes sense for data that genuinely has to be erasable per person while copies of it live
where a `DELETE` cannot reach.

**It is irreversible, which is the point and the danger.** A key deleted by mistake destroys data
nobody meant to lose, in every backup. That is why `deletion_allowed` exists, why the step should
be a reviewed operation rather than a script's side effect, and why OpenBao's own backups — which
hold the keys — need a retention policy that matches the promise: a backup of the key service
kept for a year means a shredded key is recoverable for a year.

**It erases only what was encrypted with that key alone.** A customer's notes encrypted with
their own key are gone; the same notes copied in clear into a support ticket are not. Shredding is
only as complete as the discipline about where plaintext was allowed to go, which is lesson 3's
inventory of copies all over again.
