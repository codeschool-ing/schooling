---
title: What encryption at rest protects against, and what it does not
version: 1
---

**Encryption at rest protects data from anybody who reaches the disk without going through the
service. It does nothing against a request the service answers.** S3 decrypts an object for every
request it allows, so an encrypted object behind a public policy is served to a stranger in plain
text, decrypted on the way out.

The wrong idea is the checkbox: *the bucket is encrypted, so the data is safe*. Audits ask about it,
dashboards turn green for it, and since January 2023 AWS encrypts every new object in S3 whether
anybody asks or not. If encryption at rest stopped exposures, lesson 9 would have no incidents in
it. It stops a different thing.

## Two ways to reach the data

| who | how they reach it | does encryption at rest stop them? |
|---|---|---|
| somebody holding a disk, a backup tape or a copy of the provider's storage | around the service, straight to the bytes | **yes**: what they hold is ciphertext without the key |
| somebody the service answers: a user with permission, a stolen key, or anybody at all through a public policy | through the service's own API | **no**: the service decrypts for them, because it was told to |

The first row is real and is the provider's half of the work, which lesson 2 placed on their side of
the line: drives that leave a data centre, a misdirected backup, an engineer with physical access.
The second row is where every incident in lesson 9 happened, and **it is decided by permissions, not
by encryption**. A defender who mixes the two up ends up with green dashboards and public buckets.

## Encrypted and public, in your lab

Start moto, empty, in the first terminal, and give the clinic a bucket with one object written under
S3's own encryption. A file stands in for a record:

```sh
printf 'patient: Maria Souza\nallergy: penicillin\n' > record.txt
```

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-records --key maria-souza.txt --body record.txt --server-side-encryption AES256 --query ServerSideEncryption
"AES256"
```

`"AES256"` is S3 saying it stored the object encrypted, under a key S3 owns
and manages. Now the mistake of lesson 1, one bucket policy that allows everybody to read, and the
stranger's request:

```
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket clinic-records --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::clinic-records/*"}]}'
ana@laptop:~/aws$ curl -s -w "%{http_code}\n" http://localhost:4567/clinic-records/maria-souza.txt
patient: Maria Souza
allergy: penicillin
200
```

**Encrypted at rest, and served in plain text to a request with no identity at all.** Nothing went
wrong with the encryption; it did its job on the disk, and S3 undid it for a request the policy
allowed. AWS would answer the same way for an object encrypted with S3's own key: the transcript is
moto's, and the behaviour is S3's.

Remove the policy before you go on:

```
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket clinic-records
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-records/maria-souza.txt
403
```

## So what is a key worth?

If S3 decrypts for anybody it serves, the useful question is **who else has to agree before it
does**. With S3's own key, nobody does: permission on the bucket is permission on the plain text.
With a key the clinic manages in KMS, using the key is a second permission, written in a second
place, and a request has to hold both. The next section is the three kinds of key, and the one after
it is that second permission at work.
