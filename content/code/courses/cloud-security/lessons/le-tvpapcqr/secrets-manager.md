---
title: A secret with a name, a policy and versions
version: 1
---

**Secrets Manager keeps a value, such as a database password, under a name. Who may read it is an
IAM question, every change is a new version, and the application asks for it by name when it
starts.** So the password lives in one place, with an access policy and an audit trail. It no longer
lives in every file and environment that needed a copy.

The wrong picture is a vault as a safer kind of file: put the password in, take it out, done. What
the service adds is not the hiding. It is that **reading the value is a request**, judged by a policy
and recorded like any other, and that replacing it does not mean redeploying everything that uses it.

## Creating one without ever seeing it

The booking application's database password does not need to be typed by anybody. Secrets Manager
generates one, the shell keeps it in a variable, and it goes straight into the secret. A second
secret, for the reports database, gives the next part something to be refused:

```
ana@laptop:~/aws$ pw=$(aws secretsmanager get-random-password --password-length 24 --exclude-punctuation --query RandomPassword --output text)
ana@laptop:~/aws$ aws secretsmanager create-secret --name clinic/booking/db --secret-string "$pw" --query Name --output text
clinic/booking/db
ana@laptop:~/aws$ aws secretsmanager create-secret --name clinic/reports/db --secret-string "$(aws secretsmanager get-random-password --password-length 24 --exclude-punctuation --query RandomPassword --output text)" --query Name --output text
clinic/reports/db
ana@laptop:~/aws$ aws secretsmanager describe-secret --secret-id clinic/booking/db --query "[ARN,VersionIdsToStages]"
[
    "arn:aws:secretsmanager:sa-east-1:123456789012:secret:clinic/booking/db-gyJFep",
    {
        "9a99b4bb-8f5e-497c-aeaf-0c7417a1a090": [
            "AWSCURRENT"
        ]
    }
]
```

Two details in the answer matter later. The ARN ends in a hyphen and six random characters, which
Secrets Manager adds so that a secret deleted and created again under the same name is a different
resource. And the one version carries the label `AWSCURRENT`: the label, not the version id, is how
a reader asks for "the password in use".

## Who may read it

The booking application's role should read its own secret and nothing else. On AWS this is the
policy, with `-*` at the end of the ARN to cover the random suffix:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:sa-east-1:123456789012:secret:clinic/booking/db-*"
    }
  ]
}
```

Save it as `read-db-secret.json`, put it on the role, and ask with a fresh session of the role:

```
ana@laptop:~/aws$ aws iam put-role-policy --role-name booking-app --policy-name read-db-secret --policy-document file://read-db-secret.json
ana@laptop:~/aws$ session=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/booking-app --role-session-name booking)
ana@laptop:~/aws$ with_session "$session" aws secretsmanager get-secret-value --secret-id clinic/booking/db --query "length(SecretString)"

aws: [ERROR]: An error occurred (403) when calling the GetSecretValue operation: <?xml version="1.0" encoding="utf-8"?>
<ErrorResponse><Errors><Error><Code>AccessDenied</Code><Message>User: arn:aws:sts::123456789012:assumed-role/booking-app/booking is not authorized to perform: secretsmanager:GetSecretValue</Message><Type>Sender</Type></Error></Errors></ErrorResponse>
```

**This refusal is the lab's, not AWS's.** moto 5.2.3 judges Secrets Manager requests against
`"Resource": "*"` only, and refused this narrow ARN, which AWS accepts. The error's odd shape, an
HTTP code with an XML page inside it, is moto's too; AWS answers with a short
`AccessDeniedException`. So the lab falls back to the wide version, saved as `read-any-secret.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "*"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam put-role-policy --role-name booking-app --policy-name read-db-secret --policy-document file://read-any-secret.json
ana@laptop:~/aws$ with_session "$session" aws secretsmanager get-secret-value --secret-id clinic/booking/db --query "length(SecretString)"
24
ana@laptop:~/aws$ with_session "$session" aws secretsmanager get-secret-value --secret-id clinic/reports/db --query "length(SecretString)"
24
```

**And the cost of `*` is on the screen:** the booking application's role now reads the reports
database's password too. A program with a flaw that lets somebody make it fetch a secret by name, as
the `secure-code` course's injection lessons describe, would hand over every secret in the account.
On AWS the narrow policy above keeps it to one. The `--query` printed only the length, 24, because
a password printed to a terminal is a password in a scrollback buffer.

## Replacing it

A new password is a new version. `put-secret-value` stores it and moves the `AWSCURRENT` label onto
it; the version that had the label keeps the value under `AWSPREVIOUS`:

```
ana@laptop:~/aws$ new=$(aws secretsmanager get-random-password --password-length 24 --exclude-punctuation --query RandomPassword --output text)
ana@laptop:~/aws$ aws secretsmanager put-secret-value --secret-id clinic/booking/db --secret-string "$new" --query VersionStages --output text
AWSCURRENT
ana@laptop:~/aws$ aws secretsmanager list-secret-version-ids --secret-id clinic/booking/db --query "Versions[].VersionStages[]" --output text
AWSPREVIOUS	AWSCURRENT
ana@laptop:~/aws$ [ "$(aws secretsmanager get-secret-value --secret-id clinic/booking/db --version-stage AWSPREVIOUS --query SecretString --output text)" = "$pw" ] && echo previous is the old password
previous is the old password
ana@laptop:~/aws$ [ "$(aws secretsmanager get-secret-value --secret-id clinic/booking/db --query SecretString --output text)" = "$new" ] && echo current is the new one
current is the new one
```

**`AWSPREVIOUS` is what makes the change safe.** For a while after the label moves, an instance of
the application that started earlier still holds the old password, and the database has to accept
both. Rotation in Secrets Manager is exactly this dance, done by a function: create the new password,
set it in the database, test it, move the label. AWS's *managed* rotation does it for its own
databases; for anything else you write the rotation function, which runs on Lambda, lesson 13's
subject. **Neither was run here**: moto has no database to change, and a rotation function is code
this lesson has no room to write and test.
