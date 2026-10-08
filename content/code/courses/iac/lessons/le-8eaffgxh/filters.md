---
title: Filters, and the image that changed under you
version: 2
---

A tag lookup is the simple case. Some data sources search a large catalogue, and the query has to be
narrow enough to come back with one answer. **Machine images** are the usual example: an AWS region
lists thousands of public images, and even moto carries a catalogue of Amazon's. A machine started from the wrong one is a machine running the wrong operating
system.

At the shop an image team bakes the web server's image (lesson 20 is about how) and publishes each
build under a name with its date. In your lab the image team is you again. Its build is a copy of a
throwaway instance started from one of moto's Ubuntu images, and these two commands make it;
`BASE` keeps the instance's id, so stay in the same terminal until the second build:

```sh
BASE=$(aws ec2 run-instances --image-id ami-1e749f67 --instance-type t3.micro --query 'Instances[0].InstanceId' --output text)
aws ec2 create-image --instance-id $BASE --name shop-web-20260915
```

Ana can see the one image that exists so far:

```
ana@laptop:~/shop/app$ aws ec2 describe-images --owners self --query "Images[].[Name,ImageId]" --output text
shop-web-20260915	ami-737937c26a362335e
```

`data "aws_ami"` takes the same filters as `aws ec2 describe-images`, written as `filter` blocks,
plus an `owners` list that says whose images to search, here `self`, the account itself. The pattern
`shop-web-*` matches every build, so **`most_recent = true` picks the newest of them** by creation
date. The instance takes the image's id as its `ami`, and both go in a new file, `image.tf`:

```hcl
data "aws_ami" "web" {
  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["shop-web-*"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.web.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
}

output "web_image" {
  value = data.aws_ami.web.name
}
```

`data.aws_subnets.public.ids[0]` places the instance in the first public subnet the lookup returned;
lesson 4's `for_each` is how you would place one in each. The apply creates the instance, built from
the only image there is:

```
Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + web_image      = "shop-web-20260915"
```

Two weeks later the image team publishes a new build, and retires the throwaway instance. Playing
that part, in the terminal that still holds `BASE`:

```sh
aws ec2 create-image --instance-id $BASE --name shop-web-20261001
aws ec2 terminate-instances --instance-ids $BASE
```

Nobody tells Ana, and nobody needs to, because the image list says it:

```
ana@laptop:~/shop/app$ aws ec2 describe-images --owners self --query "Images[].[Name,ImageId]" --output text
shop-web-20260915	ami-737937c26a362335e
shop-web-20261001	ami-38b09037969105323
```

Ana changes nothing in her files and runs a plan for some other reason. **The query is the same, the
answer is not**, and the instance's `ami` is an argument that cannot be changed on a running
machine:

```
ana@laptop:~/shop/app$ terraform plan
data.aws_caller_identity.current: Reading...
data.aws_region.current: Reading...
data.aws_vpc.shop: Reading...
data.aws_ami.web: Reading...
data.aws_region.current: Read complete after 0s [id=sa-east-1]
data.aws_caller_identity.current: Read complete after 0s [id=123456789012]
data.aws_ami.web: Read complete after 0s [id=ami-38b09037969105323]
data.aws_vpc.shop: Read complete after 0s [id=vpc-6689436bfc5f4d19d]
aws_security_group.web: Refreshing state... [id=sg-99da7cd4f05cceaf2]
data.aws_subnets.public: Reading...
data.aws_subnets.public: Read complete after 0s [id=sa-east-1]
aws_instance.web: Refreshing state... [id=i-bdf35ca9a071c3167]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # aws_instance.web must be replaced
-/+ resource "aws_instance" "web" {
      ~ ami                                  = "ami-737937c26a362335e" -> "ami-38b09037969105323" # forces replacement
```
```
    }

Plan: 1 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  ~ web_image      = "shop-web-20260915" -> "shop-web-20261001"
```

`-/+` means destroy and create again, and `# forces replacement` names the argument responsible.
The configuration did not change, the image did. On a real account that is the web server thrown
away and a new one started from an image nobody on Ana's side has tested, triggered by whoever runs
the next apply, for whatever reason they ran it.

**`most_recent` is a decision to follow the newest image, made once and applied on every plan.**
That is sometimes exactly right: a scratch environment that should always run the latest build.
For production the safer arrangement is to pin the exact build and make moving it a diff somebody
reviews. Ana rewrites `image.tf`:

```hcl
variable "web_image" {
  description = "The exact image the web server runs. Changing it is a deliberate diff."
  type        = string
  default     = "shop-web-20260915"
}

data "aws_ami" "web" {
  owners = ["self"]

  filter {
    name   = "name"
    values = [var.web_image]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.web.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
}

output "web_image" {
  value = data.aws_ami.web.name
}
```

The filter now names one image. `most_recent` is gone because one match needs no tie-break, and if
the name ever matched two images the plan would stop with an error rather than choose (the last
section shows that error). The new build is still there; Ana is not asking for it:

```

No changes. Your infrastructure matches the configuration.
```

Upgrading is now a one-line change to `web_image`, and the plan that shows `-/+` is one somebody
asked for. Lesson 6 shows the other tool for this, `ignore_changes`, which keeps the data source
following the newest image while telling Terraform not to act on it for one argument.
