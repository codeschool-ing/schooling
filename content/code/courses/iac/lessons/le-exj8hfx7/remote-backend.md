---
title: Moving the state to S3
version: 1
---

Where the state lives is decided by the **backend**. Until now it has been the default one,
`local`: a file in the working directory, which is why a second directory had no state and built a
second network. A remote backend keeps the one copy somewhere every run can reach, and Terraform
reads it at the start of a command and writes it back at the end, exactly as it did with the file.
For an AWS shop the usual place is an S3 bucket.

**The bucket comes first, and not from this configuration.** A configuration cannot keep its state
in a bucket it creates itself: on the very first `init` the bucket does not exist yet, and a
`destroy` would delete the bucket holding the record of what to destroy. So the bucket is made once,
outside: by hand, as here, or by a small configuration of its own whose state stays local. Ana
names it after the account, because bucket names are global across every AWS customer:

```
ana@laptop:~/shop$ aws s3api create-bucket --bucket shop-tfstate-123456789012 --create-bucket-configuration LocationConstraint=sa-east-1
{
    "Location": "/shop-tfstate-123456789012"
}
ana@laptop:~/shop$ aws s3api put-bucket-versioning --bucket shop-tfstate-123456789012 --versioning-configuration Status=Enabled
ana@laptop:~/shop$ aws s3api put-public-access-block --bucket shop-tfstate-123456789012 --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/shop$ aws s3api get-bucket-versioning --bucket shop-tfstate-123456789012
{
    "Status": "Enabled"
}
```

Two of those commands are not optional. **Versioning** keeps every version of every object, so
each write of the state leaves the previous one recoverable; "protecting" uses it. **Blocking public
access** makes sure no later policy or ACL can publish the bucket by mistake, and what is in the
state is the reason that matters.

Then the backend block, in a file of its own beside `main.tf`:

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

`key` is the path of the state object inside the bucket; one bucket can hold the states of many
configurations, each under its own key, which lesson 8 puts to use. `encrypt` asks S3 to encrypt the
object at rest. `use_lockfile` is the subject of the next section. **None of these values can come
from a variable**: the backend is configured before anything else in the configuration is
evaluated, so it is written out literally, or passed to `terraform init` with `-backend-config`.

Changing the backend is an `init` job, and Terraform notices that there is a local state to carry
over. It asks before copying it:

```
ana@laptop:~/shop$ terraform init -migrate-state
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v6.67.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

What is left in the directory, and what is in the bucket:

```
ana@laptop:~/shop$ ls -l terraform.tfstate*
-rw-r--r-- 1 ana ana    0 Oct  2 00:51 terraform.tfstate
-rw-r--r-- 1 ana ana 5828 Oct  2 00:50 terraform.tfstate.1790913034.backup
-rw-r--r-- 1 ana ana 5835 Oct  2 00:50 terraform.tfstate.1790913055.backup
-rw-r--r-- 1 ana ana 5835 Oct  2 00:51 terraform.tfstate.backup
ana@laptop:~/shop$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 00:51:41       5835 shop/terraform.tfstate
ana@laptop:~/shop$ terraform state list
aws_security_group.web
aws_subnet.public_a
aws_vpc.shop
ana@laptop:~/shop$ rm terraform.tfstate terraform.tfstate.*
```

The local `terraform.tfstate` is now **empty**, zero bytes, and the newest backup is the same size as
the object in the bucket. The bucket holds the state under the key Ana chose,
and `terraform state list` printed the three addresses having read them from S3: nothing local is
involved any more. The old backups are copies of a state that now lives elsewhere, and keeping them
around only invites somebody to restore one, so they go.

The experiment from "losing-it" again, now that `backend.tf` is committed. A fresh clone, an `init`,
a plan:

```
ana@laptop:~$ git clone -q shop shop-2
ana@laptop:~/shop-2$ terraform init
Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
```

```
ana@laptop:~/shop-2$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-10f2b2857589fd959]
aws_subnet.public_a: Refreshing state... [id=subnet-1849baa846a6631fa]
aws_security_group.web: Refreshing state... [id=sg-3bb7d165786e44657]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

**Same repository, a brand new directory, and `No changes`.** The ids in the `Refreshing state` lines
are the original ones: the clone read the same state as Ana's directory, because there is only one.
Any laptop, any colleague and any CI job that has the repository and can read the bucket now plans
against the same record.

Sharing one state solves the duplicate network and opens a different problem straight away: two
of those readers can now try to *write* it at the same moment.
