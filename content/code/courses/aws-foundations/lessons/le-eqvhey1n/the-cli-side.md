---
title: The command line signed in through Identity Center
version: 1
---

**On the command line, Identity Center is a profile that names a portal, an account and a
permission set, and a sign-in that fills a cache.** No key goes into any file. `aws sso login` opens
the browser once, the person signs in at the identity provider, and for the hours that follow every
command with that profile gets fresh role credentials on its own.

The wrong picture is that the command line needs the access portal's copied credentials pasted into
`~/.aws/credentials`. The portal offers exactly that, and it is the right thing for a one-off. For
anything daily it means a key-shaped secret in a file that outlives the session it came from. **The
profile does the same job without the file.**

## The profile, as a file

`aws configure sso` asks five questions and writes the answers into `~/.aws/config`. The answers
are short enough to write by hand, and the file is clearer than the questions. Lesson 25 covers the
file in full. Save this as `~/.aws/config`, adding it to the end if the file already exists, with
your own `shop-prod` id in place of this one:

```ini
[sso-session shop]
sso_start_url = https://my-sso-portal.awsapps.com/start
sso_region = sa-east-1
sso_registration_scopes = sso:account:access

[profile prod-readonly]
sso_session = shop
sso_account_id = 834307267662
sso_role_name = ReadOnly
region = sa-east-1
output = json
```

**Two kinds of section, for two different things.** `[sso-session shop]` is the sign-in: the
portal's address, the region Identity Center lives in, and the scope the command line asks for. The
address here is the placeholder AWS's documentation uses. A real one is in Identity Center's
settings. `[profile prod-readonly]` is one destination: an account, a permission set by name, and
the region and output format for commands run with it. **One session serves any number of
profiles.** A single sign-in in the morning opens `prod-readonly`, a `staging-developer` beside it,
and every other pair the person is assigned.

```
ana@laptop:~/aws$ aws configure list-profiles
prod-readonly
```

## What happens before anybody has signed in

Ask who the profile is:

```
ana@laptop:~/aws$ aws sts get-caller-identity --profile prod-readonly

aws: [ERROR]: Error loading SSO Token: Token for shop does not exist
```

**The command line looked for a cached sign-in for the session `shop`, found none, and stopped.** It
did not fall back to the test keys `env.sh` exports, because a profile named with `--profile` takes
the environment's keys out of the chain. Lesson 25 measures that rule and its exception. The cache
it looked in is `~/.aws/sso/cache/`, and one command fills it.

## Signing in, which was not run

**`aws sso login --profile prod-readonly` needs a real Identity Center and a browser, and neither
exists in the lab.** Pointed at moto, which has no sign-in service, it fails at its first request:

```
ana@laptop:~/aws$ aws sso login --profile prod-readonly --no-browser 2>&1 | grep -o "An error occurred ([0-9]*) when calling the [A-Za-z]* operation"
An error occurred (500) when calling the RegisterClient operation
```

Against AWS, AWS's documentation describes the rest, and this course describes it from there.
`RegisterClient` registers the command line with Identity Center's sign-in service. The command
then prints an address and a code, and opens the browser at it unless told `--no-browser`. The
person checks that the code matches, signs in at the identity provider with their second factor,
and allows the access. The command line receives a token, writes it into `~/.aws/sso/cache/`, and
says it signed in.

From then on, **every command with the profile trades that token for role credentials**. The `sso`
provider of lesson 10's chain asks the portal for the credentials of `ReadOnly` in `834307267662`.
It gets temporary ones for the `AWSReservedSSO_ReadOnly_…` role, and refreshes them when they run
out. Two clocks bound it. The **permission set's session duration**, four hours for `ReadOnly`,
limits each set of role credentials. The **Identity Center session**, eight hours by default and set
by the administrator, limits the sign-in itself. When it ends, the next command says the token has
expired and the person runs `aws sso login` again. `aws sso logout` ends it on purpose, and removes
the cached token.

## What this buys, in one comparison

| | an IAM user's key in `~/.aws/credentials` | an `sso-session` profile |
|---|---|---|
| what is on the disk | the secret itself, valid until deleted | a token, valid for the session |
| second factor | per user, per account, if somebody set it up | at the identity provider, every sign-in |
| when the person leaves | a key per account to find and delete | disabled once, at the provider |
| what CloudTrail names | the IAM user | the role, with the person's name as the session |

**For a person at a keyboard there is no row where the key wins.** It is what lesson 12 starts from:
the key is the last resort, kept for the programs that have no browser and no role to wear.
