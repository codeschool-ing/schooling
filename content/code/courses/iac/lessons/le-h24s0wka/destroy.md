---
title: Destroy, and what it leaves behind
version: 1
---

**`terraform destroy` removes everything this configuration's state says it created, and nothing
else.** It does not empty the AWS account, and it does not delete your files. A VPC somebody made
by hand in the same account is not in the state, so destroy does not know it exists. Underneath,
it is a plan in which every action is `-`, run against the graph backwards: what was created last
goes first.

Ana runs it on the whole network. The plan above the question lists all seven resources with
every attribute set to `null`, and ends here:

```
Plan: 0 to add, 0 to change, 7 to destroy.

Changes to Outputs:
  - vpc_id                = "vpc-7327c901412b20229" -> null
  - web_security_group_id = "sg-3475d5edf795d5594" -> null
  - web_subnet_id         = "subnet-246685d4ada451bad" -> null

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
local_file.network_env: Destroying... [id=7e6c26ee85afdb7031fa9435305563d6b82f4623]
local_file.network_env: Destruction complete after 0s
aws_vpc_security_group_ingress_rule.https: Destroying... [id=sgr-dcc6bf0490cd0c301]
aws_subnet.web_a: Destroying... [id=subnet-246685d4ada451bad]
aws_s3_bucket.assets: Destroying... [id=shop-assets-2ef20bf6]
aws_subnet.web_a: Destruction complete after 0s
aws_s3_bucket.assets: Destruction complete after 0s
aws_vpc_security_group_ingress_rule.https: Destruction complete after 0s
random_id.bucket: Destroying... [id=LvIL9g]
aws_security_group.web: Destroying... [id=sg-3475d5edf795d5594]
random_id.bucket: Destruction complete after 0s
aws_security_group.web: Destruction complete after 0s
aws_vpc.shop: Destroying... [id=vpc-7327c901412b20229]
aws_vpc.shop: Destruction complete after 0s

Destroy complete! Resources: 7 destroyed.
```

The question is worded harder than apply's, and **"There is no undo" is literal**. A deleted
bucket's objects are gone and a deleted VPC is not coming back. The next apply would create a new
one with a new id. Again only the exact word `yes` proceeds.

The log runs the graph in reverse. The file and the leaf resources go first: the subnet, the
bucket and the rule, which depend on things but have nothing depending on them. The security group
waits for its rule, `random_id` waits for the bucket named after it, and the VPC goes last,
once nothing inside it is left. The order between the leaves changes from run to run, because
they are started together.

**`local_file` is gone too, and that means the file**: destroying it deleted `network.env` from
the laptop, the same way destroying the bucket deleted the bucket. So this is what remains:

```
ana@laptop:~/shop$ ls
main.tf
outputs.tf
storage.tf
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
variables.tf
versions.tf
ana@laptop:~/shop$ terraform state list
ana@laptop:~/shop$ jq ".serial, (.resources | length)" terraform.tfstate
22
0
ana@laptop:~/shop$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].VpcId" --output text
ana@laptop:~/shop$ aws s3 ls
```

**The configuration is untouched**, every `.tf` file and `terraform.tfvars`. AWS has nothing left
under the shop's tags, and `aws s3 ls` lists no bucket. **And the state file is still there**,
recording zero resources. It is not deleted, because it is still the record that this
configuration manages nothing right now, which is a fact and not an absence. `serial` goes up every
time the state changes; `terraform.tfstate.backup` is the version before the last write. Lesson 7
is about both, and about why a lost state file is far worse than an empty one.

`.terraform/` and the lock file stay as well, so nothing needs installing again, and the files
still describe the whole network:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "will be created|^Plan:"
  # aws_s3_bucket.assets will be created
  # aws_security_group.web will be created
  # aws_subnet.web_a will be created
  # aws_vpc.shop will be created
  # aws_vpc_security_group_ingress_rule.https will be created
  # local_file.network_env will be created
  # random_id.bucket will be created
Plan: 7 to add, 0 to change, 0 to destroy.
```

Seven to add: the same seven, with new ids from AWS and a new random suffix, so a new bucket name.
**The description is what lasts; the infrastructure is something you can make again from it.**
That is what makes it reasonable to destroy a development copy every evening, which lesson 16 does
with the cost in view.

Two warnings to take into real accounts. **Destroy is for a whole configuration you are finished
with**: a development copy, a test, every lesson of this course once it ends. To remove one
resource, delete its block and apply, and the plan will show one `-` and nothing else. And for the
things that must never go, a database or a bucket of customer files, lesson 6 adds a guard,
`prevent_destroy`, that makes Terraform refuse a plan which would delete them.
