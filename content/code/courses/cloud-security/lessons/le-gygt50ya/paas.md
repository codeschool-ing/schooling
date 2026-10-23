---
title: PaaS, where the runtime is the provider's and its version is yours
version: 1
---

**On a platform, the provider patches the operating system and the language runtime under your code,
and you pick which runtime version your code asks for. When that version reaches its end of life, the
patches stop, and the function keeps running as if nothing had happened.** AWS Lambda is the example
here; the same holds for App Service on Azure and Cloud Run functions on Google Cloud.

The wrong picture is that on PaaS "the provider keeps it up to date". It does, **within the version
you chose**. Moving to the next version is a change to your code's environment, it can break your
code, and so it is yours to make.

## A function on an old runtime

Keep moto from the last section running. caio's first version of the booking system's confirmation
step is a function. It needs a file of code and a role for the function to run as. The code is
three lines:

```sh
cat > app.py <<'EOF'
def handler(event, context):
    return {"statusCode": 200, "body": "booking confirmed"}
EOF
python3 -m zipfile -c confirm.zip app.py
```

The role says only that Lambda may use it, and lesson 13 is about what to allow it to do:

```
ana@laptop:~/aws$ aws iam create-role --role-name booking-confirm --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query Role.Arn --output text
arn:aws:iam::123456789012:role/booking-confirm
```

The code was copied from an old project, and so was the command that creates the function, runtime
included:

```
ana@laptop:~/aws$ aws lambda create-function --function-name booking-confirm --runtime python3.7 --handler app.handler --role arn:aws:iam::123456789012:role/booking-confirm --zip-file fileb://confirm.zip --query "[FunctionName,Runtime,State]" --output text
booking-confirm	python3.7	Active
```

**moto accepted it, and AWS would not have.** AWS deprecated the `python3.7` runtime for Lambda at the
end of 2023: from then on it received no security patches, and some weeks later AWS stopped accepting
new functions on it. **Not run here.** On AWS this command fails, and that is the easy case. The hard
case is the function created in 2022 that is still running today: AWS does not stop it, it sends
notices to the account's contacts, and the function keeps answering on a runtime nobody patches.

## Finding it, and fixing it

The question that finds it is an inventory, asked of every function:

```
ana@laptop:~/aws$ aws lambda list-functions --query "Functions[].[FunctionName,Runtime]" --output text
booking-confirm	python3.7
```

One function here; in a real account the same query lists them all, and anything on a runtime past its
end of life is a finding. The fix is one request, and on a real system it comes **after** the code has
been tested on the new version, since a runtime change is a change of Python:

```
ana@laptop:~/aws$ aws lambda update-function-configuration --function-name booking-confirm --runtime python3.12 --query "[FunctionName,Runtime]" --output text
booking-confirm	python3.12
ana@laptop:~/aws$ aws lambda list-functions --query "Functions[].[FunctionName,Runtime]" --output text
booking-confirm	python3.12
```

## What else stays on the PaaS list

The runtime version is the item a function shares with a virtual machine, in a smaller form. The
others have no IaaS equivalent and are lesson 13's subject:

| on IaaS you asked | on PaaS you ask |
|---|---|
| which ports are open to the internet | who may invoke the function |
| which packages the operating system has | which libraries the code ships with |
| what the machine's role may do | what the function's role may do |

**The shape changed and the questions did not go away.** A function has no port 22 to leave open, and
it has an invocation permission that can say "anybody". It has no kernel to patch, and it has a
`requirements.txt` that pins a library with a known flaw. A shorter list is a different list, not an
empty one.
