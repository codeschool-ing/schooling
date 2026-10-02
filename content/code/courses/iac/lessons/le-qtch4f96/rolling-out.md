---
title: Rolling an image out with Terraform
version: 1
---

An image on its own runs nothing. Something has to start machines from it, and replace them when
there is a newer one. On AWS that is Terraform, and the handover between the two repositories is
**one value: the version**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two rows. The image pipeline: a commit to the template, packer build with version 1.1.0, and the image shop-web-1.1.0 published. Then the infrastructure repository: a reviewed change to terraform.tfvars naming 1.1.0, a plan that replaces the instance, and an apply that creates the new instance before destroying the old one. Rolling back is the same path with the previous version.\"><defs><marker id=\"ro-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">the image pipeline</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a commit</text><text x=\"120.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">web.pkr.hcl</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">packer build</text><text x=\"360.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-var version=1.1.0</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">image published</text><text x=\"600.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop-web-1.1.0</text><path d=\"M220 68 L258 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ro-ah-phosphor)\"></path><path d=\"M460 68 L498 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ro-ah-phosphor)\"></path><path d=\"M600 96 L600 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ro-ah-phosphor)\"></path><text x=\"20.0\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">the infrastructure repository</text><rect x=\"500\" y=\"150\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a reviewed diff</text><text x=\"600.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">web_version = \"1.1.0\"</text><rect x=\"260\" y=\"150\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan</text><text x=\"360.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">+/- must be replaced</text><rect x=\"20\" y=\"150\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">apply</text><text x=\"120.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">new one first, then the old</text><path d=\"M500 178 L462 178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ro-ah-phosphor)\"></path><path d=\"M260 178 L222 178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ro-ah-phosphor)\"></path><text x=\"360.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">rolling back is the same path, with the previous version</text></svg>", "caption": "One number crosses from the image pipeline to the infrastructure: the version. Everything else is a replacement Terraform already knows how to make."}
```

The lab's moto cannot run the Packer build that would make an AMI, so the two AMIs below were
**staged**: made in moto from a throwaway instance, the way lesson 5 made its images, and named the
way the `amazon-ebs` source in the section on the template would name them. There is nothing
inside either; moto keeps a record with an id. What Terraform does with them is exactly what it
would do on a real account.

```
ana@laptop:~/shop/app$ aws ec2 describe-images --owners self --query "sort_by(Images,&Name)[].[Name,ImageId]" --output text
shop-web-1.0.1	ami-662fd5acc85ae4f53
shop-web-1.1.0	ami-d9628db9f20e7ed8f
```

Ana's configuration in `~/shop/app` looks the image up by its version, with the `data "aws_ami"`
lookup lesson 5 taught, and starts the web server from it:

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

variable "web_version" {
  description = "The version of the shop-web image the web server runs."
  type        = string
}

data "aws_ami" "web" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["shop-web-${var.web_version}"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.web.id
  instance_type = "t3.micro"
  tags          = { Name = "web", Version = var.web_version }

  lifecycle {
    create_before_destroy = true
  }
}
```

```hcl
web_version = "1.0.1"
```

Two choices in it matter here. The version is a **variable with no default**, set in
`terraform.tfvars`, so the image the shop runs is written in one line of a reviewed file and
nowhere else. And the instance has `create_before_destroy`, from lesson 6, because changing the
image will replace it.

```
ana@laptop:~/shop/app$ terraform apply -auto-approve | tail -n 3
aws_instance.web: Creation complete after 10s [id=i-6d3c2c40eb92536d7]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

## A new version is a one-line diff

When `1.1.0` is published, rolling it out is this change, in a pull request like any other:

```
ana@laptop:~/shop/app$ git diff
diff --git a/terraform.tfvars b/terraform.tfvars
index e62cda6..98a2273 100644
--- a/terraform.tfvars
+++ b/terraform.tfvars
@@ -1 +1 @@
-web_version = "1.0.1"
+web_version = "1.1.0"
```

```
ana@laptop:~/shop/app$ terraform plan -no-color
data.aws_ami.web: Reading...
data.aws_ami.web: Read complete after 0s [id=ami-d9628db9f20e7ed8f]
aws_instance.web: Refreshing state... [id=i-6d3c2c40eb92536d7]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
+/- create replacement and then destroy

Terraform will perform the following actions:

  # aws_instance.web must be replaced
+/- resource "aws_instance" "web" {
      ~ ami                                  = "ami-662fd5acc85ae4f53" -> "ami-d9628db9f20e7ed8f" # forces replacement
```

The lookup now finds the other AMI, and `ami` carries `# forces replacement`: the AWS provider
cannot change the image of an instance that exists, so a different image means a different
instance. **This is the immutable model doing what it says.** Terraform does not upgrade the web server; it
plans a new one and the end of the old. Most of the rest of the long plan is attributes that will be
known only when the new instance exists, and the version tag, which changes with it:

```
      ~ tags                                 = {
            "Name"    = "web"
          ~ "Version" = "1.0.1" -> "1.1.0"
        }
```

```
Plan: 1 to add, 0 to change, 1 to destroy.
```

```
ana@laptop:~/shop/app$ terraform apply -auto-approve | grep -E "Destr|Creat|Apply"
aws_instance.web: Creating...
aws_instance.web: Creation complete after 10s [id=i-ddebb4ffa0104d0d6]
aws_instance.web (deposed object d55ce95b): Destroying... [id=i-6d3c2c40eb92536d7]
aws_instance.web: Destruction complete after 10s
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
```

The order is lesson 6's `+/-`: the new instance is created first, and the old one, kept for a
moment as a *deposed object*, is destroyed after it. On a real account the new machine has nothing left to
install when it boots, so it can start serving as soon as it is up.

## Rolling back is rolling forward to an older number

If `1.1.0` turns out to be wrong, the fix is not to log in to the machine. It is the previous
version, by the same path:

```
ana@laptop:~/shop/app$ git revert --no-edit HEAD | head -n 1
[main 915135f] Revert "web runs shop-web 1.1.0"
ana@laptop:~/shop/app$ terraform plan -no-color | grep -E "must be|ami|Version|Plan:"
data.aws_ami.web: Reading...
data.aws_ami.web: Read complete after 0s [id=ami-662fd5acc85ae4f53]
  # aws_instance.web must be replaced
      ~ ami                                  = "ami-d9628db9f20e7ed8f" -> "ami-662fd5acc85ae4f53" # forces replacement
          ~ "Version" = "1.1.0" -> "1.0.1"
          ~ "Version" = "1.1.0" -> "1.0.1"
Plan: 1 to add, 0 to change, 1 to destroy.
```

`git revert` puts `1.0.1` back in `terraform.tfvars`, and the plan replaces the instance again, now
towards the older image. Two things make that possible, and both are decisions rather than
accidents: the old AMI still exists, because **an image pipeline keeps the last few versions instead of
deleting each one the day its successor ships**; and no machine was ever changed after it
started, so the version number really does describe what will run.

One web server replaced at a time is the simple case. A shop with several behind a load balancer
puts the image in a launch template for an Auto Scaling group, and the group replaces its
instances in batches, through what AWS calls an instance refresh. The shape stays the same: a new
version is a new image id in one place, and machines are replaced to match it, never edited.
