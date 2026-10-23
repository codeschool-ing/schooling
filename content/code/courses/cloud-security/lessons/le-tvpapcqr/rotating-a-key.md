---
title: Rotating a key without stopping the application
version: 1
---

**A user may hold two access keys at once, and that is the whole mechanism of rotation: create the
second, move the application onto it, prove the first is unused, then delete the first.** The same
five steps serve a key that leaked this morning and a key that has simply reached the age your
policy allows, usually ninety days.

The wrong picture is that rotating means deleting the old key and creating a new one. In that order
the application is down from the first step until somebody deploys the new key, which is exactly the
outage that makes people put rotation off.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l07-rotation\" aria-label=\"Rotating an access key without an outage, as a timeline of two keys. Step 1: the old key is active and the application uses it. Step 2: a second key is created; both are active. Step 3: the application is switched to the new key. Step 4: the old key is deactivated and its last use is watched for a while. Step 5: the old key is deleted. At every moment the application holds a key that works.\"><text x=\"70.0\" y=\"76.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">old key</text><text x=\"70.0\" y=\"136.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">new key</text><rect x=\"80.0\" y=\"60.0\" width=\"400.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">active</text><rect x=\"480.0\" y=\"60.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"535.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">inactive</text><rect x=\"260.0\" y=\"120.0\" width=\"420.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">active</text><text x=\"70.0\" y=\"186.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">application</text><path d=\"M80.0 186.0 L370.0 186.0\" stroke=\"var(--amber)\" stroke-width=\"3\" fill=\"none\"></path><path d=\"M370.0 186.0 L680.0 186.0\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><text x=\"225.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uses the old key</text><text x=\"525.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uses the new key</text><path d=\"M260.0 40.0 L260.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M260.0 96.0 L260.0 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M260.0 156.0 L260.0 196.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"260.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2. create</text><path d=\"M370.0 40.0 L370.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M370.0 96.0 L370.0 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M370.0 156.0 L370.0 196.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"370.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">3. switch</text><path d=\"M480.0 40.0 L480.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M480.0 96.0 L480.0 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M480.0 156.0 L480.0 196.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"480.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4. deactivate</text><path d=\"M590.0 40.0 L590.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M590.0 96.0 L590.0 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M590.0 156.0 L590.0 196.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"590.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5. delete</text><text x=\"80.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1. old key only</text><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">at every moment the application holds a key that works</text><text x=\"360.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">two keys per user is the limit: step 5 makes room for the next rotation</text></svg>", "caption": "The five steps in time. Deleting first and creating second would leave a gap where the application holds nothing that works."}
```

## Second key

```
ana@laptop:~/aws$ caio2=$(aws iam create-access-key --user-name caio)
ana@laptop:~/aws$ aws iam list-access-keys --user-name caio --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text
AKIARZPUZDIKKKVVGHFV	Active
AKIARZPUZDIKFRWREH5L	Active
ana@laptop:~/aws$ aws iam create-access-key --user-name caio

aws: [ERROR]: An error occurred (LimitExceeded) when calling the CreateAccessKey operation: Cannot exceed quota for AccessKeysPerUser: 2
```

**Two is the limit, and the third request says so.** A key that nobody deleted after the last
rotation blocks the next one, which is a useful alarm: it means the previous rotation was never
finished.

## Switch

Rewrite `booking.env` with the new key, which is what deploying the new configuration amounts to:

```sh
printf 'AWS_ACCESS_KEY_ID=%s\nAWS_SECRET_ACCESS_KEY=%s\n' \
  "$(echo "$caio2" | jq -r .AccessKey.AccessKeyId)" \
  "$(echo "$caio2" | jq -r .AccessKey.SecretAccessKey)" > booking/booking.env
```

Before deleting anything, **prove nothing still uses the old key**. On AWS that is a wait and a
reading: deactivate it, leave it a day or a week, and read `get-access-key-last-used` for it. A date
that stops moving, and no complaint from anybody, means no forgotten job depends on it. Deactivation
is the safe half because it can be undone. Check that the file now holds the new key's id, then
deactivate the old one and try it:

```
ana@laptop:~/aws$ grep -c "$(echo "$caio2" | jq -r .AccessKey.AccessKeyId)" booking/booking.env
1
ana@laptop:~/aws$ aws iam update-access-key --user-name caio --access-key-id $(echo "$caio" | jq -r .AccessKey.AccessKeyId) --status Inactive
ana@laptop:~/aws$ with_key "$caio" aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/caio
```

**moto ignored the deactivation**, as it did in lesson 6: the inactive key still signed a request
that succeeded. AWS refuses requests signed with an inactive key. So in this lab the proof has to
come from the deletion.

## Delete, then prove

```
ana@laptop:~/aws$ aws iam delete-access-key --user-name caio --access-key-id $(echo "$caio" | jq -r .AccessKey.AccessKeyId)
ana@laptop:~/aws$ with_key "$caio" aws sts get-caller-identity --query Arn --output text

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
ana@laptop:~/aws$ aws iam detach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3
ana@laptop:~/aws$ with_key "$caio2" aws s3 ls
ana@laptop:~/aws$ aws iam list-access-keys --user-name caio --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text
AKIARZPUZDIKFRWREH5L	Active
```

The old key is refused with `InvalidClientTokenId`. The quarantine came off once the exposed key was
gone, and the new key may list buckets again; the account has none, so the answer is empty rather
than refused. One key is left, and it is the one in `booking.env`.

The quarantine here was detached straight away so that the transcript stays short. On a real
incident the step between deletion and detaching is the investigation: what the exposed key did
while it was out, read from the trail lesson 15 builds. **A key rotated after a leak is a closed
door, not an answer to what came through it.**

## Rotation is a symptom

A key that has to be rotated every ninety days is a key that exists. The two-kinds section's table
had one row where an access key belongs; everything above it gets a role session that expires on its
own and is never rotated by anybody. When a review finds the same key rotated four times a year for
three years, the finding is not that rotation works, but that nobody asked why the program could not
assume a role.
