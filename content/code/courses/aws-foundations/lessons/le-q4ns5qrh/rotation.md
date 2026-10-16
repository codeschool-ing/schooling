---
title: Rotating a key without stopping the program that uses it
version: 1
---

**Rotation is a handover between two keys: create the second, move the program to it, check that the
first has gone quiet, switch the first off, wait, and only then delete it.** Every step can be
undone except the last, and the order exists so that a mistake shows up while it can still be
undone. This section runs it end to end in moto against the shop's one honest key holder,
`erp-sync`. That is the accounting system in the office, which uploads the day's sales to
`shop-backups`.

## A moto that judges

moto records last-used dates and refused keys only when it checks permissions, so start it the way
lesson 7 does. In the first terminal, Ctrl+C, then
`INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567`. moto lets three requests through unchecked and
judges every one after that. Spend the three on an administrator. The `read` puts its key straight
into the environment, so the secret never reaches the screen:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY < <(aws iam create-access-key --user-name admin --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

The fourth request was judged, and passed. Lesson 7 explains this start in full. From here on, every
command in this terminal signs as `admin`.

## The key holder

`erp-sync` may put files under `erp/` in one bucket and do nothing else. Save its policy as
`~/aws/upload-erp.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::shop-backups/erp/*"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-backups --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/shop-backups
ana@laptop:~/aws$ aws iam create-user --user-name erp-sync --query User.Arn --output text
arn:aws:iam::123456789012:user/erp-sync
ana@laptop:~/aws$ aws iam put-user-policy --user-name erp-sync --policy-name upload-erp --policy-document file://upload-erp.json
ana@laptop:~/aws$ read -r OLD_ID OLD_SECRET < <(aws iam create-access-key --user-name erp-sync --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)
ana@laptop:~/aws$ echo $OLD_ID
AKIARZPUZDIKCZVHDNNE
```

**The command prints the key id and not the secret.** In the office somebody would type the secret
once into the accounting system's settings and nowhere else. Here the two variables stand in for
that system, which uploads with them:

```
ana@laptop:~/aws$ printf 'order,total_cents\n1001,4990\n' > sales.csv
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$OLD_ID AWS_SECRET_ACCESS_KEY=$OLD_SECRET aws s3 cp --no-progress sales.csv s3://shop-backups/erp/sales.csv
upload: ./sales.csv to s3://shop-backups/erp/sales.csv
```

## The rotation, step by step

**Create the second key**, while the first keeps working:

```
ana@laptop:~/aws$ read -r NEW_ID NEW_SECRET < <(aws iam create-access-key --user-name erp-sync --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)
ana@laptop:~/aws$ aws iam list-access-keys --user-name erp-sync --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text
AKIARZPUZDIKCZVHDNNE	Active
AKIARZPUZDIKCFJSZ6AR	Active
ana@laptop:~/aws$ aws iam create-access-key --user-name erp-sync --query AccessKey.AccessKeyId --output text

aws: [ERROR]: An error occurred (LimitExceeded) when calling the CreateAccessKey operation: Cannot exceed quota for AccessKeysPerUser: 2
```

**The third key was refused**: two per user, enforced by moto as AWS documents it. That limit is
also why rotation has to finish. A user left with two active keys has no free slot for the next
rotation, and usually has a forgotten copy of one of them somewhere.

**Move the program, then check that the old key went quiet.** The accounting system gets the new
pair in its settings, and the next upload uses it. `get-access-key-last-used` says when each key
last signed a request, and for which service:

```
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$NEW_ID AWS_SECRET_ACCESS_KEY=$NEW_SECRET aws s3 cp --no-progress sales.csv s3://shop-backups/erp/sales.csv
upload: ./sales.csv to s3://shop-backups/erp/sales.csv
ana@laptop:~/aws$ aws iam get-access-key-last-used --access-key-id $OLD_ID --query "AccessKeyLastUsed.[LastUsedDate,ServiceName]" --output text
2026-10-16T16:37:39.082205+00:00	s3
ana@laptop:~/aws$ aws iam get-access-key-last-used --access-key-id $NEW_ID --query "AccessKeyLastUsed.[LastUsedDate,ServiceName]" --output text
2026-10-16T16:37:41.198810+00:00	s3
```

Both keys have a date and the service `s3`, because both have uploaded. The date is the field to
watch: **when the old key's date stops moving, nothing is using it any more.** A key whose date
keeps moving after the switch has a second user nobody knew about. Finding that user is the reason
you do not delete the old key yet.

**Switch the old key off.** `Inactive` refuses every request signed with it, and it is reversible:
if something breaks, `--status Active` brings the key back in one command.

```
ana@laptop:~/aws$ aws iam update-access-key --user-name erp-sync --access-key-id $OLD_ID --status Inactive
ana@laptop:~/aws$ aws iam list-access-keys --user-name erp-sync --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text
AKIARZPUZDIKCZVHDNNE	Inactive
AKIARZPUZDIKCFJSZ6AR	Active
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$OLD_ID AWS_SECRET_ACCESS_KEY=$OLD_SECRET aws s3 cp --no-progress sales.csv s3://shop-backups/erp/sales.csv
upload: ./sales.csv to s3://shop-backups/erp/sales.csv
```

**The old key still uploaded, and that is moto, not AWS.** moto 5.2.3 records the status and goes on
accepting the key, where AWS refuses every request signed with an inactive key. So the lab cannot
show the one thing this step is for: the failure of whatever still used the key. A real rotation
waits here. A week covers a program that runs daily; a month covers one that runs at the end of the
month.

**Delete it**, once the wait has passed with nothing broken:

```
ana@laptop:~/aws$ aws iam delete-access-key --user-name erp-sync --access-key-id $OLD_ID
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$OLD_ID AWS_SECRET_ACCESS_KEY=$OLD_SECRET aws s3 cp --no-progress sales.csv s3://shop-backups/erp/sales.csv
upload failed: ./sales.csv to s3://shop-backups/erp/sales.csv An error occurred (InvalidAccessKeyId) when calling the PutObject operation: The AWS Access Key Id you provided does not exist in our records.
```

Now the old pair names nothing, and moto refuses it the way AWS would.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l12-rotation\" aria-label=\"The rotation of erp-sync's key as a timeline of five steps: create the second key, move the program to it, check that the old key went quiet, make the old key inactive, and after a wait delete it. The old key is active until the fourth step, inactive until the fifth, and gone after it. The new key is active from the first step on. The program signs with the old key until the second step and with the new one after. Every step is reversible except the deletion.\"><text x=\"190.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1 create</text><text x=\"190.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the second</text><path d=\"M190.0 56.0 L190.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"290.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2 move the</text><text x=\"290.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">program</text><path d=\"M290.0 56.0 L290.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"390.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">3 check</text><text x=\"390.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">last used</text><path d=\"M390.0 56.0 L390.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"490.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4 make old</text><text x=\"490.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">inactive</text><path d=\"M490.0 56.0 L490.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"630.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5 delete</text><text x=\"630.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the old key</text><path d=\"M630.0 56.0 L630.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"560.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">wait</text><text x=\"20.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">old key</text><rect x=\"110.0\" y=\"76.0\" width=\"380.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Active</text><rect x=\"490.0\" y=\"76.0\" width=\"140.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"560.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Inactive</text><text x=\"20.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">new key</text><rect x=\"190.0\" y=\"126.0\" width=\"510.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Active</text><text x=\"20.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the program</text><rect x=\"110.0\" y=\"178.0\" width=\"180.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">signs with the old</text><rect x=\"290.0\" y=\"178.0\" width=\"410.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">signs with the new</text><path d=\"M110.0 245.0 L626.0 245.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"368.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">every step so far can be undone</text><path d=\"M634.0 245.0 L700.0 245.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"667.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cannot</text><text x=\"360.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">two keys at once is the limit, which is why the old one must go</text></svg>", "caption": "The old key is switched off before it is deleted, so that whatever still used it fails while the failure can be undone."}
```

## The credential report

**The credential report is one CSV with a row per IAM user.** It says whether each has a password,
MFA and keys, how old the keys are and when they were last used. IAM generates it on request, and
you ask again if it is more than four hours old. `get-credential-report` returns it in base64, so it
goes through `base64 -d`, and `cut` keeps five of its twenty-two columns:

```
ana@laptop:~/aws$ aws iam generate-credential-report --query State --output text
STARTED
ana@laptop:~/aws$ aws iam generate-credential-report --query State --output text
COMPLETE
ana@laptop:~/aws$ aws iam get-credential-report --query Content --output text | base64 -d | cut -d, -f1,9,10,11,14
user,access_key_1_active,access_key_1_last_rotated,access_key_1_last_used_date,access_key_2_active
admin,true,2026-10-16T16:37:34+00:00,2026-10-16T16:37:48+00:00,false
erp-sync,true,2026-10-16T16:37:39+00:00,2026-10-16T16:37:41+00:00,false
```

`erp-sync`'s first key slot now holds the new key and the second is empty. That is what a finished
rotation looks like. Against AWS the report also has a first row for the account's root user, called
`<root_account>`, and moto's has none.

Reading ages by eye works for three users and not for three hundred. This program reads the report
and prints every active key with its age in days. Save it as `~/aws/key-ages.py`:

```schooling-example
{"language": "python", "file": "key-ages.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Prints the age of every active access key in a credential report.\n\n    aws iam get-credential-report --query Content --output text | base64 -d | python3 key-ages.py\n\"\"\"\nimport csv\nimport sys\nfrom datetime import datetime, timezone\n\nLIMIT = 90\n\n", "note": "Only Python's own library. `LIMIT` is the age past which a key is flagged: 90 days is the line the CIS benchmark draws, and AWS Security Hub's control `IAM.3` checks the same number."}, {"code": "now = datetime.now(timezone.utc)\nfor row in csv.DictReader(sys.stdin):\n    for n in ('1', '2'):\n        if row[f'access_key_{n}_active'] != 'true':\n            continue\n", "note": "The report's first line names its columns, so each row reads as a dictionary. Each user has two key slots, and an empty or inactive slot is skipped."}, {"code": "        rotated = datetime.fromisoformat(row[f'access_key_{n}_last_rotated'])\n        days = (now - rotated).days\n        used = row[f'access_key_{n}_last_used_date']\n        flag = 'ROTATE' if days > LIMIT else 'ok'\n        print(f\"{row['user']:<10} key {n} {days:>4} days  last used {used}  {flag}\")\n", "note": "`last_rotated` is when the key was created, so its distance from now is the key's age. The last-used date is printed beside it: an old key that is never used is a key to delete rather than rotate."}]}
```

```
ana@laptop:~/aws$ aws iam get-credential-report --query Content --output text | base64 -d | python3 key-ages.py
admin      key 1    0 days  last used 2026-10-16T16:37:49+00:00  ok
erp-sync   key 1    0 days  last used 2026-10-16T16:37:41+00:00  ok
```

**Every key is 0 days old**, because moto was started minutes ago, so nothing is flagged. In an
account that has existed for years the same program prints the keys nobody has touched since they
were made.
