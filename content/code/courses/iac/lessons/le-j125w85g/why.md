---
title: Why the laptop stops applying
version: 2
---

The common belief is that a pipeline for Terraform is something a large team needs, and that for
two people `terraform apply` on a laptop is fine as long as the code is in git. Every lesson in this
course so far has applied from Ana's laptop, so it is worth saying what that arrangement hides
before replacing it.

Here is her laptop on an ordinary afternoon, at the end of this lesson, once the pipeline has applied
the network; section 08 ends with the commands that reproduce it. She is trying out a different range
for the subnet and has not committed anything:

```
ana@laptop:~/shop$ git status --short
 M main.tf
ana@laptop:~/shop$ git diff --stat
 main.tf | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@laptop:~/shop$ terraform plan -var-file=prod.tfvars | grep -E "# aws|forces replacement|Plan:"
  # aws_subnet.a must be replaced
      ~ cidr_block                                     = "10.20.1.0/24" -> "10.20.3.0/24" # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
```

**Terraform plans the directory, not the commit.** It reads whatever `.tf` files are on disk and has
no idea what git thinks of them. Had Ana typed `terraform apply` here, the subnet would have been
destroyed and created again from a change that exists in no commit, on no branch, reviewed by
nobody. The next person to plan from `main` would see a plan to put the old range back, and would
have to work out why.

The same transcript makes the second point. The diff is one line. The plan says one subnet is
destroyed and another created, with `# forces replacement` beside the line responsible, which lesson
6 explained. **The diff says what somebody meant; the plan says what will happen**, and a reviewer
who reads only the first is approving the second blind. On a laptop the plan scrolls past in one
terminal and is gone.

A laptop hides three more things:

| on a laptop | in a pipeline |
| --- | --- |
| whichever Terraform version is installed there | one version, written in the workflow |
| credentials that can change production, on every laptop that applies | write credentials in one place, for one job |
| no record of what was applied, from which commit, by whom | a log per run, tied to a commit and an approval |

So this lesson builds one arrangement: **one place applies, and it applies only what was merged
and reviewed**. People still write the change and still decide whether it is wise;
the pipeline does the mechanical part the same way every time, and keeps the plan where a reviewer
can read it.

## How this lesson runs a pipeline with no CI service

A pipeline runs on a service such as GitHub or GitLab, and running one there needs an account, which
this course never asks you for. So the workflow files in this lesson are **illustrative**: written
in full, checked to parse as YAML, and not run for the lesson. What they call is a shell script,
`ci.sh`, and that script is run for real, each time in a fresh clone under `~/ci/` standing in for a
runner. A bare repository, `~/git/shop.git`, stands in for the remote, and copying `tfplan` from one
clone to the next stands in for the artifact a job uploads and the next one downloads. The AWS is
moto, as in every lesson, and the state lives in an S3 bucket like the one lesson 7 created.

## Setting up the repository

Your moto starts empty, so the state bucket has to be made again, as lesson 7 made it. In your home
directory, make it, and the bare repository that plays the remote. The first line tells Git to call
a new repository's first branch `main`, as every transcript here does; without it, Git on Ubuntu
calls it `master` and the pushes below find no `main`:

```sh
git config --global init.defaultBranch main
aws s3api create-bucket --bucket shop-tfstate-123456789012 --create-bucket-configuration LocationConstraint=sa-east-1
aws s3api put-bucket-versioning --bucket shop-tfstate-123456789012 --versioning-configuration Status=Enabled
git init -q --bare git/shop.git
```

Then the working copy, `~/shop`, with that remote as `origin`:

```sh
mkdir -p shop && cd shop
git init -q && git remote add origin ~/git/shop.git
```

Ana's configuration is the shop's network from earlier lessons, with the environment as a variable.
`main.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop", Environment = var.environment }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
  tags        = { Name = "web" }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

`variables.tf`:

```hcl
variable "environment" {
  type        = string
  description = "Which environment this state describes."
}
```

`prod.tfvars`, the value for production:

```hcl
environment = "prod"
```

`backend.tf`, the state in the bucket with lesson 7's lock file beside it:

```hcl
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "shop/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

And `.gitignore`, which keeps the plan files out of Git as well as the state:

```
.terraform/
*.tfstate
*.tfstate.*
tfplan
plan.txt
```

The repository has three more files, `ci.sh` and the two workflow files, and sections 04 and 05 show
them. The first commit, at the end of section 04, takes all of them and the lock file that
`terraform init` writes. `ci.sh scan` runs Trivy, installed in lesson 14, and its section on Trivy
gives the three commands if you skipped it.
