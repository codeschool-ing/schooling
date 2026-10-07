---
title: Working in the lab, lesson after lesson
version: 1
---

**The four `AWS_` variables are the whole trick**, the four that `env` listed at the end of the previous section, and
they are the reason the Terraform files in these lessons look exactly like ones written for a real
account. `AWS_ENDPOINT_URL` sends every call the AWS CLI and the AWS provider make to moto instead of to
Amazon. The key pair is the word `test`, which moto accepts and AWS would refuse, so a slip that
sends a call to the real AWS fails rather than doing something. The region is São Paulo. The account
moto answers as, `123456789012`, is the placeholder AWS itself uses in its documentation, and it
turns up in bucket names in later lessons.

## A fresh lab for every lesson

**Each lesson was recorded on an empty moto and an empty home directory**, and its transcripts only
match if yours starts the same way. moto forgets everything when it stops, so emptying it is
pressing Ctrl+C in its terminal and starting it again. The files are this short script's job; save
it as `fresh-lesson.sh`:

```sh
#!/bin/sh
# ~/fresh-lesson.sh: move aside what the last lesson left in your home
# directory, so the next one starts as empty as it was recorded.
set -e
cd ~
aside=lessons-done/$(date +%Y%m%d-%H%M%S)
mkdir -p "$aside"
for f in *; do
  case $f in
    iac-venv|lessons-done|setup-iac.sh|iac-env.sh|fresh-lesson.sh) ;;
    *) mv "$f" "$aside/" ;;
  esac
done
echo "moved aside: $(ls "$aside" | tr '\n' ' ')"
```

It moves rather than deletes, because the previous lesson's files are yours and you may want to read
them again. So the start of every lesson is the same two steps:

```
ana@laptop:~$ sh ~/fresh-lesson.sh
moved aside: lookup shop shop-tf 
ana@laptop:~$ ls
fresh-lesson.sh  iac-env.sh  iac-venv  lessons-done  setup-iac.sh
```

In a virtual machine there is a second way: take a snapshot right after building the lab, and go back
to it at the start of each lesson. A lesson that needs something an earlier one made says so, and
gives the commands that make it again.

**Three habits the transcripts take for granted:**

- **`terraform init` in every new directory**, before the first `plan`. The lessons show it when it
  says something worth reading, and not every time.
- **Lessons that show `git diff` keep the configuration in Git**, and commit where the prose says Ana
  did. Tell Git your name once, with `git config --global user.name "Your Name"` and the same with
  `user.email`, or the first commit refuses.
- **Ids are different on every run.** AWS invents `vpc-…` and `sg-…` ids, and so does moto, so yours
  will never match the page; everything else should.

## Where your screen differs from the page, and why

The lessons were recorded on a machine with **no access to the internet**, and four things on the
page come from that and not from Terraform:

- **Providers came from a local copy.** They were downloaded from HashiCorp's release site, checked
  against its published checksums, and served from a directory. Where `terraform init` prints
  `(unauthenticated)`, yours prints that the provider is signed by HashiCorp, and the lock file it
  writes has more lines than the page shows. Lesson 2 shows that file.
- **Two transcripts show the Terraform Registry failing to answer**, in lessons 10 and 17. Yours
  will download what they could not.
- **Two scanners print a complaint about the network** in lesson 14, and yours will not.
- **A few tools were built from their source code**, because their downloads are on a site the
  recording machine could not reach. You install the released programs, and each lesson that needs
  one says how.

The other tools arrive in the lesson that first uses them, and each of those lessons opens with how
to install them:

| lesson | tools |
|---|---|
| 11 | Terragrunt |
| 12 | OpenTofu |
| 14 | Checkov, Trivy, tfsec |
| 17 | Node.js and the AWS CDK |
| 18 | Docker and Ansible |
| 19 | Puppet and Salt |
| 20 | Packer and its Docker plugin |

**And when you move to a real account**, the configurations work as they are, with two exceptions.
moto's sample machine images have ids AWS does not have, and a bucket name on AWS has to be unique
across every account in the world; the lessons point both out where they occur. Run
`unset AWS_ENDPOINT_URL`, configure real credentials with `aws configure`, and remember that from
then on every `apply` creates something that costs money until a `destroy` removes it.
