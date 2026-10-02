---
title: Provisioning and configuration management
version: 1
---

"Infrastructure as code" covers two jobs that look alike from far away and are different up close.
Most of the confusion about which tool to use comes from treating them as one.

**Provisioning** is making the resources exist: the network, the subnet, the firewall rule, the
machine, the bucket, the database, the DNS record. Each is something a provider sells, created and
changed through the provider's API, and each has a small set of attributes you can name: this VPC
has the range `10.20.0.0/16`, this machine is a `t3.micro` in `sa-east-1a`. Ana's `network.sh` was
provisioning. Terraform, OpenTofu, CloudFormation and Pulumi do this job.

**Configuration management** is what happens inside a machine once it exists: which packages are
installed, what is in `/etc/nginx/nginx.conf`, which users can log in, which services are running.
None of that is visible to the cloud's API. The tool reaches the operating system itself, over SSH
or through an agent installed on the machine. Ansible, Chef, Puppet and Salt do this job.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two nested layers. The outer one, provisioning, holds what the cloud provider's API creates: the VPC, the subnet, the security group, the machine and the bucket, done by Terraform, OpenTofu, CloudFormation or Pulumi. Inside the machine is the second layer, configuration management: packages, files, users and services, reached over SSH or an agent by Ansible, Chef, Puppet or Salt.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Provisioning: the provider's API</text><text x=\"40.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Terraform, OpenTofu, CloudFormation, Pulumi</text><rect x=\"40\" y=\"80\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">VPC</text><rect x=\"40\" y=\"145\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">subnet</text><rect x=\"40\" y=\"210\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">security group</text><rect x=\"560\" y=\"80\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">bucket</text><rect x=\"560\" y=\"145\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">DNS record</text><rect x=\"200\" y=\"80\" width=\"340\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a machine</text><rect x=\"220\" y=\"115\" width=\"300\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"235.0\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">Configuration management: inside the OS</text><text x=\"235.0\" y=\"151.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Ansible, Chef, Puppet, Salt, over SSH or an agent</text><text x=\"235.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">packages</text><text x=\"235.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">/etc/nginx/nginx.conf</text><text x=\"235.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">users</text><text x=\"380.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">services</text></svg>", "caption": "Two layers. The cloud's API can create the machine and cannot see inside it; that is a second job, for a different kind of tool."}
```

The two jobs ask different questions, and that is why they grew different tools. A provisioning
tool asks *"does a VPC with this range exist, and if not, create one"*, and the answer comes from
one API call. A configuration tool asks *"is nginx installed, at this version, with this file, and
running"*, and the answer comes from looking at a disk and a process table on each of thirty
machines, some of which may be switched off.

**The overlap is real, and it is where most trouble starts.** Ansible has modules that create cloud
resources, and Terraform can run a script on a machine after creating it. Both work. Both are the
second-best tool for that half of the job: Ansible keeps no record of what it created, so it cannot
tell what to remove when a line is deleted, and a script Terraform runs once at creation is never
run again, so the configuration it made drifts like any other. Lesson 18 hands over between the two
on purpose: Terraform creates the machines and writes down their addresses, and Ansible reads them.

There is a third answer, which avoids configuring a running machine at all: install everything into
an **image** before the machine exists, and start machines from it. That is lesson 20, and it turns
most configuration management back into provisioning.
