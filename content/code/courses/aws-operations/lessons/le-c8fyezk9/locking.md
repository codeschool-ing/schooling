---
title: The lock, the table, and the file that replaced it
version: 1
---

Two applies writing one state at the same moment lose one of the two writes, and `iac` lesson 7
showed the second apply refused by a lock. On AWS the lock lived for years in a **DynamoDB table**:
before writing, Terraform puts an item with the state's path as its key, on condition that no such
item exists, and deletes it afterwards. Since Terraform 1.10 the backend can lock with **a file in the
same bucket** instead, using S3's conditional writes, and the table is now deprecated. A team on AWS
meets both, and has to move from one to the other without a moment with no lock at all.

## The table

The backend that names the table:

```hcl
# dynamodb/backend.tf
terraform {
  backend "s3" {
    bucket         = "shop-tfstate-123456789012"
    key            = "shop/terraform.tfstate"
    region         = "sa-east-1"
    encrypt        = true
    use_path_style = true
    dynamodb_table = "shop-tflocks"
  }
}
```

```
ana@laptop:~/aws/tf/shop$ terraform init -input=false -no-color | sed -n '/Warning/,/instead/p'
Warning: Deprecated Parameter

The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile"
instead.
```

Deprecated, and still working. With an apply waiting at its prompt in another terminal, the lock is
an item in the table:

```
ana@laptop:~/aws/tf/shop$ aws dynamodb scan --table-name shop-tflocks --query 'Items[].Info.S' --output text | jq .
{
  "ID": "7ff338c3-b61a-0cb9-3bba-2898e38b6fc6",
  "Operation": "OperationTypeApply",
  "Info": "",
  "Who": "root@vm",
  "Version": "1.16.4",
  "Created": "2026-10-16T16:14:36.695112232Z",
  "Path": "shop-tfstate-123456789012/shop/terraform.tfstate"
}
```

`Who` names the user and machine that took the lock (here, the machine the transcripts were recorded
on, as `root@vm`), and `Created` says since when. A second plan, from anywhere, is refused with the
same record:

```
ana@laptop:~/aws/tf/shop$ terraform plan -lock-timeout=0s -no-color 2>&1 | sed -n '/Error: Error acquiring/,$p'
Error: Error acquiring the state lock

Error message: operation error DynamoDB: PutItem, https response error
StatusCode: 400, RequestID:
dNydrC0WGKgVI72hPGxZltPQeZMFf2sZjBaX8ZI7YImnJNLiI878,
ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        7ff338c3-b61a-0cb9-3bba-2898e38b6fc6
  Path:      shop-tfstate-123456789012/shop/terraform.tfstate
  Operation: OperationTypeApply
  Who:       root@vm
  Version:   1.16.4
  Created:   2026-10-16 16:14:36.695112232 +0000 UTC
  Info:      


Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.
```

`ConditionalCheckFailedException` is DynamoDB saying the item already exists, which is the whole
mechanism: **a lock is a write that only succeeds when nobody else's write is there**.

## Moving to the lock file

The migration is two releases, so there is no moment with nobody locking. First, both:

```hcl
# both/backend.tf
terraform {
  backend "s3" {
    bucket         = "shop-tfstate-123456789012"
    key            = "shop/terraform.tfstate"
    region         = "sa-east-1"
    encrypt        = true
    use_path_style = true
    use_lockfile   = true
    dynamodb_table = "shop-tflocks"
  }
}
```

```
ana@laptop:~/aws/tf/shop$ terraform init -input=false -reconfigure -no-color | grep -E 'Warning|Successfully|deprecated'
Successfully configured the backend "s3"! Terraform will automatically
Warning: Deprecated Parameter
The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile"
```

With both set, Terraform takes both locks, so a colleague still on the old configuration and one on
the new one exclude each other. Hold the lock again and look in the bucket and in the table:

```
ana@laptop:~/aws/tf/shop$ aws s3 ls s3://shop-tfstate-123456789012/shop/
2026-10-16 13:14:33       2827 terraform.tfstate
2026-10-16 13:14:42        224 terraform.tfstate.tflock
ana@laptop:~/aws/tf/shop$ aws dynamodb scan --table-name shop-tflocks --query 'Items[].LockID.S' --output text
shop-tfstate-123456789012/shop/terraform.tfstate	shop-tfstate-123456789012/shop/terraform.tfstate-md5
```

The state has a neighbour, `terraform.tfstate.tflock`, and the table holds the lock item as well.
Its second item, ending in `-md5`, is not a lock: the DynamoDB backend keeps there the checksum of the
last state it wrote, so that a read returning an older copy of the object is noticed rather than
used. When the apply ends, the file goes:

```
ana@laptop:~/aws/tf/shop$ aws s3 ls s3://shop-tfstate-123456789012/shop/
2026-10-16 13:14:33       2827 terraform.tfstate
```

Once everybody's configuration has both, the second release removes the table:

```hcl
# lockfile/backend.tf
terraform {
  backend "s3" {
    bucket         = "shop-tfstate-123456789012"
    key            = "shop/terraform.tfstate"
    region         = "sa-east-1"
    encrypt        = true
    use_path_style = true
    use_lockfile   = true
  }
}
```

```
ana@laptop:~/aws/tf/shop$ terraform init -input=false -reconfigure -no-color | grep -E 'Warning|Successfully'
Successfully configured the backend "s3"! Terraform will automatically
```

No warning. The table can be deleted after the last configuration that names it is gone, and the
bootstrap configuration loses its last resource but one.

## When a lock is left behind

A laptop that closes in the middle of an apply leaves the lock: the item in the table, or the
`.tflock` file. Terraform refuses every later plan, correctly, because it cannot tell an abandoned lock
from a live one. **`terraform force-unlock <ID>` removes it**, with the ID the refusal printed, and it
is safe only after confirming with the person in `Who` that their apply is not still running. A
force-unlock during a live apply is exactly the two-writers accident the lock exists to prevent.
