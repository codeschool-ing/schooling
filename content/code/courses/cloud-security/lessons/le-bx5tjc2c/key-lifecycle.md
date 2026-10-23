---
title: Rotating, disabling and deleting a key
version: 1
---

**A customer managed key has a life: it is rotated, it may be disabled, and it may be scheduled for
deletion. Each of those changes what happens to every byte ever encrypted under it.** Deleting a
key is the one action in this course that cannot be undone by anybody, AWS included: the data
encrypted under it becomes noise. That is why KMS makes you wait.

Keep working in the moto and the terminal of the last section, with the key's id in `k`, its alias
`alias/clinic-records` and `note.enc`.

## Rotation keeps the old material

Rotating a key in KMS does not re-encrypt anything. **It adds new key material for new encryptions
and keeps every older version**, so ciphertext made last year still decrypts and the key's id and
alias never change. Automatic rotation is off on a new customer managed key until you switch it on;
KMS's documentation gives the default period as one year. A rotation can also be asked for at once:

```
ana@laptop:~/aws$ aws kms get-key-rotation-status --key-id "$k" --query KeyRotationEnabled
false
ana@laptop:~/aws$ aws kms enable-key-rotation --key-id "$k"
ana@laptop:~/aws$ aws kms get-key-rotation-status --key-id "$k" --query KeyRotationEnabled
true
ana@laptop:~/aws$ aws kms rotate-key-on-demand --key-id "$k" --output text
3dc44faa-5788-45db-b010-8787db7bf058
ana@laptop:~/aws$ aws kms list-key-rotations --key-id "$k" --query "Rotations[].RotationType" --output text
ON_DEMAND
```

That is the right answer to *the key is a year old*, and the wrong one to *the key may have leaked*.
Rotation protects data encrypted from now on; whoever could use the key yesterday can still decrypt
everything made before. A key that may be compromised is a question about **who can use it**, and
the answer lives in its key policy and in IAM, not in its material.

## Disabling: what AWS refuses and moto does not

Disabling a key stops it being used, and it can be enabled again. Disable the clinic's key and ask it
for the note:

```
ana@laptop:~/aws$ aws kms disable-key --key-id "$k"
ana@laptop:~/aws$ aws kms describe-key --key-id alias/clinic-records --query KeyMetadata.KeyState --output text
Disabled
ana@laptop:~/aws$ aws kms decrypt --ciphertext-blob fileb://note.enc --query Plaintext --output text | base64 -d; echo
door code: 4471
```

**moto still decrypted.** AWS would not: a request to a disabled key is refused with
`DisabledException`, and every S3 read of an object under that key fails with it. This is the
behaviour that makes disabling useful, as a way to cut off a key's data within seconds while you
find out what happened. **The refusal is from KMS's documentation and was not run here.** Enable it
again before you go on:

```
ana@laptop:~/aws$ aws kms enable-key --key-id "$k"
```

## Deletion waits, on purpose

A key is never deleted at once. `schedule-key-deletion` starts a waiting period, between 7 and 30
days in AWS and 30 when you do not say, and during it the key is `PendingDeletion`:

```
ana@laptop:~/aws$ aws kms schedule-key-deletion --key-id "$k" --query DeletionDate --output text
2026-11-22T01:10:57.047905-03:00
ana@laptop:~/aws$ aws kms describe-key --key-id alias/clinic-records --query KeyMetadata.KeyState --output text
PendingDeletion
ana@laptop:~/aws$ aws kms decrypt --ciphertext-blob fileb://note.enc --query Plaintext --output text | base64 -d; echo
door code: 4471
ana@laptop:~/aws$ aws kms cancel-key-deletion --key-id "$k" --output text
3dc44faa-5788-45db-b010-8787db7bf058
ana@laptop:~/aws$ aws kms describe-key --key-id alias/clinic-records --query KeyMetadata.KeyState --output text
Disabled
```

The date is thirty days on. During the wait, AWS refuses every use of the key with
`KMSInvalidStateException`, which is the point of the wait: **anything still depending on the key
breaks now, loudly, while the deletion can still be cancelled**. moto decrypted the note again, so
that refusal, like the 7-to-30-day bounds, is from the documentation and not from a run. Cancelling
is the last line, and it leaves the key disabled rather than enabled, as AWS also does: somebody has
to decide to switch it back on.

## What a defender watches

Three calls on a key deserve an alarm of their own, read from the logs of lesson 15:
`DisableKey`, `ScheduleKeyDeletion` and `PutKeyPolicy`. The first two can make the clinic's records
unreadable to the clinic, and the third can make them readable to somebody else. **A stolen
administrator key that schedules the deletion of every customer managed key in an account is a way
of holding data to ransom without touching the data**, and the thirty days are the time the account's
owners have to notice. They only notice if somebody is watching for that event name.
