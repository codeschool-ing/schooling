---
title: The trouble with one state for everything
version: 2
---

Lesson 7 left the shop with one configuration and one state, kept in S3 under one key. Since then
the configuration has grown. It now holds the network, the `web` security group and the two
buckets from lesson 6, all in one `main.tf`:

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

# The network: made once, changed a few times a year.
resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-c" }
}

# The application: changed every week.
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

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-dev"
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
```

**To start where Ana is**, remember that your moto is empty at the start of every lesson. Make
lesson 7's state bucket again, with versioning on:

```sh
aws s3api create-bucket --bucket shop-tfstate-123456789012 --create-bucket-configuration LocationConstraint=sa-east-1
aws s3api put-bucket-versioning --bucket shop-tfstate-123456789012 --versioning-configuration Status=Enabled
```

Then, in `~/shop`, save the `main.tf` above and lesson 7's `backend.tf` beside it:

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

and apply them and commit, with lesson 7's `.gitignore`:

```sh
terraform init
terraform apply -auto-approve
printf ".terraform/\n*.tfstate\n*.tfstate.*\n" > .gitignore
git init -q && git add . && git commit -qm "the shop, in one state"
```

The backend is lesson 7's, unchanged, and the state holds six resources under one key:

```
ana@laptop:~/shop$ terraform state list
aws_s3_bucket.assets
aws_s3_bucket.logs
aws_security_group.web
aws_subnet.public_a
aws_subnet.public_c
aws_vpc.shop
ana@laptop:~/shop$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 07:08:56      12484 shop/terraform.tfstate
```

**Nothing is broken, and that is why the shape lasts.** One directory, one `apply`, one place to
look. A single state is the right start for a small configuration, and every team begins there. The
question is what it costs as the configuration grows, and the cost shows up in three places.

## Every change plans everything

Ana tags the assets bucket. It is one line in one resource:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index 6ddd87f..583a3b8 100644
--- a/main.tf
+++ b/main.tf
@@ -49,6 +49,7 @@ resource "aws_security_group" "web" {
 
 resource "aws_s3_bucket" "assets" {
   bucket = "shop-assets-dev"
+  tags   = { Owner = "ana" }
 }
 
 resource "aws_s3_bucket" "logs" {
ana@laptop:~/shop$ terraform plan -no-color | grep -E "Refreshing|^  #|^Plan"
aws_vpc.shop: Refreshing state... [id=vpc-644904a24046c8bab]
aws_s3_bucket.logs: Refreshing state... [id=shop-logs-dev]
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]
aws_subnet.public_c: Refreshing state... [id=subnet-0bf2cbc4f593b157b]
aws_security_group.web: Refreshing state... [id=sg-020bb5a164511a5d9]
aws_subnet.public_a: Refreshing state... [id=subnet-2fc7f0dc6fb32b7e4]
  # aws_s3_bucket.assets will be updated in-place
Plan: 0 to add, 1 to change, 0 to destroy.
```

**One resource to change, and six refreshed to find that out.** Before every plan, Terraform asks
AWS about every resource in the state, because it cannot know which ones somebody changed by hand.
Six calls cost nothing. With six hundred, the plan for a tag on a bucket waits on every subnet,
route and DNS record the company owns. The lock from lesson 7 is held for all of it, so nobody
else can plan the network while Ana tags her bucket. She does not apply the tag, and puts the
file back with `git checkout main.tf`.

## The blast radius is the whole state

The plan above changed one bucket, and it could have changed anything. **The state a command runs
against is the set of things a mistake can reach.** A typo in a reference, a bad merge that
deletes a block, a `-replace` aimed at the wrong address: each one is applied to whatever the state
holds. In this configuration a careless edit to the app can destroy the VPC, and every subnet and
group inside it goes with it.

## Who may change what

Permissions follow the state, not the resource. Whoever may apply this configuration may change
everything in it, so a pipeline that deploys the app every day holds the credentials to rebuild
the network. And people step on each other: the network team waits for the app's plan to release
the lock, and reviews pull requests full of changes they do not own.

## Where to cut

The usual cut follows two questions. **How often does it change, and who changes it?** The VPC
and its subnets are made once and touched a few times a year, by whoever owns the network. The
security group and the buckets change with the application, every week. Two answers, so two
states:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two layouts side by side. On the left, one state, shop/terraform.tfstate, holds the VPC, two subnets, the web security group and two buckets, behind one lock that everybody shares. On the right, the same resources in two states: network/terraform.tfstate holds the VPC and the subnets and changes a few times a year; app/terraform.tfstate holds the security group and the buckets and changes every week. The network publishes outputs, and the app reads them with terraform_remote_state.\"><defs><marker id=\"sp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sp-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"250\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">one state, one lock</text><text x=\"145.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop/terraform.tfstate</text><text x=\"145.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_vpc.shop</text><text x=\"145.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.public_a</text><text x=\"145.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.public_c</text><text x=\"145.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_security_group.web</text><text x=\"145.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_s3_bucket.assets</text><text x=\"145.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_s3_bucket.logs</text><text x=\"145.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">every change plans all six</text><rect x=\"330\" y=\"30\" width=\"370\" height=\"100\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">network: a few changes a year</text><text x=\"345.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">network/terraform.tfstate</text><text x=\"345.0\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_vpc.shop</text><text x=\"345.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.public_a  aws_subnet.public_c</text><rect x=\"330\" y=\"180\" width=\"370\" height=\"100\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">app: changes every week</text><text x=\"345.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app/terraform.tfstate</text><text x=\"345.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_security_group.web</text><text x=\"345.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_s3_bucket.assets  aws_s3_bucket.logs</text><path d=\"M515 132 L515 178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah-phosphor)\"></path><text x=\"530.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">outputs</text><text x=\"530.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">terraform_remote_state</text><path d=\"M274 145 L326 145\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah-wire)\"></path><text x=\"360.0\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">split by how often it changes and who changes it</text></svg>", "caption": "One state for everything against two states cut along how often things change and who changes them."}
```

Other lines are just as reasonable: per environment (lesson 11), per team, or by how dangerous a
mistake is, with the database apart from everything that can be rebuilt. What they share is that
**the cut follows ownership and lifecycle, never the size of a file**. A state split at random
gives you two configurations that both have to change for every feature, which is worse than one.

The price of splitting is a boundary. The app's security group needs the VPC's id, and after the
split that id lives in another state. The next two sections make the cut and then build the
bridge across it.
