---
title: "Infracost: the price of a pull request"
version: 2
---

A reviewer reading a diff sees words. Here is a one-word change to `web.tf`, made with
`sed -i 's/t3.medium/m7i.large/' web.tf`:

```
ana@laptop:~/shop$ git diff
diff --git a/web.tf b/web.tf
index 841b9ea..db6a789 100644
--- a/web.tf
+++ b/web.tf
@@ -1,7 +1,7 @@
 resource "aws_instance" "web" {
   count         = 2
   ami           = "ami-1e749f67"
-  instance_type = "t3.medium"
+  instance_type = "m7i.large"
   subnet_id     = aws_subnet.private_c.id
 
   root_block_device {
```

`t3.medium` to `m7i.large` reads like a size, and a size is easy to approve. The plan agrees that it
is small, two updates in place and nothing replaced. Priced, it reads differently:

```
ana@laptop:~/shop$ terraform plan -no-color -out tfplan | grep -E "will be updated|instance_type|Plan:"
  # aws_instance.web[0] will be updated in-place
      ~ instance_type                        = "t3.medium" -> "m7i.large"
  # aws_instance.web[1] will be updated in-place
      ~ instance_type                        = "t3.medium" -> "m7i.large"
Plan: 0 to add, 2 to change, 0 to destroy.
ana@laptop:~/shop$ terraform show -json tfplan | python3 price.py
aws_instance.web[0]    update      52.10 ->   120.31
aws_instance.web[1]    update      52.10 ->   120.31
change per month, USD                      +136.44
```

**One word, 136.44 USD more every month**, and each web server goes from 52.10 to 120.31. Nothing in
the diff or in the plan says that. The decision may still be right, since the shop may need the
memory, but it should be taken by somebody who saw the number.

Ana does not take it today. `git checkout -q web.tf` puts the file back to `t3.medium`, and
`rm -f tfplan` throws the priced plan away; the rest of the lesson goes on from the two `t3.medium`
servers.

## What Infracost does

**Infracost does what `price.py` does, for hundreds of resource types, on every pull request.** It
reads a Terraform directory or a plan's JSON, works out which attributes of each resource carry a
price, asks a pricing service for those prices, and prints a breakdown per resource with a monthly
total. Its `diff` command compares two versions of the code, the branch against the main line, and
prints the change in cost; its integrations for the common CI systems post that difference as a
comment on the pull request, so it sits beside the plan that lesson 15 puts there.

Three things about it are worth knowing before you adopt it:

- **It needs a pricing service and an API key.** The prices are not in the program; it looks them
  up in Infracost's own price database, through its API, with a key you get by signing up.
- **It prices list prices for the region you deploy to**, and it knows nothing of your discounts,
  just as the sheet in the previous section does not.
- **Usage is yours to supply.** For what a plan cannot know, gigabytes transferred or requests
  served, it reads a usage file in which you write your own estimates. Without one, those lines
  show a price per unit and no monthly figure, rather than a guessed one.

## Not run here

**Infracost was not run for this lesson, and there is no Infracost output on this page.** Its prices
come from its own service, through an API key that Infracost gives with a free account, and this
course never asks you for an account. An invented breakdown would be the one thing this course
promises never to print. The commands below are what a pipeline would run, written out for reference
and not executed. If you sign up and install Infracost as its documentation describes, you can try
them on `~/shop` with your own key; nothing later in the course depends on it.

```sh
# Not run for this lesson: Infracost needs an API key and its pricing service.
export INFRACOST_API_KEY=...   # from your Infracost account

# on the main branch: the baseline
infracost breakdown --path . --format json --out-file infracost-base.json

# on the pull request's branch: the difference
infracost diff --path . --compare-to infracost-base.json
```

## What stays the same

Changing the tool does not change the method. **The plan is the input, the price is a list price,
and usage is a guess somebody wrote down.** What Infracost adds is coverage, a database of current
prices instead of a pinned sheet, and a place in the review that nobody has to remember to open.
What it cannot add is anything the plan does not contain, which is why the rest of this lesson is
about the money that never appears in a plan at all.
