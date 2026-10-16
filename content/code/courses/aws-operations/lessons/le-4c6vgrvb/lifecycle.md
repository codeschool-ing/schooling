---
title: Rotation, disabling, and the deletion that cannot be undone
version: 1
---

## Rotation

Rotating a KMS key gives it **new key material** and keeps the old material, so everything encrypted
before still decrypts and everything encrypted after uses the new one. The key's id, ARN, alias and
policy do not change, and no program notices. Turned on, rotation happens on a schedule:

```
ana@laptop:~/aws/kms$ aws kms enable-key-rotation --key-id $KEY --rotation-period-in-days 365
ana@laptop:~/aws/kms$ aws kms get-key-rotation-status --key-id $KEY
{
    "KeyRotationEnabled": true
}
```

On AWS the period can be between 90 and 2,560 days, 365 by default, and `get-key-rotation-status` answers
with the period and the next date; moto keeps only the yes. `rotate-key-on-demand` rotates at once,
which is the answer when a key's material might have been exposed. **Nothing is re-encrypted**: with
envelope encryption only data keys were ever encrypted under the KMS key, and old data keys are still
decrypted with the old material, which KMS keeps for the life of the key.

## Disabling

`disable-key` stops every use of the key at once, encrypt and decrypt, until `enable-key`. It is the
switch to pull when a key's use looks wrong, because it can be undone in a second. What it breaks is
everything that depends on the key, which for the key behind a database is the database.

## Deletion

Deleting a KMS key deletes the material, and **every ciphertext made with it becomes unreadable for
ever**: the backups, the snapshots, the sealed files of the previous section. So KMS never deletes at
once. It schedules the deletion **7 to 30 days** ahead, and the key waits in `PendingDeletion`:

```
ana@laptop:~/aws/kms$ aws kms schedule-key-deletion --key-id $KEY --pending-window-in-days 7 --query DeletionDate --output text
2026-10-23T16:35:08.482077-03:00
ana@laptop:~/aws/kms$ aws kms describe-key --key-id $KEY --query 'KeyMetadata.KeyState' --output text
PendingDeletion
ana@laptop:~/aws/kms$ aws kms decrypt --ciphertext-blob fileb://note.enc --encryption-context order=1001 --query Plaintext --output text | base64 -d; echo
card ending 4242
ana@laptop:~/aws/kms$ aws kms cancel-key-deletion --key-id $KEY --query KeyId --output text
e646e99c-ee02-4891-b5c7-9ac684b09fad
ana@laptop:~/aws/kms$ aws kms describe-key --key-id $KEY --query 'KeyMetadata.KeyState' --output text
Disabled
ana@laptop:~/aws/kms$ aws kms enable-key --key-id $KEY
ana@laptop:~/aws/kms$ aws kms describe-key --key-id $KEY --query 'KeyMetadata.KeyState' --output text
Enabled
```

The third command is moto's mistake. **On AWS a key pending deletion cannot be used at all**: the decrypt
fails with `KMSInvalidStateException`, and that failure is the purpose of the waiting period, because
whatever still needs the key breaks loudly while the deletion can be cancelled. moto decrypted as if
nothing had happened.

Cancelling leaves the key **`Disabled`**, not enabled, on AWS as in moto, so cancelling a deletion does
not quietly put a key back into use: somebody has to enable it on purpose. A team that schedules a
deletion should also alarm on its use in the waiting period, which CloudTrail makes possible and lesson
20 builds.
