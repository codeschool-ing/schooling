---
title: Secrets Manager, versions and stages
version: 1
---

A secret is usually a small JSON document with everything one connection needs:

```
ana@laptop:~/aws/secrets$ aws secretsmanager create-secret --name shop/prod/db --secret-string '{"username":"shop","password":"first-pass"}' --query ARN --output text
arn:aws:secretsmanager:sa-east-1:123456789012:secret:shop/prod/db-BdrPcr
ana@laptop:~/aws/secrets$ aws secretsmanager get-secret-value --secret-id shop/prod/db --query '[SecretString,VersionStages[0]]' --output text
{"username":"shop","password":"first-pass"}	AWSCURRENT
```

The ARN ends with a hyphen and **six random characters** that Secrets Manager adds to the name. A policy
naming the secret has to allow for them, `secret:shop/prod/db-*`, and the section on access comes back
to that. The value came back with its stage, `AWSCURRENT`.

## Versions and stages

Writing a new value makes a new version, and the stages move:

```
ana@laptop:~/aws/secrets$ aws secretsmanager put-secret-value --secret-id shop/prod/db --secret-string '{"username":"shop","password":"second-pass"}' --query VersionStages
[
    "AWSCURRENT"
]
ana@laptop:~/aws/secrets$ aws secretsmanager list-secret-version-ids --secret-id shop/prod/db --query 'Versions[].[VersionId,VersionStages[0]]' --output text
5458714e-f3cf-4d2f-b216-aa4da18c6ce6	AWSPREVIOUS
fe2de9d1-a408-4db9-a4a4-ade7b727a7ed	AWSCURRENT
ana@laptop:~/aws/secrets$ aws secretsmanager get-secret-value --secret-id shop/prod/db --version-stage AWSPREVIOUS --query SecretString --output text
{"username":"shop","password":"first-pass"}
```

`AWSCURRENT` is what a read without a stage returns; `AWSPREVIOUS` is the version before it, kept
precisely so that a change can be undone, or a program still holding the old password can be diagnosed.
**A read never names a version**; it names a stage, or nothing, and the stage decides.

Secrets Manager also makes the values themselves:

```
ana@laptop:~/aws/secrets$ aws secretsmanager get-random-password --password-length 24 --exclude-punctuation --query RandomPassword --output text
SHYyfBotp3gzwePXnDTXtuL0
```

A password nobody chose and nobody saw is the best kind, and this one is in the lab only, never typed
anywhere.

## Rotation

**Rotation is a Lambda function that Secrets Manager calls on a schedule, in four steps**, as AWS
documents it: `createSecret` makes a new password and stores it as `AWSPENDING`; `setSecret` sets it in
the database; `testSecret` connects with it; `finishSecret` moves `AWSCURRENT` to it, and the old one
becomes `AWSPREVIOUS`. If any step fails, `AWSCURRENT` has not moved, and the application goes on with
the password that works. For RDS and Aurora there is a managed form with no function to write, where the
database service owns the master password's secret and rotates it itself.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Four steps in a row. 1, createSecret: a new password is stored as AWSPENDING. 2, setSecret: it is set in the database, and the old one still works. 3, testSecret: the function connects with AWSPENDING. 4, finishSecret: AWSCURRENT moves to the new version and the old one becomes AWSPREVIOUS. Below: a failure at any step leaves AWSCURRENT where it was, and the application goes on with the password that works. These are the Lambda function steps as AWS documents them, not run in the lab.\"><defs><marker id=\"rot-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">createSecret</text><text x=\"95.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new password stored</text><text x=\"95.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as AWSPENDING</text><text x=\"95\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><path d=\"M172 98 L194 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rot-ah)\"></path><rect x=\"196\" y=\"50\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"271.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">setSecret</text><text x=\"271.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">set in the database</text><text x=\"271.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">old one still works</text><text x=\"271\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><path d=\"M348 98 L370 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rot-ah)\"></path><rect x=\"372\" y=\"50\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"447.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">testSecret</text><text x=\"447.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">connects with</text><text x=\"447.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">AWSPENDING</text><text x=\"447\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><path d=\"M524 98 L546 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rot-ah)\"></path><rect x=\"548\" y=\"50\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"623.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">finishSecret</text><text x=\"623.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">AWSCURRENT moves</text><text x=\"623.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">old becomes AWSPREVIOUS</text><text x=\"623\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><path d=\"M20 176 L698 176\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"20\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">A failure at any step leaves AWSCURRENT where it was: the application goes on with the password that works.</text><text x=\"20\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Lambda function steps, as AWS documents them; not run in the lab.</text></svg>", "caption": "The stage moves last, and only after a connection with the new password worked."}
```

moto has no Lambda to run, and does something AWS would not:

```
ana@laptop:~/aws/secrets$ aws secretsmanager create-secret --name shop/prod/smtp --secret-string smtp-pass --query Name
"shop/prod/smtp"
ana@laptop:~/aws/secrets$ aws secretsmanager rotate-secret --secret-id shop/prod/smtp --rotation-rules AutomaticallyAfterDays=30 --query Name
"shop/prod/smtp"
ana@laptop:~/aws/secrets$ aws secretsmanager get-secret-value --secret-id shop/prod/smtp --query SecretString

aws: [ERROR]: An error occurred (ResourceNotFoundException) when calling the GetSecretValue operation: Secrets Manager can't find the specified secret value for staging label: AWSCURRENT
```

**AWS refuses a rotation with no function to call**, for a secret that no service manages. moto accepts
it, creates a new version with no value, makes it `AWSCURRENT`, and the next read fails. In the lab that
is a curiosity; it is also a fair picture of a rotation function that moves the stage without setting
the value, which is the one bug a rotation function must not have.

## Deleting, with a window

```
ana@laptop:~/aws/secrets$ aws secretsmanager delete-secret --secret-id shop/prod/smtp --query DeletionDate --output text
2026-11-15T16:27:41.493292-03:00
ana@laptop:~/aws/secrets$ aws secretsmanager get-secret-value --secret-id shop/prod/smtp 2>&1 | tail -1
aws: [ERROR]: An error occurred (InvalidRequestException) when calling the GetSecretValue operation: An error occurred (InvalidRequestException) when calling the GetSecretValue operation: You tried to                 perform the operation on a secret that's currently marked deleted.
ana@laptop:~/aws/secrets$ aws secretsmanager restore-secret --secret-id shop/prod/smtp --query Name
"shop/prod/smtp"
```

A deleted secret is not gone: it waits **30 days** by default, between 7 and 30 as chosen, and can be
restored until then. Reading it fails meanwhile, so an application that still uses a secret somebody
deleted breaks at once, inside the window, when restoring it is one command. `--force-delete-without-recovery`
skips the window, and that flag is not for production.
