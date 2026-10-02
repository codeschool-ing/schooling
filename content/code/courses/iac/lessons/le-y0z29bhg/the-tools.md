---
title: The tools, and which job each one does
version: 1
---

The tools in this field are easier to tell apart by the job they do and the way they are written
than by their marketing. This table is the map the course follows, with the lesson where each one
is used:

| tool | job | written in | lessons |
|---|---|---|---|
| **Terraform** | provisioning, any provider | HCL, its own configuration language | 2 to 16 |
| **OpenTofu** | the same, a fork of Terraform | HCL | 17, and 12 for one feature Terraform lacks |
| **CloudFormation** | provisioning, AWS only | YAML or JSON templates | 17 |
| **AWS CDK** | provisioning, AWS only, by generating CloudFormation | TypeScript, Python, Java, C#, Go | 17 |
| **Pulumi** | provisioning, any provider | TypeScript, Python, Go, C#, Java | 17 |
| **Ansible** | configuration management, pushed over SSH | YAML playbooks | 18 |
| **Chef**, **Puppet**, **Salt** | configuration management, mostly by an agent on each machine | Ruby, Puppet's language, YAML | 19 |
| **Packer** | machine images | HCL | 20 |
| **Checkov**, **Trivy**, **tfsec** | reading a description for what it exposes | (they read the others) | 14 |

Two things in that table deserve a sentence each before lesson 2 starts.

**Terraform gets most of the course** because its model is the one the others are measured against:
a description, a provider for each API, a plan you read before anything happens, and a state that
remembers what was made. CloudFormation, Pulumi and the CDK each change one of those four, and
lesson 17 is clearer for having the four in hand first. Everything you learn about plans, state and
modules carries over to OpenTofu unchanged, because it began as the same code.

**A provider is the part that knows one API.** Terraform itself knows nothing about AWS; the AWS
provider, a separate program, knows how to turn `resource "aws_vpc"` into the right calls and read
the result back. There are providers for every large cloud, for DNS services, for GitHub, for
monitoring systems, and for things that are not services at all, like generating a random name or
writing a local file. Lesson 2 meets four of them.

The table has no row for "the tool that does both jobs well", and that is not an oversight. A
working setup uses one tool from the provisioning rows, one from the configuration rows or Packer,
and a clear line between them, which is what `two-jobs` was about.
