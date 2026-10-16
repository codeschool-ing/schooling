---
title: Turning on moto's checking
version: 1
---

Until now moto has said yes to everything. **From this section on, moto judges every request**: a
user without permission is refused, as lesson 1 promised. Lessons 8 and 9 start the same way, so
this is worth doing slowly once.

## What it checks, and what it does not

Once its checking is on, moto refuses a request the way AWS would when the reason is one of these:

- **no policy of the caller allows the action**, whether the policy is inline, customer-managed or
  AWS-managed, and whether it reached the caller directly, through a group or through a role;
- **a policy of the caller denies it explicitly**, even if another allows it;
- **a role's trust policy does not name the caller** who is trying to assume it;
- **the key is one moto's IAM never issued**, such as `test`.

It does not check permission boundaries, service control policies, a bucket's own policy, session
policies, or conditions inside a statement. Lesson 8 measures each of those and teaches what AWS
does instead.

## The count

The switch is an environment variable read when moto starts: **`INITIAL_NO_AUTH_ACTION_COUNT=3`
lets the first three requests through unchecked, and judges every request after them.** The three
free requests exist because a judge needs somebody to be the administrator, and there is nobody yet:
they are spent making one. After the third, every request has to be signed with a key moto's own IAM
issued, and that key's policies decide.

**Every request counts, including one that fails.** A typo that comes back as an error has still
spent one of the three. Requests to moto's own control address, `/moto-api/`, do not count, and the
command line never sends any. In the first terminal, stop moto with Ctrl+C and start it like this:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

In the second, the three requests: a user called `admin`, AWS's `AdministratorAccess` policy for
it, and an access key. The key is kept in a shell variable, `key`, rather than printed or saved:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "4mf2zzta72ljh4imk5i5",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/admin"
}
ana@laptop:~/aws$ aws iam list-users --query "Users[].UserName"
[
    "admin"
]
```

The fourth command was refused, and the reason is in its words: **the request was signed with
`test`, and moto's IAM never issued a key called `test`**. That is the count running out, and it
proves the checking is on before anything else is tried.

The `export` line moves this terminal onto admin's key. `jq -r` takes one field out of the JSON
that `create-access-key` returned, and `export` puts the id and the secret where the command line
looks first. **These are moto's keys, made up by moto and worthless anywhere else**; they are on
nobody's screen and in no file, and they vanish when moto stops. `get-caller-identity` confirms
it: from here on the terminal works as `admin`.

A new terminal reads `env.sh` and starts with `test` again, which moto now refuses, and the
variable `key` lives only in this shell. **Work in this one terminal for the whole lesson.**

## When the count goes wrong

If one of the three requests fails, the count has still moved. This is what a typo in the policy's
name looks like, in a moto started with the same count:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin
{
    "User": {
        "Path": "/",
        "UserName": "admin",
        "UserId": "4mf2zzta72ljh4imk5i5",
        "Arn": "arn:aws:iam::123456789012:user/admin",
        "CreateDate": "2026-10-16T16:23:16.286274+00:00"
    }
}
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAcess

aws: [ERROR]: An error occurred (NoSuchEntity) when calling the AttachUserPolicy operation: Policy arn:aws:iam::aws:policy/AdministratorAcess does not exist or is not attachable.
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ aws iam create-access-key --user-name admin --query AccessKey.AccessKeyId

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the CreateAccessKey operation: The security token included in the request is invalid.
```

The misspelt `AdministratorAcess` spent the second request, the corrected command spent the third,
and **the access key arrived fourth and was refused**. There is no way back from inside: stop moto,
start it again with the count, and type the three requests again.

## One command as somebody else

The next sections give bia a policy and then act as her, one command at a time, while the terminal
stays `admin`. A small shell function does it: it takes the JSON that `create-access-key` printed,
and runs the rest of the line with that key in the environment of that one command only. Type it
into the second terminal:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
```

`with_key "$bia" aws s3 ls` then runs `aws s3 ls` signed with bia's key, and the next command is
signed with admin's again. Lessons 8 and 9 use the same function.
