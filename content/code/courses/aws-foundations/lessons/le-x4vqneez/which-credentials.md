---
title: Which credentials win, roles in a profile, and CloudShell
version: 1
---

**For credentials, the environment beats `AWS_PROFILE`, and `--profile` beats the environment.**
That asymmetry is the most useful single fact about the command line in this course, because
`env.sh` exports moto's test keys into every terminal. Lesson 10's chain explains it: the `env`
provider comes first, and naming a profile with `--profile` removes that provider from the chain
for the command; naming it with a variable does not.

## Measured three ways

With `env.sh` read, name the profile with the variable:

```
ana@laptop:~/aws$ AWS_PROFILE=lab aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : lab                      : env              : ['AWS_PROFILE', 'AWS_DEFAULT_PROFILE']
access_key : ****************test     : env              : 
secret_key : ****************test     : env              : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

**The profile is `lab`, and the keys are not its.** The `TYPE` column says `env`: the test keys
`env.sh` exported won, and the profile contributed nothing but its name. Name it with the option
instead:

```
ana@laptop:~/aws$ aws configure list --profile lab
NAME       : VALUE                    : TYPE             : LOCATION
profile    : lab                      : manual           : --profile
access_key : ****************test     : shared-credentials-file : 
secret_key : ****************test     : shared-credentials-file : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

**Now the keys come from `shared-credentials-file`**, the profile's own file. The two runs use the
same keys only because `lab` holds `test` and `test` too; with a real profile the first would sign
as one identity and the second as another, and nothing on the screen but the `TYPE` column would
say so.

The third way keeps `AWS_PROFILE` and takes the environment's keys away for one command. That is
the way to use a profile in this course **without changing `env.sh`**, which every other lesson
relies on:

```
ana@laptop:~/aws$ env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY AWS_PROFILE=lab aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : lab                      : env              : ['AWS_PROFILE', 'AWS_DEFAULT_PROFILE']
access_key : ****************test     : shared-credentials-file : 
secret_key : ****************test     : shared-credentials-file : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

A terminal that never read `env.sh` behaves the same, with the difference that it also lacks the
endpoint and would send its requests to AWS. **In the lab, prefer `--profile`**; outside it, a
profile picked with `AWS_PROFILE` in a shell with no keys exported is the everyday arrangement.

## A role in a profile: one account to another

The shop's people work in several accounts, and lesson 9 assumed roles across them by hand. A
profile can do it on every command. Make the organisation and the staging account, then a profile
whose credentials are a role in it:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.Id --output text
o-5sixxus3on
ana@laptop:~/aws$ aws organizations create-account --account-name shop-staging --email aws+shop-staging@example.com --query CreateAccountStatus.[State,AccountId] --output text
SUCCEEDED	986198030938
ana@laptop:~/aws$ STAGING=$(aws organizations list-accounts --query "Accounts[?Name==\`shop-staging\`].Id" --output text)
```

```
ana@laptop:~/aws$ aws configure set role_arn arn:aws:iam::$STAGING:role/OrganizationAccountAccessRole --profile staging
ana@laptop:~/aws$ aws configure set source_profile lab --profile staging
ana@laptop:~/aws$ aws configure set role_session_name ana --profile staging
ana@laptop:~/aws$ aws configure set output table --profile staging
ana@laptop:~/aws$ aws sts get-caller-identity --profile staging
-----------------------------------------------------------------------------------------
|                                   GetCallerIdentity                                   |
+---------+-----------------------------------------------------------------------------+
|  Account|  986198030938                                                               |
|  Arn    |  arn:aws:sts::986198030938:assumed-role/OrganizationAccountAccessRole/ana   |
|  UserId |  AROA6LHP3XJNFPMJSJBNZ:ana                                                  |
+---------+-----------------------------------------------------------------------------+
```

**`role_arn` says which role to assume and `source_profile` says with which credentials.** The
command line called `sts:AssumeRole` as `lab`, got temporary credentials in `shop-staging`, and
signed `get-caller-identity` with them; `role_session_name` fixed the session name that it would
otherwise take from the clock. The output is a table because the profile asked for one. The role is
the one lesson 3 showed moto creating in every new account, with no policy attached, which moto
does not check here anyway.

The same command with the profile and without it shows two accounts, each with its own default
network:

```
ana@laptop:~/aws$ aws ec2 describe-vpcs --profile staging --query "Vpcs[].[OwnerId,CidrBlock]" --output text
986198030938	172.31.0.0/16
ana@laptop:~/aws$ aws ec2 describe-vpcs --query "Vpcs[].[OwnerId,CidrBlock]" --output text
123456789012	172.31.0.0/16
ana@laptop:~/aws$ ls ~/.aws/cli/cache/
83009e16ca18f53b349e21816a716fddcb4b28d3.json
session.db
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l25-role-profile\" aria-label=\"What one command with --profile staging does. The profile staging names a role_arn in shop-staging and a source_profile, lab. The keys of lab sign an sts:AssumeRole call. STS returns temporary credentials for OrganizationAccountAccessRole in shop-staging, which the command line keeps in ~/.aws/cli/cache and signs the command with. The next command reuses the cache until the credentials expire.\"><defs><marker id=\"l25-role-profile-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"60.0\" width=\"160.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">[profile staging]</text><text x=\"90.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">role_arn, source_profile</text><rect x=\"190.0\" y=\"60.0\" width=\"160.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">[lab]</text><text x=\"270.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its keys sign</text><rect x=\"370.0\" y=\"60.0\" width=\"160.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sts:AssumeRole</text><text x=\"450.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in shop-staging</text><rect x=\"550.0\" y=\"60.0\" width=\"160.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">~/.aws/cli/cache</text><text x=\"630.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kept until expiry</text><path d=\"M172.0 92.0 L188.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25-role-profile-af-ah-phosphor)\"></path><path d=\"M352.0 92.0 L368.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25-role-profile-af-ah-phosphor)\"></path><path d=\"M532.0 92.0 L548.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25-role-profile-af-ah-phosphor)\"></path><path d=\"M630.0 126.0 L630.0 170.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25-role-profile-af-ah-phosphor)\"></path><rect x=\"430.0\" y=\"172.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws ec2 describe-vpcs --profile staging</text><text x=\"220.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">signed as the role, in the other account</text><text x=\"90.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">one command</text></svg>", "caption": "A profile with role_arn assumes the role on the first command and reuses it until it expires."}
```

The `.json` files in `~/.aws/cli/cache/` hold the role's temporary credentials, kept until they
expire so that the next command does not assume the role again. **Deleting them is safe**: the
next command just assumes the role once more. Two related settings sit beside `role_arn`. `credential_source`
replaces `source_profile` on a machine that already has credentials from its environment or its
metadata service, as in lesson 10; `mfa_serial` makes the command line ask for a code before
assuming a role whose trust policy demands MFA.

## `credential_process`, a program that hands over credentials

**`credential_process` names a program whose output is the credentials**, as JSON on its standard
output. It is how a password manager or a company's vault plugs into the command line without the
secret ever being written to `~/.aws`. This one prints moto's placeholders, and nothing else:

```sh
cat > ~/aws/lab-creds.sh <<'EOF'
#!/bin/sh
# Prints credentials the way credential_process expects them. These are moto's
# placeholders; a real one would ask a vault or a password manager.
printf '{"Version": 1, "AccessKeyId": "test", "SecretAccessKey": "test"}\n'
EOF
```

```
ana@laptop:~/aws$ sh ~/aws/lab-creds.sh
{"Version": 1, "AccessKeyId": "test", "SecretAccessKey": "test"}
ana@laptop:~/aws$ aws configure set credential_process "sh ~/aws/lab-creds.sh" --profile from-process
ana@laptop:~/aws$ aws sts get-caller-identity --profile from-process

aws: [ERROR]: Error when retrieving credentials from custom-process: sh: 0: cannot open ~/aws/lab-creds.sh: No such file
```

**The command is not run by a shell**, so the `~` reached `sh` as it was written and named no file.
Wrapping the line in `sh -c` hands it to a shell, which does expand it:

```
ana@laptop:~/aws$ aws configure set credential_process "sh -c \"sh ~/aws/lab-creds.sh\"" --profile from-process
ana@laptop:~/aws$ tail -2 ~/.aws/config
[profile from-process]
credential_process = sh -c "sh ~/aws/lab-creds.sh"
ana@laptop:~/aws$ aws configure list --profile from-process
NAME       : VALUE                    : TYPE             : LOCATION
profile    : from-process             : manual           : --profile
access_key : ****************test     : custom-process   : 
secret_key : ****************test     : custom-process   : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

`custom-process` is the provider of lesson 10's chain that answered. A real program may also return
`SessionToken` and `Expiration`, and the command line asks it again once that time has passed.

Lesson 11 used the fourth kind, `sso_session`, and with these four the list is complete: **keys in
a file, a role assumed from another profile, a program, or a sign-in through Identity Center.**

## CloudShell, which needs no profile at all

**AWS CloudShell is a shell in the browser, opened from the console, with the command line already
signed in as whoever is using the console.** It runs Amazon Linux in the region the console is set
to, with the AWS CLI, Python and Node.js installed, and keeps 1 GB of the home directory per region
between sessions. There is no key to configure, because the credentials are those of the console
session, and they end when it does.

It suits the moments this lesson's profiles are too much for: one command in an account somebody
signed in to through Identity Center, from a computer with nothing installed. **It was not run
here**: it needs an AWS account and a browser, and AWS CLI 2.37.4 has no `cloudshell` command to
reach it from a terminal. This description follows AWS's documentation.
