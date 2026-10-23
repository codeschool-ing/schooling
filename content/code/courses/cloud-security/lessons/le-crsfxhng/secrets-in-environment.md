---
title: A password in an environment variable is a password in the configuration
version: 1
---

**An environment variable of a Lambda function is part of the function's configuration, and anybody
allowed to read the configuration reads the value.** Lambda encrypts the variables at rest, which is
true and beside the point. They are decrypted for every caller allowed to describe the function, and
that permission is handed out far more widely than access to a database password should ever be.

The habit comes from a good rule applied in the wrong place. The `secure-code` course's lesson 16
says secrets belong in the environment and not in the source, and for a program on your own server
that is right. **On Lambda, "the environment" is a field anyone with `lambda:GetFunctionConfiguration`
reads in one call.**

## The password, read back

The booking database needs a password, and caio put it where the twelve-factor habit says to:

```
ana@laptop:~/aws$ aws lambda update-function-configuration --function-name daily-export --environment "Variables={DB_PASSWORD=Clinic-2026-pass}" --query LastUpdateStatus --output text
Successful
ana@laptop:~/aws$ aws lambda get-function-configuration --function-name daily-export --query Environment
{
    "Variables": {
        "DB_PASSWORD": "Clinic-2026-pass"
    }
}
```

That is ana reading it, as an administrator. Now look at who else can. bia, the analyst, has
`ReadOnlyAccess`, the managed policy AWS maintains for people who look and do not touch. Its Lambda
and Secrets Manager actions are these:

```
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --version-id $(aws iam get-policy --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --query Policy.DefaultVersionId --output text) --query "PolicyVersion.Document.Statement[].Action[]" --output json | jq -r '.[] | select(startswith("lambda:") or startswith("secretsmanager:"))'
lambda:Get*
lambda:List*
secretsmanager:Describe*
secretsmanager:GetResourcePolicy
secretsmanager:List*
```

**`lambda:Get*` covers `GetFunctionConfiguration`, so every read-only user reads the database
password.** And `secretsmanager:` appears without `GetSecretValue`: AWS's read-only policy lets a
person see that a secret exists and never what it holds. That difference is the whole fix.

## The secret where secrets are kept

Lesson 7 showed Secrets Manager keeping a secret and its versions. The password goes there, and the
function keeps only the secret's **name** in its environment:

```
ana@laptop:~/aws$ aws secretsmanager create-secret --name clinic/db --secret-string Clinic-2026-pass --query ARN --output text
arn:aws:secretsmanager:sa-east-1:123456789012:secret:clinic/db-gkfvuq
ana@laptop:~/aws$ aws lambda update-function-configuration --function-name daily-export --environment "Variables={DB_SECRET=clinic/db}" --query Environment
{
    "Variables": {
        "DB_SECRET": "clinic/db"
    }
}
```

The role gets the one action it now needs, on that one secret. The ARN ends in six characters
Secrets Manager adds to every secret's name, which is why the policy ends `clinic/db-*`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:sa-east-1:123456789012:secret:clinic/db-*"
    }
  ]
}
```

Save it as `read-db-secret.json`, and attach it beside `write-exports` from the first section:

```
ana@laptop:~/aws$ aws iam put-role-policy --role-name export-fn --policy-name read-db-secret --policy-document file://read-db-secret.json
```

The handler reads the secret on its first call and keeps it for the life of that copy of the
function. Replace `handler.py` with this:

```schooling-example
{"language": "python", "file": "handler.py", "parts": [{"code": "import os\n\nimport boto3\n\n_password = None\n\n", "note": "`boto3` is the AWS SDK for Python, and Lambda's Python runtime includes it. `_password` lives at module level, so it survives between calls served by the same copy of the function, as the `cloud` course's lesson 8 showed."}, {"code": "def db_password():\n    global _password\n    if _password is None:\n        answer = boto3.client(\"secretsmanager\").get_secret_value(\n            SecretId=os.environ[\"DB_SECRET\"])\n        _password = answer[\"SecretString\"]\n    return _password\n\n", "note": "**The environment holds the name, never the value.** The value is fetched once, with the execution role's own credentials, so only something running as that role can fetch it. A rotated password reaches new copies of the function without a redeploy."}, {"code": "def handler(event, context):\n    password = db_password()\n    return {\"statusCode\": 200, \"body\": f\"export done, password of {len(password)} characters\"}\n", "note": "The function would connect to the database here. It reports only the password's length, so that the run below proves the value arrived without printing it."}]}
```

Upload it with the same two commands as before, then do what Lambda would do: call the handler with
an event and a context. Your machine can, with `DB_SECRET` set and the SDK pointed at moto by the
`AWS_ENDPOINT_URL` from `env.sh`:

```
ana@laptop:~/aws$ python3 -m zipfile -c function.zip handler.py
ana@laptop:~/aws$ aws lambda update-function-code --function-name daily-export --zip-file fileb://function.zip --query LastUpdateStatus --output text
Successful
ana@laptop:~/aws$ DB_SECRET=clinic/db python3 -c 'from handler import handler; print(handler({}, None))'
{'statusCode': 200, 'body': 'export done, password of 16 characters'}
```

## And bia, asking

The difference between the two readings has to be shown as a refusal, so start moto once more, with
its checking on and empty, and make `admin` with the same requests as the first section. Then the
secret, and bia with `ReadOnlyAccess` and a key:

```
ana@laptop:~/aws$ aws secretsmanager create-secret --name clinic/db --secret-string Clinic-2026-pass --query Name --output text
clinic/db
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
ana@laptop:~/aws$ bia=$(aws iam create-access-key --user-name bia)
ana@laptop:~/aws$ with_key "$bia" aws secretsmanager list-secrets --query "SecretList[].Name" --output text
clinic/db
ana@laptop:~/aws$ with_key "$bia" aws secretsmanager get-secret-value --secret-id clinic/db --query SecretString --output text

aws: [ERROR]: An error occurred (403) when calling the GetSecretValue operation: <?xml version="1.0" encoding="utf-8"?>
<ErrorResponse><Errors><Error><Code>AccessDenied</Code><Message>User: arn:aws:iam::123456789012:user/bia is not authorized to perform: secretsmanager:GetSecretValue</Message><Type>Sender</Type></Error></Errors></ErrorResponse>
```

**bia can see that `clinic/db` exists, and cannot read it.** Reading the function's configuration
would still show her `DB_SECRET=clinic/db`, which is a name and harms nobody. moto answers Lambda's
read requests with signature errors while its checking is on, so that last reading was not run with
bia's key; the policy above is what grants it.

A secret moved out of the environment still has a past. **The old password sat in the function's
configuration, readable by every read-only user, for as long as it was there**, so it is changed in
the database as well as moved. Lesson 7 is how.
