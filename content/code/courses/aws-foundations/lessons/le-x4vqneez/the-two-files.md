---
title: Two files, profiles, and the order settings are read in
version: 1
---

**The AWS command line reads its settings from three places, and the nearest one wins: an option
on the command, then an environment variable, then a profile in the files under `~/.aws`.** A
profile is a named bundle of settings, so one laptop can talk to six accounts without editing
anything between commands. Every lesson so far has lived on the middle layer, `env.sh`'s
variables; this lesson opens the bottom one and measures how the three stack.

The wrong picture is that `~/.aws/credentials` is where the command line is configured. **It is one
of two files**, and the smaller one. Keys go in `credentials`; everything else, from the region to
the role to assume, goes in `config`. Splitting them lets the configuration be shared, copied into a
repository or pasted into a ticket, while the secrets stay in a file nobody copies.

## Writing a profile with `aws configure set`

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS. `aws configure set` writes one setting into the right file, which avoids a typo in
the format. Make a profile called `lab` with moto's placeholder keys, a region and an output
format. If lesson 11's `~/.aws/config` is still there, the new lines are added to it:

```
ana@laptop:~/aws$ aws configure set aws_access_key_id test --profile lab
ana@laptop:~/aws$ aws configure set aws_secret_access_key test --profile lab
ana@laptop:~/aws$ aws configure set region us-east-1 --profile lab
ana@laptop:~/aws$ aws configure set output json --profile lab
ana@laptop:~/aws$ cat ~/.aws/credentials
[lab]
aws_access_key_id = test
aws_secret_access_key = test
ana@laptop:~/aws$ cat ~/.aws/config
[profile lab]
region = us-east-1
output = json
```

**The same profile has a different header in each file.** `credentials` calls it `[lab]`;
`config` calls it `[profile lab]`. The one exception is the default profile, which is `[default]`
in both, and which is used when nothing names another. Lesson 11's file showed a third kind of
section, `[sso-session …]`, which belongs to no profile and is shared by those that name it.

Never put a real key in either file by hand, and never paste one from a message; the keys here are
moto's placeholders. `aws configure get` reads a setting back, and `list-profiles` names every
profile both files define:

```
ana@laptop:~/aws$ aws configure get region --profile lab
us-east-1
ana@laptop:~/aws$ aws configure list-profiles
lab
```

## The order, measured with the region

The profile says `us-east-1`. Ask it for the first zone of its region:

```
ana@laptop:~/aws$ aws ec2 describe-availability-zones --profile lab --query "AvailabilityZones[0].ZoneName" --output text
sa-east-1a
ana@laptop:~/aws$ env -u AWS_DEFAULT_REGION aws ec2 describe-availability-zones --profile lab --query "AvailabilityZones[0].ZoneName" --output text
us-east-1a
ana@laptop:~/aws$ aws ec2 describe-availability-zones --profile lab --region us-west-2 --query "AvailabilityZones[0].ZoneName" --output text
us-west-2a
```

**The first answer is São Paulo, although the profile says Virginia**, because `env.sh` exports
`AWS_DEFAULT_REGION=sa-east-1` and an environment variable beats a file. Taking the variable away
for one command with `env -u` lets the profile's region through. And an option on the command line,
`--region us-west-2`, beats both. Three commands, three layers:

| layer | the region came from | answer |
|---|---|---|
| command line | `--region us-west-2` | `us-west-2a` |
| environment | `AWS_DEFAULT_REGION` in `env.sh` | `sa-east-1a` |
| profile | `region = us-east-1` in `~/.aws/config` | `us-east-1a` |

The region has two variables, and `AWS_REGION` wins over `AWS_DEFAULT_REGION` when both are set;
`aws configure list` names both in its `LOCATION` column. The same three layers hold for the
output format (`--output`, `AWS_DEFAULT_OUTPUT`, `output =`), the endpoint (`--endpoint-url`,
`AWS_ENDPOINT_URL`, `endpoint_url =`) and the profile itself (`--profile`, `AWS_PROFILE`).

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l25-layers\" aria-label=\"The three places the AWS command line reads a setting from, nearest first. First the command itself: options such as --region, --profile and --output. Then the environment: AWS_REGION, AWS_DEFAULT_REGION, AWS_PROFILE and the key variables. Last the two files, ~/.aws/config and ~/.aws/credentials. The region measured in the lesson came from each layer in turn: us-west-2a with the option, sa-east-1a from env.sh, us-east-1a from the profile. For credentials, --profile takes the environment's keys out of the way, and AWS_PROFILE does not.\"><defs><marker id=\"l25-layers-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"610.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the region, measured</text><rect x=\"80.0\" y=\"40.0\" width=\"440.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1  the command</text><text x=\"100.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--region  --profile  --output</text><rect x=\"560.0\" y=\"52.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-west-2a</text><path d=\"M522.0 70.0 L558.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"80.0\" y=\"120.0\" width=\"440.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2  the environment</text><text x=\"100.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AWS_DEFAULT_REGION  AWS_PROFILE  AWS_ACCESS_KEY_ID</text><rect x=\"560.0\" y=\"132.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1a</text><path d=\"M522.0 150.0 L558.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"80.0\" y=\"200.0\" width=\"440.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"218.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3  the files</text><text x=\"100.0\" y=\"242.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">~/.aws/config  ~/.aws/credentials</text><rect x=\"560.0\" y=\"212.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1a</text><path d=\"M522.0 230.0 L558.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M40.0 44.0 L40.0 256.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l25-layers-af-ah-phosphor)\"></path><text x=\"40.0\" y=\"281.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">first found</text><text x=\"40.0\" y=\"294.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">wins</text><text x=\"360.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">credentials: --profile skips the environment's keys; AWS_PROFILE does not</text></svg>", "caption": "Nearest wins: the command, then the environment, then the files, with one exception for keys."}
```

**Credentials follow the same rule with one exception**, and the exception is the reason this lab
works at all. The next section measures it.
