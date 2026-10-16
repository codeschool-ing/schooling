---
title: Narrowing what a key can do, and the day one leaks
version: 1
---

**A key that has to exist should be able to do as little as possible, and the most dangerous actions
should need more than the key.** `erp-sync` already shows the first half. Its policy names one
action on one prefix of one bucket, so a copy of its key can upload files and nothing else. The
second half is a condition that asks for a second factor. The last part of this section is what to
do when, despite both, a key turns up somewhere it should not be.

## A second factor for the actions that hurt

`dani`, in finance, still has an IAM user from before Identity Center, with S3 access for the
monthly reports. Deleting a backup should need her phone as well as her key. **A key carries no MFA
on its own.** A session gets it when the user calls `sts get-session-token` with the code from her
device. Requests signed with that session carry `aws:MultiFactorAuthPresent` set to `true`. This
refusal applies whenever that is not the case. Save it as `~/aws/mfa-to-delete.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": ["s3:DeleteObject", "s3:DeleteBucket"],
      "Resource": ["arn:aws:s3:::shop-backups", "arn:aws:s3:::shop-backups/*"],
      "Condition": {"BoolIfExists": {"aws:MultiFactorAuthPresent": "false"}}
    }
  ]
}
```

**`BoolIfExists` is the important word.** A request signed with the key alone carries no
`aws:MultiFactorAuthPresent` at all. A plain `Bool` would not match a key that is absent, so the
deny would miss exactly the request it exists for. `IfExists` makes the missing key count as a
match.

```
ana@laptop:~/aws$ aws iam create-user --user-name dani --query User.Arn --output text
arn:aws:iam::123456789012:user/dani
ana@laptop:~/aws$ aws iam attach-user-policy --user-name dani --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
ana@laptop:~/aws$ aws iam put-user-policy --user-name dani --policy-name mfa-to-delete --policy-document file://mfa-to-delete.json
ana@laptop:~/aws$ read -r DANI_ID DANI_SECRET < <(aws iam create-access-key --user-name dani --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$DANI_ID AWS_SECRET_ACCESS_KEY=$DANI_SECRET aws s3api list-objects-v2 --bucket shop-backups --query "Contents[].Key" --output text
erp/sales.csv
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$DANI_ID AWS_SECRET_ACCESS_KEY=$DANI_SECRET aws s3 rm s3://shop-backups/erp/sales.csv
delete failed: s3://shop-backups/erp/sales.csv An error occurred (AccessDenied) when calling the DeleteObject operation: Access Denied
```

Listing worked and deleting was refused, which is what AWS would do with a key and no MFA. **But
moto reached the right answer for the wrong reason**, and one more test shows it. This version
inverts the condition, so that it refuses only requests that do have MFA. A key alone should pass.
Save it as `~/aws/mfa-flipped.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": ["s3:DeleteObject", "s3:DeleteBucket"],
      "Resource": ["arn:aws:s3:::shop-backups", "arn:aws:s3:::shop-backups/*"],
      "Condition": {"Bool": {"aws:MultiFactorAuthPresent": "true"}}
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam put-user-policy --user-name dani --policy-name mfa-to-delete --policy-document file://mfa-flipped.json
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$DANI_ID AWS_SECRET_ACCESS_KEY=$DANI_SECRET aws s3 rm s3://shop-backups/erp/sales.csv
delete failed: s3://shop-backups/erp/sales.csv An error occurred (AccessDenied) when calling the DeleteObject operation: Access Denied
```

**moto refused again, so it ignores the condition entirely**: a `Deny` with a `Condition` block
denies always, whatever the condition says. The other half of the test, a session with MFA
succeeding, cannot run either. moto's own checking refuses the credentials its `get-session-token`
returns. So the lab shows the policy and the refusal. Whether the condition matches is AWS's
documented evaluation, not something measured here.

## The day a key leaks

The order matters more than the speed of any one step, and it is the same order every published
playbook uses:

1. **deactivate the key**, at once. `update-access-key --status Inactive` stops it working and can
   be reversed; deleting it first throws away what IAM knows about it, such as when it was last
   used, and cannot be undone if the key turns out to be one a program still needs;
2. **find out what it did.** CloudTrail records every call with the access key id that signed it,
   so the question is a search by that id: which actions, from which addresses, since when. Look in
   particular for new users, new keys and new roles, because a careful intruder makes another way in
   before the first is closed;
3. **undo what it made**, and deal with any session it opened with `GetSessionToken`;
4. **rotate**: a new key for the program, as in the previous section, and the old one deleted;
5. **find the leak**, or the next key leaks the same way.

**CloudTrail is not run in this lab.** It belongs to the `aws-operations` course, and moto 5.2.3
answers `lookup-events` with an internal error.

AWS also acts on its own. When it finds one of your keys in public, through its own scanning or a
report from a partner, it can attach a managed policy called **`AWSCompromisedKeyQuarantineV3`** to
the user. It also writes to the account's contact address. moto carries a copy of the policy, and
its shape says what AWS considers the dangerous part of a stolen key:

```
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3 --version-id v3 --query "PolicyVersion.Document.Statement[].[Effect,length(Action)]" --output text
Deny	98
Deny	1
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3 --version-id v3 --query "PolicyVersion.Document.Statement[0].Action" --output text | tr "\t" "\n" | cut -d: -f1 | sort | uniq -c | sort -rn | head -5
     26 iam
     16 s3
     10 lambda
      6 lightsail
      6 ec2
```

Starting machines, creating users and keys, changing policies, reading CloudTrail: it denies the
actions an intruder uses to spend money and to stay. **It is a brake, not a cure**: it leaves the
key active and does not undo anything. AWS's own guidance still says to rotate the key and
investigate. moto's copy is version `v3` of the policy. AWS revises its managed policies, so the
count can differ in an account. Applying it yourself is the same `attach-user-policy` as any other,
and it goes beside the deactivation, not instead of it:

```
ana@laptop:~/aws$ aws iam update-access-key --user-name dani --access-key-id $DANI_ID --status Inactive
ana@laptop:~/aws$ aws iam attach-user-policy --user-name dani --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3
ana@laptop:~/aws$ aws iam list-attached-user-policies --user-name dani --query "AttachedPolicies[].PolicyName" --output text
AWSCompromisedKeyQuarantineV3	AmazonS3FullAccess
```

## Catching a key before it leaves

The cheapest leak to handle is the one that never reaches a remote. Two tools work at that point,
and neither was run here:

- **GitHub's secret scanning** recognises AWS keys among many other formats. On a public
  repository GitHub reports a found key to AWS, which can set off the quarantine above. With **push
  protection** turned on, a push that contains a key is refused before it is accepted;
- **`git-secrets`**, from AWS Labs, installs hooks in a local repository and refuses a commit whose
  changes match AWS's key patterns. It catches the key on the laptop, before any server sees it.

Both look for the shape of a key, which is why the order of this lesson holds. **The only key that
cannot leak is the one that was never created**, and a scanner is the net under that rule, not a
substitute for it.
