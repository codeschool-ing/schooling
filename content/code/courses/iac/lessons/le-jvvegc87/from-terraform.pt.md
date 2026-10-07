---
title: Do Terraform ao Ansible: o inventário como passagem de bastão
version: 2
---

A aula 1 dividiu o trabalho em dois: o Terraform cria as máquinas, o Ansible configura o que há
dentro delas, e **o problema começa onde os dois se sobrepõem**. A sobreposição tem um ponto que não
dá para evitar. O Ansible precisa dos endereços das máquinas, e só a ferramenta que criou as
máquinas os conhece. Escritos à mão no `inventory.ini`, eles estariam certos até a primeira máquina
ser substituída, e depois errados sem nada que avise.

Então o Terraform escreve o inventário. O recurso `local_file` do provider `local` escreve um arquivo
no laptop, e o `templatefile` preenche o arquivo a partir de um template, com as mesmas diretivas
`%{ for }` que a aula 3 usou:

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

**Uma substituição honesta neste lab.** Contra uma conta real, os endereços viriam direto das
instâncias que o Terraform criou, `aws_instance.web[*].private_ip` ou uma expressão `for` sobre elas.
O moto não roda máquinas, então uma instância que ele cria não tem endereço em que algo responda, e
as máquinas reais da Ana são os três contêineres. Os endereços deles entram, portanto, como
variáveis, e tudo depois dessa linha é o que uma configuração real faz:

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
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A passagem em três passos. O Terraform lê main.tf e terraform.tfvars e escreve hosts.ini por um recurso local_file. O Ansible lê hosts.ini e configura web1, web2 e db1 por SSH. O arquivo é a única coisa que as duas ferramentas compartilham.\"><defs><marker id=\"ho-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Terraform</text><text x=\"115.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">~/shop/infra</text><text x=\"115.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cria as máquinas</text><rect x=\"285\" y=\"75\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">hosts.ini</text><text x=\"365.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o contrato</text><rect x=\"510\" y=\"60\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ansible</text><text x=\"605.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">~/shop/ansible</text><text x=\"605.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">configura o que há dentro</text><path d=\"M210 110 L283 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ho-ah-phosphor)\"></path><text x=\"247.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">local_file</text><path d=\"M445 110 L508 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ho-ah-phosphor)\"></path><text x=\"476.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-i</text></svg>", "caption": "A passagem: o Terraform escreve o inventário, e o Ansible o lê. Nenhuma das duas ferramentas sabe que a outra existe.", "same": ["Terraform", "Ansible"]}
```

O arquivo agora é um produto da configuração. A Ana confia nas chaves de host das máquinas pelos
endereços, já que é esse o nome que o SSH vai ver agora, e pergunta ao Ansible como ele lê o arquivo
novo:

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

`ansible_host` é a variável que separa os dois nomes: o host continua se chamando `web1` em todo o
Ansible, no resumo e no `inventory_hostname`, e a conexão vai para o endereço. Então o playbook da
seção anterior, contra o inventário que o Terraform escreveu:

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

**`changed=0` de novo**, o que prova que os dois inventários descrevem as mesmas máquinas.

### Por que um arquivo, e não uma chamada

O arquivo é o contrato inteiro entre as duas ferramentas, e essa é a força dele. O Terraform não roda
o Ansible e o Ansible não lê o estado do Terraform; cada um pode ser rodado, revisado e substituído
sozinho, e o arquivo entre eles é texto puro que um revisor consegue ler num pull request.

As alternativas existem todas, e cada uma move a linha. O Terraform pode rodar o próprio Ansible por
um provisioner `local-exec` quando uma máquina é criada, o que o roda uma vez, na criação, e nunca
mais, a fraqueza que a aula 1 apontou em qualquer script rodado na criação. O Ansible pode montar o
inventário perguntando à nuvem na hora da execução, com o plugin de inventário `aws_ec2` da coleção
`amazon.aws`, que é a escolha melhor quando as máquinas vêm e vão mais depressa do que alguém roda
`terraform apply`. Esta aula instalou só o `ansible-core`, que não inclui essa coleção, então ela é
nomeada aqui e não mostrada. E a aula 20 elimina quase toda a passagem, configurando a imagem antes que exista qualquer
máquina.
