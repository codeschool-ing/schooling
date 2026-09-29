---
title: Um inventário, e variáveis ao lado dele
version: 1
---

O Ansible é a ferramenta de automação mais usada em redes, e ele chega às mesmas ideias que o
Nornir da aula 8 pelo outro lado. **O Nornir é uma biblioteca Python com que você escreve
programas; o Ansible é um programa para o qual você descreve o estado desejado**, em arquivos YAML
chamados playbooks, e ele descobre o que rodar. Os dois mantêm a lista de equipamentos como dados,
e os dois rodam em muitos equipamentos ao mesmo tempo.

Um projeto é um diretório, e a organização dele é uma convenção que o Ansible lê sozinho:

```
ana@ctl:~$ cd net && find . -type f | sort
./ansible.cfg
./bgp.yaml
./bgp_check.yaml
./facts.yaml
./group_vars/routers.yaml
./host_vars/core1.yaml
./host_vars/edge1.yaml
./host_vars/edge2.yaml
./inventory/hosts.yaml
./mgmt.yaml
./show.yaml
./ticket.yaml
```

O `ansible.cfg` diz onde está o inventário:

```
[defaults]
inventory = inventory
stdout_callback = default
retry_files_enabled = false
```

O inventário agrupa os hosts. `routers` contém dois grupos, `core` e `branches`, então um playbook
pode mirar em todos os roteadores ou só nas filiais:

```yaml
all:
  children:
    routers:
      children:
        core:
          hosts:
            core1: {ansible_host: core1.example.net}
        branches:
          hosts:
            edge1: {ansible_host: edge1.example.net}
            edge2: {ansible_host: edge2.example.net}
```

```
ana@ctl:~$ cd net && ansible-inventory --graph
@all:
  |--@ungrouped:
  |--@routers:
  |  |--@core:
  |  |  |--core1
  |  |--@branches:
  |  |  |--edge1
  |  |  |--edge2
```

**As variáveis ficam ao lado do inventário, em arquivos com o nome de um grupo ou de um host.**
O `group_vars/routers.yaml` vale para todos os roteadores: como conectar, e os valores que todo
roteador compartilha.

```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: frr.frr.frr
ansible_network_cli_ssh_type: paramiko
ansible_user: netops
ansible_ssh_private_key_file: /home/ana/.ssh/id_ed25519
bgp_as: 64512
management_network: 192.0.2.0/24
```

O `host_vars/edge1.yaml` vale para um host, e guarda o que o torna diferente:

```yaml
router_id: 203.0.113.252
bgp_neighbours: [203.0.113.251]
```

O Ansible junta os dois, e o `ansible-inventory --host` mostra o resultado para um host, que é a
primeira coisa a conferir quando um playbook faz algo inesperado:

```
ana@ctl:~$ cd net && ansible-inventory --host edge1
{
    "ansible_connection": "ansible.netcommon.network_cli",
    "ansible_host": "edge1.example.net",
    "ansible_network_cli_ssh_type": "paramiko",
    "ansible_network_os": "frr.frr.frr",
    "ansible_ssh_private_key_file": "/home/ana/.ssh/id_ed25519",
    "ansible_user": "netops",
    "bgp_as": 64512,
    "bgp_neighbours": [
        "203.0.113.251"
    ],
    "management_network": "192.0.2.0/24",
    "router_id": "203.0.113.252"
}
```

As quatro variáveis de conexão são a parte de rede. **`ansible_connection: network_cli` quer dizer
"entrar por SSH num CLI"**, como o Netmiko faz, em vez do jeito habitual do Ansible de copiar
Python para um host Linux e rodá-lo lá, o que um roteador não consegue fazer. O
`ansible_network_os` nomeia a plataforma, `frr.frr.frr` da collection `frr.frr`, para o Ansible
conhecer os prompts e os comandos dela. O `ansible_network_cli_ssh_type: paramiko` escolhe a
biblioteca SSH, a camada de baixo da aula 8.
