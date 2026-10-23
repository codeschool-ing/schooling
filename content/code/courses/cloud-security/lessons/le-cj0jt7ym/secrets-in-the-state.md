---
title: The state file remembers what the screen hides
version: 1
---

**Terraform keeps a state file recording every attribute of every resource it manages, and an
attribute that is a password is recorded like any other: in clear text.** Marking a variable
`sensitive` hides it from the screen and from nothing else. Whoever can read the state can read the
secret, and the state usually sits somewhere more people can reach than the secret itself.

## The database password

The booking application's database password belongs in Secrets Manager, and caio creates the secret
with Terraform. In a new directory:

```sh
mkdir -p ~/aws/clinic-db && cd ~/aws/clinic-db
```

Save this as `main.tf`:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.67.0" }
  }
}

provider "aws" {
  region = "sa-east-1"
}

variable "db_password" {
  type      = string
  sensitive = true
}

resource "aws_secretsmanager_secret" "db" {
  name = "clinic/db"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = var.db_password
}
```

The password comes in through an environment variable, so it is in no file of the repository.
Terraform reads any variable called `TF_VAR_` followed by a variable's name. Run `terraform init`,
then:

```sh
export TF_VAR_db_password='Clinic-2019-Booking!'
```

```
ana@laptop:~/aws/clinic-db$ terraform apply -auto-approve -no-color | tail -1
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
ana@laptop:~/aws/clinic-db$ terraform state show -no-color aws_secretsmanager_secret_version.db | grep secret_string
    secret_string    = (sensitive value)
    secret_string_wo = (write-only attribute)
ana@laptop:~/aws/clinic-db$ grep -o '"secret_string": "[^"]*"' terraform.tfstate
"secret_string": "Clinic-2019-Booking!"
```

`terraform state show` says `(sensitive value)`, which is what `sensitive = true` buys. The file it
read from says the password outright. **Everything careful about how the password arrived, through
an environment variable and nowhere on disk, was undone by the state file**, which now lives on caio's
laptop and, in a team, in a shared backend.

## Keeping it out of the state

Recent versions of Terraform, this lesson's 1.16.4 among them, can pass a value to a resource
**without recording it**. The resource offers a *write-only* argument, `secret_string_wo`, and a
version number beside it that says when the value changed. The variable becomes `ephemeral`, which
means Terraform may use it during a run and must never store it. Replace `main.tf` with this:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.67.0" }
  }
}

provider "aws" {
  region = "sa-east-1"
}

variable "db_password" {
  type      = string
  sensitive = true
  ephemeral = true
}

resource "aws_secretsmanager_secret" "db" {
  name = "clinic/db"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id                = aws_secretsmanager_secret.db.id
  secret_string_wo         = var.db_password
  secret_string_wo_version = 1
}
```

```
ana@laptop:~/aws/clinic-db$ terraform apply -auto-approve -no-color | grep -E 'will be|Apply complete'
  # aws_secretsmanager_secret_version.db will be updated in-place
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
ana@laptop:~/aws/clinic-db$ grep -c 'Clinic-2019-Booking' terraform.tfstate terraform.tfstate.backup
terraform.tfstate:0
terraform.tfstate.backup:1
ana@laptop:~/aws/clinic-db$ aws secretsmanager get-secret-value --secret-id clinic/db --query SecretString --output text
Clinic-2019-Booking!
```

The state no longer holds the password, and the secret still does, which is the one place it should
be. Terraform will not notice a new password by comparing values it never kept: when the password
changes, `secret_string_wo_version` goes up by one, and that is what tells it to write again.

**And the backup still has the old one.** `terraform.tfstate.backup` is the state as it was before the
last apply, and Terraform keeps it beside the state without being asked. A shared backend keeps its
own history in the same way, often every version of the state ever written. So the fix for a
password that has been in a state file is the same as for a key that has been in a repository: **this
password has to change**, and only then does it matter where the old copies are.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l12-three-places\" aria-label=\"Three places a value passes through when infrastructure is written as code, and what each one does with it. The repository: the current files can be clean while the history keeps every line ever committed, including a removed key. The plan on the screen: a sensitive value is shown as hidden, and a value that depends on something not yet created is shown as known after apply, so a reviewer sees neither. The state file: every attribute in clear text, including a password the screen hid, and a backup beside it holding the version before the last apply.\"><rect x=\"20.0\" y=\"20.0\" width=\"200.0\" height=\"250.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the repository</text><rect x=\"32.0\" y=\"66.0\" width=\"176.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">today's files</text><text x=\"120.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">clean</text><rect x=\"32.0\" y=\"142.0\" width=\"176.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the history</text><text x=\"120.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">access_key = &quot;AKIA…&quot;</text><text x=\"120.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">every clone keeps the history</text><rect x=\"260.0\" y=\"20.0\" width=\"200.0\" height=\"250.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the plan on the screen</text><rect x=\"272.0\" y=\"66.0\" width=\"176.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">secret_string</text><text x=\"360.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">(sensitive value)</text><rect x=\"272.0\" y=\"142.0\" width=\"176.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">policy</text><text x=\"360.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">(known after apply)</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the reviewer sees neither</text><rect x=\"500.0\" y=\"20.0\" width=\"200.0\" height=\"250.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the state file</text><rect x=\"512.0\" y=\"66.0\" width=\"176.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">terraform.tfstate</text><text x=\"600.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&quot;Clinic-2019-…&quot;</text><rect x=\"512.0\" y=\"142.0\" width=\"176.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">terraform.tfstate.backup</text><text x=\"600.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the old value</text><text x=\"600.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">whoever reads it reads the secret</text></svg>", "caption": "A secret marked sensitive is hidden from the screen and kept everywhere else. Each of the three needs its own answer: rotate what reached the history, make plan values knowable, keep secrets out of the state."}
```

## Where the state lives

Two decisions follow, and the `iac` course's lessons 7 and 12 take both further:

- **The state is a secret, so store it like one.** In a team it lives in a backend such as an S3
  bucket, encrypted, with versioning, readable only by the people and the pipeline that run
  Terraform. A state bucket readable by the whole engineering team makes every secret in it readable
  by the whole team.
- **Prefer arguments that keep secrets out of it.** Write-only arguments where a resource offers one;
  otherwise let the service generate the secret itself, so that it never passes through Terraform at
  all.

None of the backend half was run here: these lessons keep the state on the laptop.
