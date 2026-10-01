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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O inventário como árvore: o grupo routers contém os grupos core e branches; core tem o core1, branches tem o edge1 e o edge2. Ao lado da árvore, as variáveis: group_vars/routers.yaml vale para todo roteador, com o jeito de conectar e o AS do BGP; host_vars/edge1.yaml vale só para o edge1, com o router ID e os vizinhos dele. O Ansible as mescla nas variáveis que o edge1 recebe, e o valor do próprio host ganha onde os dois definem um.\"><defs><marker id=\"iv-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"110\" y=\"20\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">routers</text><rect x=\"20\" y=\"110\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">core</text><rect x=\"200\" y=\"110\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">branches</text><rect x=\"20\" y=\"200\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">core1</text><rect x=\"170\" y=\"200\" width=\"80\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">edge1</text><rect x=\"260\" y=\"200\" width=\"80\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">edge2</text><path d=\"M150 66 L80 108\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M190 66 L260 108\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80 156 L80 198\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M240 156 L210 198\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M280 156 L300 198\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"400\" y=\"20\" width=\"300\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">group_vars/routers.yaml</text><text x=\"550.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">todo roteador: como conectar, o AS do BGP</text><rect x=\"400\" y=\"110\" width=\"300\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">host_vars/edge1.yaml</text><text x=\"550.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só o edge1: router ID, vizinhos</text><rect x=\"400\" y=\"200\" width=\"300\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"550.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o que o edge1 recebe</text><text x=\"550.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ansible-inventory --host edge1</text><path d=\"M550 92 L550 106\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#iv-ah)\"></path><path d=\"M550 182 L550 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#iv-ah)\"></path><path d=\"M210 246 L210 260 L370 260 L396 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#iv-ah)\"></path><text x=\"330\" y=\"285\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o valor do próprio host ganha do grupo</text></svg>", "caption": "Grupos dizem onde um host pertence; arquivos de variáveis dizem o que ele recebe de cada lugar a que pertence.", "same": ["routers", "core", "branches", "core1", "edge1", "edge2", "group_vars/routers.yaml", "host_vars/edge1.yaml", "ansible-inventory --host edge1"]}
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
