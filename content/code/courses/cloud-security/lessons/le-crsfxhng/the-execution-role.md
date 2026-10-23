---
title: The execution role is what a flaw in the code inherits
version: 1
---

**A function has no password and no key of its own. It runs as a role, the *execution role*, and
everything the role may do, any code running inside the function may do too.** That includes your
code, every library it imports, and whoever finds a flaw in either. So the question to ask of a
function is not "what does it do?" but "what could it do?", and the answer is the role's policy.

The wrong picture is that serverless is safer because there is no server to break into. There is no
operating system for you to patch, and that part of the claim is true; the `cloud` course's lesson 8
showed how little of the machine is left to you. What is left is the handler, its dependencies, its
configuration and its permissions, and all four are yours. Lesson 3 drew that line for platforms in
general; this lesson walks the four edges of one function.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l13-edges\" aria-label=\"The four edges of one Lambda function, each written in a different place. Above it, who may become it: the trust policy of its execution role, which should name only the Lambda service. On its left, who may call it: its resource-based policy and the authentication type of its function URL. On its right, what it may do: the policies of its execution role, which any code inside the function inherits. Below it, what it carries: its code, its dependencies and its environment variables, all frozen into the deployed package and its configuration.\"><defs><marker id=\"l13-edges-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270.0\" y=\"130.0\" width=\"180.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">daily-export</text><text x=\"360.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the function</text><rect x=\"230.0\" y=\"14.0\" width=\"260.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">who may become it</text><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the role's trust policy</text><rect x=\"16.0\" y=\"136.0\" width=\"200.0\" height=\"68.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"116.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">who may call it</text><text x=\"116.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resource policy, function URL</text><rect x=\"504.0\" y=\"136.0\" width=\"200.0\" height=\"68.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"604.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what it may do</text><text x=\"604.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the execution role's policies</text><rect x=\"210.0\" y=\"272.0\" width=\"300.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"360.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what it carries</text><text x=\"360.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">code, dependencies, environment</text><path d=\"M360.0 70.0 L360.0 128.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-edges-af-ah-paper-dim)\"></path><path d=\"M218.0 170.0 L268.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-edges-af-ah-paper-dim)\"></path><path d=\"M452.0 170.0 L502.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-edges-af-ah-paper-dim)\"></path><path d=\"M360.0 212.0 L360.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "Four documents decide what one function is. A review that reads only the code has read one of them."}
```

## How the role reaches the code

When Lambda starts a copy of a function, it assumes the execution role and puts the temporary
credentials it received into the function's environment, as `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY` and `AWS_SESSION_TOKEN`. The AWS SDK inside the function finds them there
without being told. **Anything that can read the process's environment holds the role for as long as
the session lasts**, which is why a function that leaks its environment, through an error page or a
debugging endpoint left in, leaks its permissions.

Who may become the role is written in its **trust policy**. For an execution role, that is
`lambda.amazonaws.com`, the Lambda service, and nobody else.

## A role that can do everything

The clinic's `daily-export` function writes the day's appointments into `clinic-exports`. When caio
first deployed it, it failed with `AccessDenied`, and he attached `AdministratorAccess` to its role.
The error went away, and so did every limit on the function.

Start moto with its checking on, the way lesson 6 did, so that this section's refusals are real:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

The first three requests are let through unchecked, and they make an administrator called `admin`
with a key. The fourth is refused, which proves the checking is on, and then the terminal moves onto
admin's key:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

To see a role's permissions from the inside, you need its credentials. These two functions put a
set of credentials into the environment for one command: `with_session` the answer of
`assume-role`, and `with_key` the answer of `create-access-key`, which the last section uses:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
with_session() {
  local c=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$c" | jq -r .Credentials.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$c" | jq -r .Credentials.SecretAccessKey) \
  AWS_SESSION_TOKEN=$(echo "$c" | jq -r .Credentials.SessionToken) "$@"
}
```

Two buckets, and a patient file in the one the function has no business reading:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-exports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-exports
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
ana@laptop:~/aws$ printf 'patient,diagnosis\nMaria Souza,asthma\n' | aws s3 cp - s3://clinic-records/patients.csv
```

The role's trust policy names the Lambda service and, **for this section only, your own `admin`
user**, so that you can step into the role and look around. Save it as `export-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com",
        "AWS": "arn:aws:iam::123456789012:user/admin"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Create the role, give it what caio gave it, and become it:

```
ana@laptop:~/aws$ aws iam create-role --role-name export-fn --assume-role-policy-document file://export-trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/export-fn
ana@laptop:~/aws$ aws iam attach-role-policy --role-name export-fn --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ r=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/export-fn --role-session-name daily-export)
ana@laptop:~/aws$ with_session "$r" aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/export-fn/daily-export
ana@laptop:~/aws$ with_session "$r" aws s3 cp s3://clinic-records/patients.csv -
patient,diagnosis
Maria Souza,asthma
ana@laptop:~/aws$ with_session "$r" aws iam list-users --query "Users[].UserName" --output text
admin
```

**The function writes exports and nothing else, and its role just read a patient file and listed the
account's users.** Neither request was refused, because nothing in the role refuses anything. A flaw
in the export code, or in any library it loads, would have had the same reach.

## One action on one place

The function needs one action, `s3:PutObject`, on one place, the objects of `clinic-exports`. Save
that as `write-exports.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::clinic-exports/*"
    }
  ]
}
```

Take `AdministratorAccess` away, put the narrow policy in its place, and ask the same three questions
with a new session:

```
ana@laptop:~/aws$ aws iam detach-role-policy --role-name export-fn --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ aws iam put-role-policy --role-name export-fn --policy-name write-exports --policy-document file://write-exports.json
ana@laptop:~/aws$ r=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/export-fn --role-session-name daily-export)
ana@laptop:~/aws$ printf 'date,time\n2026-10-23,09:00\n' | with_session "$r" aws s3 cp - s3://clinic-exports/2026-10-23.csv
ana@laptop:~/aws$ with_session "$r" aws s3 cp s3://clinic-records/patients.csv -
download failed: s3://clinic-records/patients.csv to - An error occurred (403) when calling the HeadObject operation: Forbidden
ana@laptop:~/aws$ with_session "$r" aws iam list-users --query "Users[].UserName" --output text

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListUsers operation: User: arn:aws:sts::123456789012:assumed-role/export-fn/daily-export is not authorized to perform: iam:ListUsers
```

The upload printed nothing, which for `aws s3 cp` from standard input means it worked. The two
requests that had no business succeeding are refused: S3 answers `403 Forbidden` to the read, and IAM
names the action the role lacks. **That last transcript is the proof, not the policy file**: a
policy is what you meant, and a refused request is what the account does.

The test entry in the trust policy has to go, or `admin` stays a second way into the function's
permissions. Save the trust policy as it should be, `lambda-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam update-assume-role-policy --role-name export-fn --policy-document file://lambda-trust.json
ana@laptop:~/aws$ aws iam get-role --role-name export-fn --query "Role.AssumeRolePolicyDocument.Statement[].Principal"
[
    {
        "Service": "lambda.amazonaws.com"
    }
]
```

**Do not try `assume-role` again now.** moto 5.2.3 judges trust policies when its checking is on,
and a statement naming only a service makes it fail with an internal error, HTTP 500, instead of
answering. AWS would answer `AccessDenied`, since `admin` is no longer a principal the role trusts.
That refusal was not run here.

## Finding out what a function needs

caio's mistake has a respectable cause: nobody knew which actions the function used, and the error
message named one at a time. Three ways to find out, all from AWS's documentation and **not run
here**:

- **read the code**: every call to the SDK is an action, `put_object` is `s3:PutObject`, and a
  function small enough to be a function has few of them;
- **IAM Access Analyzer's policy generation** reads a role's activity in CloudTrail over a period you
  choose and drafts a policy holding only the actions it saw;
- **last accessed information** on the role, `aws iam generate-service-last-accessed-details`, lists
  the services the role used and when, which shows what an over-wide policy can lose.

**One function, one role.** A role shared by ten functions has the union of their needs, and every
one of them carries the other nine's permissions.
