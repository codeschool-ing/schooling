---
title: Parameter Store, by path
version: 1
---

A parameter's name is a path, and the path is how the code and the policies find it: everything the
shop's production database needs lives under `/shop/prod/db/`. Work in `~/aws/secrets`
(`mkdir -p ~/aws/secrets && cd ~/aws/secrets`). The host is a plain `String`; the password is a
`SecureString`:

```
ana@laptop:~/aws/secrets$ aws ssm put-parameter --name /shop/prod/db/host --type String --value db.internal --query '[Version,Tier]' --output text
1	Standard
ana@laptop:~/aws/secrets$ aws ssm put-parameter --name /shop/prod/db/password --type SecureString --value first-pass --query '[Version,Tier]' --output text
1	Standard
ana@laptop:~/aws/secrets$ aws ssm get-parameter --name /shop/prod/db/password --query 'Parameter.[Type,Value]' --output text
SecureString	kms:alias/aws/ssm:first-pass
ana@laptop:~/aws/secrets$ aws ssm get-parameter --name /shop/prod/db/password --with-decryption --query Parameter.Value --output text
first-pass
```

Without `--with-decryption` the value comes back encrypted, and with it, in plain text. The third line
is the one to look at: **that is moto's idea of encryption**, the name of the key in front of the
plaintext. On AWS the encrypted value is ciphertext from KMS, unreadable without the key, and asking for
the plain text needs permission to decrypt with that key as well as to read the parameter. The default
key is the account's `aws/ssm`; a key of the team's own is lesson 18.

## By path

The code asks for its whole configuration in one call, by path:

```
ana@laptop:~/aws/secrets$ aws ssm get-parameters-by-path --path /shop/prod --recursive --with-decryption --query 'Parameters[].[Name,Type,Version]' --output text
/shop/prod/db/host	String	1
/shop/prod/db/password	SecureString	1
```

The path is also what a policy grants: a policy allowing the production application to read the
parameters under `/shop/prod` gives it its configuration and nothing of staging's, which lives under
`/shop/staging`. One hierarchy per environment is what makes that policy short.

## Changing a value

A parameter is not overwritten by accident:

```
ana@laptop:~/aws/secrets$ aws ssm put-parameter --name /shop/prod/db/password --type SecureString --value second-pass

aws: [ERROR]: An error occurred (ParameterAlreadyExists) when calling the PutParameter operation: The parameter already exists. To overwrite this value, set the overwrite option in the request to true.
ana@laptop:~/aws/secrets$ aws ssm put-parameter --name /shop/prod/db/password --type SecureString --value second-pass --overwrite --query Version
2
ana@laptop:~/aws/secrets$ aws ssm get-parameter-history --name /shop/prod/db/password --query 'Parameters[].[Version,LastModifiedDate]' --output text
1	2026-10-16T16:27:27.569000-03:00
2	2026-10-16T16:27:30.667000-03:00
```

Every change is a new version, and the history keeps the old ones, so a value changed at the wrong
moment can be read back and restored. The program reading the parameter sees the new version on its
next read, which is a reason to know when the next read is.

## What moto lets through

```
ana@laptop:~/aws/secrets$ aws ssm put-parameter --name /shop/prod/too-big --type String --value "$(printf "%5000s" | tr " " x)" --query Tier
"Standard"
```

**AWS refuses that**: a standard parameter holds at most 4 KB, and 5,000 characters is over it, so the
call fails with a validation error unless the tier is `Advanced`. moto stores it as standard. A value
that large is usually a file that belongs in S3, with its key in the parameter.
