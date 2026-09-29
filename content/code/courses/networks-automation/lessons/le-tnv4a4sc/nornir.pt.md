---
title: Nornir, muitos equipamentos de uma vez
version: 1
---

Todo script até aqui percorreu uma lista de nomes digitada nele, um roteador depois do outro.
**O Nornir substitui as duas metades**: a lista vira um inventário mantido como dado, e o laço vira
uma tarefa executada em todo host em threads paralelas. Ele é uma biblioteca Python, não uma
ferramenta com linguagem própria, então uma tarefa é uma função comum.

O inventário são três arquivos YAML. Os hosts, com seu endereço e os dados que os descrevem:

```yaml
---
core1:
  hostname: core1.example.net
  groups: [routers]
  data: {site: core}
edge1:
  hostname: edge1.example.net
  groups: [routers]
  data: {site: branch-1}
edge2:
  hostname: edge2.example.net
  groups: [routers]
  data: {site: branch-2}
edge3:
  hostname: edge3.example.net
  groups: [routers]
  data: {site: branch-3}
```

Os grupos, com o que vários hosts compartilham: aqui a plataforma do Netmiko e o nome do driver do
NAPALM:

```yaml
---
routers:
  platform: cisco_ios
  connection_options:
    napalm:
      platform: frr
      extras:
        optional_args: {key_file: /home/ana/.ssh/id_ed25519}
```

Os defaults, para todo host:

```yaml
---
username: netops
connection_options:
  netmiko:
    extras: {use_keys: true, key_file: /home/ana/.ssh/id_ed25519}
```

E `config.yaml` diz onde estão os três arquivos e em quantos hosts trabalhar ao mesmo tempo:

```yaml
inventory:
  plugin: SimpleInventory
  options:
    host_file: inventory/hosts.yaml
    group_file: inventory/groups.yaml
    defaults_file: inventory/defaults.yaml
runner:
  plugin: threaded
  options:
    num_workers: 10
```

O `edge3` está no inventário de propósito. A filial 3 está planejada nos dados da aula 5 e ainda
não tem roteador, que é como um inventário fica na véspera de uma instalação.

```schooling-example
{
  "language": "python",
  "file": "nr.py",
  "parts": [
    {
      "code": "import json\n\nfrom nornir import InitNornir\nfrom nornir_netmiko.tasks import netmiko_send_command\n"
    },
    {
      "code": "nr = InitNornir(config_file=\"config.yaml\")\nprint(\"hosts:\", \", \".join(nr.inventory.hosts))\n\n",
      "note": "**O inventário é dado**, lido de três arquivos YAML: hosts, os grupos a que pertencem e padrões para tudo. `config.yaml` diz onde eles estão e em quantos hosts trabalhar ao mesmo tempo."
    },
    {
      "code": "def full_neighbours(task):\n    out = task.run(netmiko_send_command, command_string=\"show ip ospf neighbor json\")\n    data = json.loads(out.result)\n    return sum(n[\"nbrState\"].startswith(\"Full\") for e in data[\"neighbors\"].values() for n in e)\n\n\nresult = nr.run(task=full_neighbours)",
      "note": "**Uma tarefa é uma função de um host.** O Nornir a roda em todo host, em threads, e junta o que cada um devolveu ou levantou."
    },
    {
      "code": "for host, r in sorted(result.items()):\n    if r.failed:\n        print(f\"{host:6} FAILED: {type(r[-1].exception).__name__}: {str(r[-1].exception).splitlines()[0]}\")\n    else:\n        print(f\"{host:6} {r[0].result} OSPF neighbour(s) Full\")\nprint(\"failed hosts:\", sorted(result.failed_hosts))",
      "note": "**Um host falhando não para os outros.** O `edge3` está no inventário e não na rede; o resultado dele é uma exceção, e os três roteadores reais responderam assim mesmo."
    }
  ]
}
```

```
ana@ctl:~$ time python nr.py
hosts: core1, edge1, edge2, edge3
core1  2 OSPF neighbour(s) Full
edge1  1 OSPF neighbour(s) Full
edge2  1 OSPF neighbour(s) Full
edge3  FAILED: NetmikoTimeoutException: TCP connection to device failed.
failed hosts: ['edge3']

real	0m0.876s
user	0m0.386s
sys	0m0.123s
```

Três roteadores responderam, e o `edge3` falhou com a causa que o Netmiko deu, **sem parar os
outros**. O Nornir coleta o resultado ou a exceção de cada host, e `failed_hosts` lista os que
precisam de atenção. A execução inteira levou menos de um segundo de relógio, porque os quatro hosts
foram trabalhados ao mesmo tempo em vez de um depois do outro; o script da aula 1 precisava de
segundos para três.

Os hosts são selecionados pelos seus dados, nunca por uma lista de nomes no código:

```schooling-example
{
  "language": "python",
  "file": "nr_filter.py",
  "parts": [
    {
      "code": "from nornir import InitNornir\nfrom nornir.core.filter import F\nfrom nornir_napalm.plugins.tasks import napalm_get\n\nnr = InitNornir(config_file=\"config.yaml\")"
    },
    {
      "code": "branches = nr.filter(F(site__startswith=\"branch-\") & ~F(name=\"edge3\"))\nprint(\"selected:\", \", \".join(branches.inventory.hosts))",
      "note": "**Filtros escolhem hosts pelos dados**, nunca por nomes escritos no código. O mesmo script roda numa filial ou em todas."
    },
    {
      "code": "result = branches.run(task=napalm_get, getters=[\"facts\"])\nfor host, r in sorted(result.items()):\n    facts = r[0].result[\"facts\"]\n    print(host, facts[\"vendor\"], facts[\"os_version\"], len(facts[\"interface_list\"]), \"interfaces\")",
      "note": "**NAPALM pelo Nornir**: o mesmo getter em todo host escolhido, com o driver nomeado no `groups.yaml`."
    }
  ]
}
```

```
ana@ctl:~$ python nr_filter.py
selected: edge1, edge2
edge1 FRRouting 8.4.4 4 interfaces
edge2 FRRouting 8.4.4 4 interfaces
```

`F` monta um filtro a partir dos dados do inventário: todo host cujo `site` começa com `branch-`,
exceto o `edge3`. A tarefa desta vez é o `get` do NAPALM através do `nornir_napalm`, com o driver
nomeado em `groups.yaml`. **O inventário é o único lugar que diz quais equipamentos existem**, e a
aula 12 o leva para o NetBox, onde o Nornir o lê com outro plugin de inventário e nenhuma outra
mudança.
