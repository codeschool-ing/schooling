---
title: From Terraform to Ansible: the inventory as the handover
version: 1
---

Lesson 1 split the work in two: Terraform creates the machines, Ansible configures what is inside
them, and **the trouble starts where the two overlap**. The overlap has one point that cannot be
avoided. Ansible needs the machines' addresses, and only the tool that created the machines knows
them. Written into `inventory.ini` by hand, they would be correct until the first machine is
replaced, and then wrong with nothing to say so.

So Terraform writes the inventory. The `local_file` resource of the `local` provider writes a file
on the laptop, and `templatefile` fills the file from a template, the same `%{ for }` directives
lesson 3 used:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}

# moto runs no machines, so the addresses come in as a variable here.
# Against a real account they would be aws_instance.web[*].private_ip.
variable "web_hosts" {
  type = map(string)
}

variable "db_hosts" {
  type = map(string)
}

resource "local_file" "inventory" {
  filename        = "../ansible/hosts.ini"
  file_permission = "0644"
  content = templatefile("${path.module}/inventory.tftpl", {
    web = var.web_hosts
    db  = var.db_hosts
  })
}

output "inventory" {
  value = local_file.inventory.filename
}
```

```
# Written by Terraform from inventory.tftpl. Edits here are overwritten.
[web]
%{ for name, addr in web ~}
${name} ansible_host=${addr}
%{ endfor ~}

[db]
%{ for name, addr in db ~}
${name} ansible_host=${addr}
%{ endfor ~}

[all:vars]
ansible_user=deploy
ansible_python_interpreter=/usr/bin/python3
```

**One honest substitution in this lab.** Against a real account, the addresses would come straight
from the instances Terraform created, `aws_instance.web[*].private_ip` or a `for` expression over
them. Moto runs no machines, so an instance it creates has no address anything answers on, and
Ana's real machines are the three containers. Their addresses therefore come in as variables, and
everything after that line is what a real configuration does:

```hcl
web_hosts = {
  web1 = "172.30.0.11"
  web2 = "172.30.0.12"
}
db_hosts = {
  db1 = "172.30.0.21"
}
```

```
ana@laptop:~/shop/infra$ terraform apply -auto-approve

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.inventory will be created
  + resource "local_file" "inventory" {
      + content              = <<-EOT
            # Written by Terraform from inventory.tftpl. Edits here are overwritten.
            [web]
            web1 ansible_host=172.30.0.11
            web2 ansible_host=172.30.0.12
            
            [db]
            db1 ansible_host=172.30.0.21
            
            [all:vars]
            ansible_user=deploy
            ansible_python_interpreter=/usr/bin/python3
        EOT
```

```
Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + inventory = "../ansible/hosts.ini"
local_file.inventory: Creating...
local_file.inventory: Creation complete after 0s [id=22081db6a4a1c557c280883557d2974d2dc72996]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

inventory = "../ansible/hosts.ini"
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The handover in three steps. Terraform reads main.tf and terraform.tfvars and writes hosts.ini through a local_file resource. Ansible reads hosts.ini and configures web1, web2 and db1 over SSH. The file is the only thing the two tools share.\"><defs><marker id=\"ho-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Terraform</text><text x=\"115.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">~/shop/infra</text><text x=\"115.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">creates the machines</text><rect x=\"285\" y=\"75\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">hosts.ini</text><text x=\"365.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the contract</text><rect x=\"510\" y=\"60\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ansible</text><text x=\"605.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">~/shop/ansible</text><text x=\"605.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">configures what is inside</text><path d=\"M210 110 L283 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ho-ah-phosphor)\"></path><text x=\"247.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">local_file</text><path d=\"M445 110 L508 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ho-ah-phosphor)\"></path><text x=\"476.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-i</text></svg>", "caption": "The handover: Terraform writes the inventory, and Ansible reads it. Neither tool knows the other exists."}
```

The file is now a product of the configuration. Ana trusts the machines' host keys under their
addresses, since that is the name SSH will see now, and asks Ansible how it reads the new file:

```
ana@laptop:~/shop/ansible$ ssh-keyscan -t ed25519 172.30.0.11 172.30.0.12 172.30.0.21 >> ~/.ssh/known_hosts 2>/dev/null
ana@laptop:~/shop/ansible$ cat hosts.ini
# Written by Terraform from inventory.tftpl. Edits here are overwritten.
[web]
web1 ansible_host=172.30.0.11
web2 ansible_host=172.30.0.12

[db]
db1 ansible_host=172.30.0.21

[all:vars]
ansible_user=deploy
ansible_python_interpreter=/usr/bin/python3
ana@laptop:~/shop/ansible$ ansible-inventory -i hosts.ini --graph
@all:
  |--@ungrouped:
  |--@web:
  |  |--web1
  |  |--web2
  |--@db:
  |  |--db1
```

`ansible_host` is the variable that separates the two names: the host is still called `web1`
everywhere in Ansible, in the recap and in `inventory_hostname`, and the connection goes to the
address. Then the playbook from the previous section, against the inventory Terraform wrote:

```
ana@laptop:~/shop/ansible$ ansible-playbook -i hosts.ini site.yml

PLAY [Web servers] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [web2]
ok: [web1]

TASK [web : Install nginx] *****************************************************
ok: [web2]
ok: [web1]

TASK [web : Create the site's directory] ***************************************
ok: [web1]
ok: [web2]

TASK [web : Write the index page] **********************************************
ok: [web1]
ok: [web2]

TASK [web : Configure the shop's site] *****************************************
ok: [web1]
ok: [web2]

TASK [web : Start nginx] *******************************************************
ok: [web2]
ok: [web1]

PLAY RECAP *********************************************************************
web1                       : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web2                       : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**`changed=0` again**, which proves the two inventories describe the same machines.

### Why a file, and not a call

The file is the whole contract between the two tools, and that is its strength. Terraform does not
run Ansible and Ansible does not read Terraform's state; each can be run, reviewed and replaced on
its own, and the file between them is plain text that a reviewer can read in a pull request.

The alternatives all exist and each moves the line. Terraform can run Ansible itself through a
`local-exec` provisioner when a machine is created, which runs it once, at creation, and never
again, the weakness lesson 1 named for any script run at creation. Ansible can build its inventory
by asking the cloud at run time, with the `aws_ec2` inventory plugin from the `amazon.aws` collection,
which is the better choice once machines come and go faster than anybody runs `terraform apply`;
that collection is not installed in this lab, so it is named here and not shown. And lesson 20 removes
most of the handover altogether, by configuring the image before any machine exists.
