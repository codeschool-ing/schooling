---
title: Where the application gets it
version: 1
---

**There are three places a program can find a secret: in its own code, in its environment when it
starts, or by asking for it at run time with its own identity. Each step down that list removes a
set of people and files that can see the value.** The third is the one Secrets Manager exists for,
and it is less code than the other two.

## Three places, and who else can read each

| where | who else sees the value |
|---|---|
| written in the code or a file beside it | everybody with the repository, its history, its forks and every build made from it |
| in an environment variable set at deploy | everybody who can read the deployment's configuration, plus the process's crash reports, debug pages and any child process |
| fetched at run time from Secrets Manager | whoever the secret's policy allows, and every read leaves a record |

The first row is `booking.env` from two sections ago, and it is never right. The second is the
common one. It is not a secret store so much as a shorter path from the deploy tool to the process:
for a Lambda function, as lesson 13 shows, anybody allowed to read the function's configuration
reads its environment in plain text. **The third keeps the value out of every file and every
configuration**: what is deployed is the secret's name.

## The booking application, asking for it

This is the whole of the fetch, in Python with boto3, the AWS SDK that came into `~/aws/venv` with
moto. Save the code as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "import boto3\n\n", "note": "The SDK finds credentials by itself: in the lab, the session `with_session` puts in the environment; on an AWS machine, the role the platform gives it. Nothing in this file names a key."}, {"code": "secrets = boto3.client(\"secretsmanager\")\npassword = secrets.get_secret_value(SecretId=\"clinic/booking/db\")[\"SecretString\"]\n", "note": "One request, by name. With no version given it returns the value labelled `AWSCURRENT`, so a rotation reaches the next start of the program without a deploy."}, {"code": "print(\"connecting to the database with a password of\", len(password), \"characters\")\n", "note": "A stand-in for opening the database connection. It prints the length and never the value, because a log line is another place a secret leaks."}]}
```

Run it as the role, with the session from the last section:

```
ana@laptop:~/aws$ with_session "$session" python3 app.py
connecting to the database with a password of 24 characters
```

## What this does not fix

**The program still holds the password in memory**, and anybody who can run code inside it, or read
its memory, can read it there. Fetching at run time moves the secret out of files and configuration;
it does not make the running program a safe place. That is the `secure-code` course's territory.

**A fetched secret is cached**, or the database sees a request to Secrets Manager for every
connection. AWS publishes caching clients for that, and a cached value has to be refreshed after a
rotation, which is why `AWSPREVIOUS` keeps working for a while.

**The identity that fetches it is now the thing to protect.** A role allowed to read the secret is
as good as the password. So the role's policy is narrow, as the last section's AWS version was, and
only the platform the program runs on assumes the role. That is lesson 6's question, asked of a
machine: who can become this identity, and could anybody else? 