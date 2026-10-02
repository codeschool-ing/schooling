---
title: The lab this course runs on
version: 1
---

Every command in this course was run, and every line of output is what the command printed. **No
cloud account was used for any of it**, and nothing here was billed to anybody. The AWS that
Terraform talks to in these lessons is **moto**, the same emulator the cloud course used for S3: a
Python program that answers the AWS APIs on a port of the laptop, keeps what it is told in memory,
and forgets everything when it stops.

```
ana@laptop:~/shop-tf$ terraform version
Terraform v1.16.4
on linux_amd64
+ provider registry.terraform.io/hashicorp/aws v6.67.0
ana@laptop:~/shop-tf$ aws --version
aws-cli/1.46.1 Python/3.11.15 Linux/6.18.44-fc-v51 botocore/1.43.62
ana@laptop:~/shop-tf$ env | grep ^AWS_ | sort
AWS_ACCESS_KEY_ID=test
AWS_DEFAULT_REGION=sa-east-1
AWS_ENDPOINT_URL=http://localhost:4566
AWS_SECRET_ACCESS_KEY=test
ana@laptop:~/shop-tf$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
```

The four `AWS_` variables are the whole trick, and they are the reason the lessons' Terraform files
look exactly like ones written for a real account. `AWS_ENDPOINT_URL` sends every call the AWS CLI
and the AWS provider make to moto instead of to Amazon; the key pair is the word `test`, which moto
accepts and AWS would refuse; the region is São Paulo. The account moto answers as, `123456789012`,
is the placeholder AWS itself uses in its documentation.

**What moto is, and what it is not.** It is a faithful imitation of the *API*: it checks arguments,
invents ids, remembers what was created and answers questions about it. It runs no machine and
carries no packet. An instance it launches is a record with an id and a state, which is exactly
what Terraform reads back, so every plan, apply, state file and error in these lessons is the one
Terraform would produce. What you will not see is a web server answering on a machine Terraform
created; lessons 18 to 20, which need machines that run, use containers on the laptop instead, and
say so.

**Everything else is the real program.** Terraform, OpenTofu, Terragrunt, Packer, Ansible and the
scanners are the released versions, and each provider is the one HashiCorp publishes. The one
arrangement you would not have at home is where the providers come from: the laptop these lessons
were recorded on could not reach the Terraform Registry, so the providers were downloaded from
HashiCorp's release site, checked against their published checksums, and served from a local
directory. `terraform init` prints the same lines either way; lesson 2 shows the one file where
the difference is visible.

## Doing it on your own computer

You need Terraform, Python 3 and the AWS CLI, on Linux, macOS or Windows with WSL:

1. **Terraform**, from HashiCorp's downloads page or your system's package manager. The lessons
   were recorded on the version printed above, and the few features that need a recent one say
   so where they appear.
2. **moto and the AWS CLI**, in a Python virtual environment: `pip install "moto[server]" awscli`.
3. **Start moto** in a terminal of its own, `moto_server -p 4566`, and leave it running.
4. **In the terminal you work in**, export the four variables shown above. Then add
   `s3_use_path_style = true` to the AWS provider block of any configuration that creates a
   bucket, because the AWS SDK addresses a bucket as `<name>.localhost` and most computers do not
   resolve that name. The lab used a small DNS server for the same job.

**When something does not answer, the endpoint is the first suspect.** With nothing listening at
the address, the CLI says so in one line:

```
ana@laptop:~/shop-tf$ AWS_ENDPOINT_URL=http://localhost:4567 aws sts get-caller-identity

Could not connect to the endpoint URL: "http://localhost:4567/"
```

Check that `moto_server` is still running in its terminal and that the port in `AWS_ENDPOINT_URL`
is the one it printed when it started. A credentials error instead means the variables are not set
in the terminal you are typing in, and the call went somewhere else; with `test` as the key, a real
AWS endpoint refuses it, which is the safety you want.

**And when you move to a real account**, the configurations in these lessons work unchanged: unset
`AWS_ENDPOINT_URL`, configure real credentials, and remember that from then on every `apply`
creates something that costs money until a `destroy` removes it. Lesson 16 is about that cost.
