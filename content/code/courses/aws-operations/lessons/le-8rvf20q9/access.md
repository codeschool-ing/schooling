---
title: Who may read it, and what moto checks
version: 1
---

A secret is only as private as the policies that reach it. The shop's API should read its database
secret and nothing else: not the payment provider's key, not the parameters of staging, and not write
anything at all. This is the lesson about a refusal, so the lab needs a moto that refuses.

## A moto that checks

By default moto lets everybody do everything. Stop it in its terminal with Ctrl+C, and start it again
with **`INITIAL_NO_AUTH_ACTION_COUNT`**: the number of requests it lets through unchecked before it
starts evaluating policies. Nine is the number this section's setup needs, every request counting,
a mistyped one included:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=9 ~/aws/venv/bin/moto_server -p 4567
```

The new moto starts empty. Two policies, one for the application, naming its secret with the six
characters' wildcard, and one that names every secret:

`app-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:sa-east-1:123456789012:secret:shop/prod/db-*"
    }
  ]
}
```

`wide-policy.json`:

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

Then the setup, seven requests: two secrets, a parameter, and two users with a policy each:

```sh
cd ~/aws/secrets
aws secretsmanager create-secret --name shop/prod/db --secret-string '{"username":"shop","password":"first-pass"}' --query Name
aws secretsmanager create-secret --name shop/prod/payments --secret-string '{"provider":"lab"}' --query Name
aws ssm put-parameter --name /shop/prod/db/host --type String --value db.internal --query Version
aws iam create-user --user-name shop-app --query User.Arn
aws iam put-user-policy --user-name shop-app --policy-name read-db-secret --policy-document file://app-policy.json
aws iam create-user --user-name shop-wide --query User.Arn
aws iam put-user-policy --user-name shop-wide --policy-name read-any-secret --policy-document file://wide-policy.json
```

The eighth and ninth make an access key for each user. **They are read into variables and never
printed**: an access key belongs in no terminal's scrollback, even a lab's.

```
ana@laptop:~/aws/secrets$ read -r KEY SECRET < <(aws iam create-access-key --user-name shop-app --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)
ana@laptop:~/aws/secrets$ read -r WKEY WSECRET < <(aws iam create-access-key --user-name shop-wide --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)
```

## The application's user

```
ana@laptop:~/aws/secrets$ AWS_ACCESS_KEY_ID=$KEY AWS_SECRET_ACCESS_KEY=$SECRET aws sts get-caller-identity --query Arn
"arn:aws:iam::123456789012:user/shop-app"
ana@laptop:~/aws/secrets$ AWS_ACCESS_KEY_ID=$KEY AWS_SECRET_ACCESS_KEY=$SECRET aws ssm get-parameter --name /shop/prod/db/host 2>&1 | grep -o "User: [^<]*"
User: arn:aws:iam::123456789012:user/shop-app is not authorized to perform: ssm:GetParameter
ana@laptop:~/aws/secrets$ AWS_ACCESS_KEY_ID=$KEY AWS_SECRET_ACCESS_KEY=$SECRET aws secretsmanager get-secret-value --secret-id shop/prod/db 2>&1 | grep -o "User: [^<]*"
User: arn:aws:iam::123456789012:user/shop-app is not authorized to perform: secretsmanager:GetSecretValue
```

The identity is `shop-app`. Reading a parameter is refused, correctly: its policy grants no `ssm`
action. **Reading its own secret is refused too, and on AWS it would not be.** This is the limit
lesson 1 named: **moto checks the action and not the resource**. It treats every request as aimed at
`*`, so a statement allowing one secret's ARN never matches, and the narrow policy, the right one,
allows nothing here.

## The user with the wide policy

```
ana@laptop:~/aws/secrets$ AWS_ACCESS_KEY_ID=$WKEY AWS_SECRET_ACCESS_KEY=$WSECRET aws secretsmanager get-secret-value --secret-id shop/prod/db --query Name
"shop/prod/db"
ana@laptop:~/aws/secrets$ AWS_ACCESS_KEY_ID=$WKEY AWS_SECRET_ACCESS_KEY=$WSECRET aws secretsmanager get-secret-value --secret-id shop/prod/payments --query Name
"shop/prod/payments"
ana@laptop:~/aws/secrets$ AWS_ACCESS_KEY_ID=$WKEY AWS_SECRET_ACCESS_KEY=$WSECRET aws secretsmanager put-secret-value --secret-id shop/prod/db --secret-string x 2>&1 | grep -o "User: [^<]*"
User: arn:aws:iam::123456789012:user/shop-wide is not authorized to perform: secretsmanager:PutSecretValue
```

With `"Resource": "*"`, moto allows reading both secrets, and so would AWS: **that is what the wide
policy says**, and the payment provider's key is now readable by anything holding this user's key. The
write is refused, under moto and on AWS alike, because no statement allows `PutSecretValue`.

So the lab shows one half of the rule, and AWS's documentation the other:

| request | moto | AWS |
|---|---|---|
| `shop-app` reads `shop/prod/db` | refused | **allowed** |
| `shop-app` reads `shop/prod/payments` | refused | refused |
| `shop-app` reads a parameter | refused | refused |
| `shop-wide` reads either secret | allowed | allowed |
| `shop-wide` writes a secret | refused | refused |

On AWS, `app-policy.json` is the policy to ship. A secret can carry a **resource policy** as well,
naming the roles that may read it, which keeps the decision beside the secret; moto stores resource
policies and evaluates none.

## Afterwards

The test key is not a user in this moto, and the count is spent:

```
ana@laptop:~/aws/secrets$ aws secretsmanager list-secrets 2>&1 | grep -o "<Message>[^<]*"
<Message>The security token included in the request is invalid.
```

Those are the words lesson 1 said meant a request had reached AWS. Here they come from moto, which now
checks keys and has never heard of `test`. Stop this moto with Ctrl+C and start it again without the
variable before the next lesson.
