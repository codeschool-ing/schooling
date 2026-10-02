---
title: Four places a password leaks to
version: 1
---

The usual picture of a leaked secret is a file pushed to a public repository by mistake. That
happens, and it is the smallest part of the problem. **A password handed to Terraform is copied, by
Terraform's ordinary work, into places nobody opened on purpose**, and every copy outlives the
moment it was useful. This section follows one password through one configuration and counts the
copies.

Ana's web server needs the shop database's password. The quickest way to get it there is a
variable, and a `user_data` script that writes it into a file the application reads when the
machine boots:

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

variable "db_password" {
  type        = string
  description = "The password the shop's application uses for its database."
}

data "aws_ami" "al2023" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro"
  user_data     = <<-EOT
    #!/bin/sh
    echo "DB_PASSWORD=${var.db_password}" > /etc/shop.env
  EOT
  tags = { Name = "web" }
}
```

The value goes where values usually go, in `terraform.tfvars` beside the configuration, so nobody
has to type it on every run. The password is made up for the lesson, and the AWS is moto, so nothing
here opens a real database:

```hcl
db_password = "s3cr3t-Shop-2026"
```

## Copy one: the git history

Ana's `.gitignore` has the lines lesson 7 gave it, for the state and for `.terraform/`. It says
nothing about `*.tfvars`, and weeks ago a `git add .` took the file along:

```
ana@laptop:~/shop$ git ls-files
.gitignore
.terraform.lock.hcl
main.tf
terraform.tfvars
ana@laptop:~/shop$ git log --oneline
c775f29 web server with its database password
```

When she notices, she stops tracking the file and adds the pattern to `.gitignore`. **That keeps the
file out of the next commit and out of no earlier one**:

```
ana@laptop:~/shop$ git rm -q --cached terraform.tfvars && echo "*.tfvars" >> .gitignore
ana@laptop:~/shop$ git commit -qam "stop tracking terraform.tfvars" && git log --oneline
08183e1 stop tracking terraform.tfvars
c775f29 web server with its database password
ana@laptop:~/shop$ git show HEAD~1:terraform.tfvars
db_password = "s3cr3t-Shop-2026"
```

Every clone made since that first commit has the password, and so does every fork and every backup
of the repository. Rewriting the history can remove the commit from this copy of the repository; it
cannot reach the others. Once a secret has been committed and pushed, the repair that works is to
**rotate it**: change the password at the database, and treat the old one as public.

## Copy two: the plan, wherever it is printed

`user_data` is an ordinary string argument, so the plan prints it, password included:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -A 3 "+ user_data  "
      + user_data                            = <<-EOT
            #!/bin/sh
            echo "DB_PASSWORD=s3cr3t-Shop-2026" > /etc/shop.env
        EOT
```

On a laptop that is a screen. In a pipeline (lesson 15) it is the job's log, kept for weeks and
readable by everybody who can open the pipeline, which is often a longer list than the people who
may read the database.

## Copy three: the saved plan file

A pipeline that plans in one job and applies in another hands the plan over as a file, the `-out`
of lesson 9. That file is a zip archive, and it carries the values the plan was made with:

```
ana@laptop:~/shop$ terraform plan -out=tfplan > /dev/null
ana@laptop:~/shop$ unzip -l tfplan | tail -n +4 | head -n -2
     1771  2026-10-02 07:23   tfplan
     3055  2026-10-02 07:23   tfstate
      145  2026-10-02 07:23   tfstate-prev
      676  2026-10-02 07:23   tfconfig/m-/main.tf
       41  2026-10-02 07:23   tfconfig/modules.json
      281  2026-10-02 07:23   .terraform.lock.hcl
ana@laptop:~/shop$ unzip -p tfplan | grep -a -c s3cr3t-Shop-2026
2
```

`grep` finds the password on two lines, in a file that pipelines keep as an artefact so the apply
job can fetch it.

## Copy four: the state

After an apply, the state records every argument of every resource, `user_data` among them. The
next section finds the password there, and "in-the-state" shows why no setting of Terraform's
changes that.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"On the left, terraform.tfvars, holding the password ana typed. Four arrows fan out from it to the places the password ends up: the git history, the plan printed on a screen and in a CI log, the saved plan file, and the state file in its bucket. Beside each, what sensitive = true does there: it hides the value on the screen, and changes nothing in the other three.\"><defs><marker id=\"lk-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"115\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">terraform.tfvars</text><text x=\"110.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the password ana typed</text><text x=\"615.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">sensitive = true</text><rect x=\"300\" y=\"25\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">git history</text><text x=\"400.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">every clone, every commit</text><path d=\"M202 145 L298 50\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-amber)\"></path><text x=\"615.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">changes nothing</text><rect x=\"300\" y=\"90\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the plan, printed</text><text x=\"400.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a terminal, a CI log</text><path d=\"M202 145 L298 115\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-amber)\"></path><text x=\"615.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">hides it here</text><rect x=\"300\" y=\"155\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a saved plan file</text><text x=\"400.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a CI artefact</text><path d=\"M202 145 L298 180\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-amber)\"></path><text x=\"615.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">changes nothing</text><rect x=\"300\" y=\"220\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the state file</text><text x=\"400.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the bucket, its versions</text><path d=\"M202 145 L298 245\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-amber)\"></path><text x=\"615.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">changes nothing</text></svg>", "caption": "One password, typed once, and the four places it travels to. Marking it sensitive cleans one of them."}
```

The rest of the lesson closes these copies, each tool doing less than its name suggests and more
than nothing. `sensitive` cleans the screen and the log. Ephemeral values and write-only arguments
keep a value out of the plan file and the state. A secret manager keeps it away from Terraform
altogether. And for what still reaches the state, the state itself can be encrypted.

The git copy has one fix, and it comes before all of them: **a secret never goes into a file that
is committed**. `*.tfvars` belongs in `.gitignore` from the first commit, and a value that has to
come from outside arrives as an environment variable such as `TF_VAR_db_password` (lesson 2), set
by the pipeline from its own secret store.
