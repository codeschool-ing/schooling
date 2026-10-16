---
title: When no version is left, import what exists
version: 1
---

Sometimes there is no history to restore from: versioning was off, the bucket itself went, or the
state was never in a bucket. The resources still exist, so **Terraform can be told about them again,
one by one**, by importing each into a fresh state. Since Terraform 1.5 that is written in the
configuration as `import` blocks, reviewed like any change, and Terraform can even write the resource
blocks for you.

The rebuilt configuration keeps its state under a new key, so nothing touches the original:

```hcl
# rebuilt/backend.tf
terraform {
  backend "s3" {
    bucket         = "shop-tfstate-123456789012"
    key            = "shop-rebuilt/terraform.tfstate"
    region         = "sa-east-1"
    encrypt        = true
    use_path_style = true
    use_lockfile   = true
  }
}
```

and names, for each resource, the address it will have and the id it has in AWS:

```hcl
# rebuilt/imports.tf
import {
  to = aws_cloudwatch_log_group.web
  id = "/shop/web"
}

import {
  to = aws_s3_bucket.uploads
  id = "shop-uploads-123456789012"
}
```

Each resource type documents what its import id is: the name for a log group, the name for a bucket,
the ARN for a topic, the URL for a queue. With no `resource` blocks written yet,
`-generate-config-out` asks Terraform to write them from what it finds:

```
ana@laptop:~/aws/tf7/rebuilt$ terraform plan -generate-config-out=generated.tf -no-color | grep -E '^Plan:|generated'
  # (config will be generated)
  # (config will be generated)
Plan: 2 to import, 0 to add, 0 to change, 0 to destroy.
generated configuration format may change in future versions.
Terraform has generated configuration and written it to generated.tf. Please
ana@laptop:~/aws/tf7/rebuilt$ cat generated.tf | grep -v -E "^ *#|= null$" | head -24

resource "aws_cloudwatch_log_group" "web" {
  deletion_protection_enabled = false
  name                        = "/shop/web"
  region                      = "sa-east-1"
  retention_in_days           = 14
  skip_destroy                = false
  tags                        = {}
  tags_all                    = {}
}

resource "aws_s3_bucket" "uploads" {
  bucket              = "shop-uploads-123456789012"
  bucket_namespace    = "global"
  force_destroy       = false
  object_lock_enabled = false
  region              = "sa-east-1"
  tags                = {}
  tags_all            = {}
}
```

`2 to import`, and a file of resource blocks written from the account's own answers. The generated
file sets every argument, including defaults nobody would write by hand (`skip_destroy = false`,
`force_destroy = false`), and it is a draft: **read it, delete what only restates a default, and
compare it with what the team meant**, because it describes the resource as it is, mistakes
included. Then `terraform apply` records the imports, and the state exists again.

Only two of the shop's four resources are imported here. For the SNS topic and the DynamoDB table,
moto returns zeros for attributes AWS fills in, and the generated blocks would fail validation on
values no real topic has; against AWS, the same two `import` blocks work as these do.

## Which way out, and when

| what is left | the way out |
|---|---|
| a version of the state in the bucket | copy it back on top (previous section) |
| a copy from `terraform state pull` | `terraform state push` it |
| nothing, but the resources exist | `import` blocks, resource by resource |

Import is the slowest of the three and the only one that needs no earlier preparation, which is why
the next section is about making sure it is never the only one available.
