---
title: Two kinds of credential, and the one that does not expire
version: 1
---

**AWS signs requests with two kinds of credential. A user's access key works until somebody deletes
it. A role's session works for a set time and then stops on its own. Almost everything in this
lesson follows from that difference.** The first kind is what leaks, gets copied into files and
outlives the person who made it, so the safest key is one that never needed to exist.

The wrong picture is that a key and a password are the same thing with different names. A password
belongs to a person who types it, behind a sign-in page that can ask for a second factor. An access
key is a pair of strings that signs API requests directly: no sign-in page, no second factor, and
nothing on AWS's side that knows whether the program holding it is the one it was given to.

## Both kinds, in the lab

Start moto in the first terminal with checking on, and spend the three free requests on `admin`
exactly as lesson 6 did; the transcript below repeats them. Then type two helpers into the second
terminal. `with_key` runs one command with a user's key, as in lesson 6, and `with_session` does the
same with a role session, which carries a third value, the session token:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
with_session() {
  local c=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$c" | jq -r .Credentials.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$c" | jq -r .Credentials.SecretAccessKey) \
  AWS_SESSION_TOKEN=$(echo "$c" | jq -r .Credentials.SessionToken) "$@"
}
```

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
```

caio gets a user and a key, the way the booking application was first set up:

```
ana@laptop:~/aws$ aws iam create-user --user-name caio --query User.Arn --output text
arn:aws:iam::123456789012:user/caio
ana@laptop:~/aws$ aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
ana@laptop:~/aws$ caio=$(aws iam create-access-key --user-name caio)
ana@laptop:~/aws$ echo "$caio" | jq ".AccessKey | {AccessKeyId, Status, CreateDate}"
{
  "AccessKeyId": "AKIARZPUZDIKKKVVGHFV",
  "Status": "Active",
  "CreateDate": "2026-10-23T04:07:08.317255+00:00"
}
```

**No expiry anywhere in that answer.** The key is `Active` from its creation date until somebody
acts. Its id starts with `AKIA`, which is how AWS marks a long-lived user key.

Now the other kind. A role called `booking-app` stands for the machine the application runs on; in
AWS the trust policy would name the service, such as EC2 or Lambda, and here it names `admin`, so
that you can assume it from this terminal. Save the trust policy as `trust-admin.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::123456789012:user/admin"},
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name booking-app --assume-role-policy-document file://trust-admin.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/booking-app
ana@laptop:~/aws$ session=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/booking-app --role-session-name booking --duration-seconds 900)
ana@laptop:~/aws$ echo "$session" | jq ".Credentials | {AccessKeyId, Expiration, SessionToken: (.SessionToken[:24] + \"...\")}"
{
  "AccessKeyId": "ASIARZPUZDIKNBP5G5RW",
  "Expiration": "2026-10-23T04:22:09.783539+00:00",
  "SessionToken": "FQoGZXIvYXdzEBYaD17teWIs..."
}
ana@laptop:~/aws$ with_session "$session" aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/booking-app/booking
```

Three differences, all visible:

| | user's access key | role session |
|---|---|---|
| id begins with | `AKIA` | `ASIA` |
| parts | an id and a secret | an id, a secret and a session token |
| ends | when somebody deletes it | at `Expiration`, here fifteen minutes after it was issued |

The `jq` filter cut the session token short so that it fits on the screen. **Nobody has to remember to revoke a session**: at `Expiration` AWS stops honouring it.
The capture did not wait fifteen minutes to watch that happen, so it is AWS's documented behaviour,
not a run.

## Which kind to use, and where

| who signs | what they should hold |
|---|---|
| a person | a session, from signing in through the identity provider (lesson 6) |
| a program on an AWS machine or function | the session of the role the platform gives it, fetched and renewed by the SDK |
| a program outside AWS, such as a pipeline | a session obtained by federation, which lesson 4 set up |
| a program with no route to any of those | an access key, kept as the next three sections say |

The last row is the only place an access key belongs, and it is smaller than it looks: most programs
that hold a key hold it because nobody set up the row above.
