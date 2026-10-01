---
title: Um inventário que não é um arquivo
version: 1
---

O inventário do Nornir da aula 8 eram três arquivos YAML listando hosts e seus endereços, o que é
uma cópia do que o NetBox já guarda. O plugin `nornir-netbox` monta o inventário a partir do
NetBox em vez disso:

```yaml
inventory:
  plugin: NetBoxInventory2
  options:
    nb_url: https://netbox
    ssl_verify: /home/ana/lab-ca.pem
    filter_parameters: {role: router}
    use_platform_slug: true
    defaults_file: inventory/defaults.yaml
runner:
  plugin: threaded
  options:
    num_workers: 10
```

O filtro é o da própria API, `role=router`, então o nc1 fica de fora exatamente como ficou na
requisição do curl. `use_platform_slug` faz a plataforma de cada host ser o slug da plataforma
dele no NetBox, `frr`, que também é o nome do driver NAPALM do laboratório. O que o NetBox não tem
como saber, o nome de usuário e a chave SSH, fica num arquivo de defaults:

```yaml
---
username: netops
connection_options:
  napalm:
    extras:
      optional_args: {key_file: /home/ana/.ssh/id_ed25519}
```

```schooling-example
{
  "language": "python",
  "file": "nr_nb.py",
  "parts": [
    {
      "code": "from nornir import InitNornir\nfrom nornir_napalm.plugins.tasks import napalm_get\n"
    },
    {
      "code": "nr = InitNornir(config_file=\"nb_config.yaml\")\nfor name, host in nr.inventory.hosts.items():\n    print(f\"{name}: hostname={host.hostname} platform={host.platform} site={host.data['site']['slug']}\")\n\nresult = nr.run(task=napalm_get, getters=[\"facts\"])\nfor name, r in sorted(result.items()):\n    facts = r[0].result[\"facts\"]\n    print(f\"{name}: {facts['vendor']} {facts['os_version']}, interfaces {', '.join(facts['interface_list'])}\")",
      "note": "**O inventário vem do NetBox.** O plugin lê o token da variável de ambiente `NB_TOKEN`, então ele nunca é escrito no `nb_config.yaml`, que vai para o repositório."
    }
  ]
}
```

```
ana@ctl:~$ cd sot && NB_TOKEN=$(cat ~/.netbox-token) python nr_nb.py
core1: hostname=192.0.2.11 platform=frr site=core
edge1: hostname=192.0.2.12 platform=frr site=branch-1
edge2: hostname=192.0.2.13 platform=frr site=branch-2
core1: FRRouting 8.4.4, interfaces eth0, eth1, eth2, lo
edge1: FRRouting 8.4.4, interfaces eth0, eth1, eth2, lo
edge2: FRRouting 8.4.4, interfaces eth0, eth1, eth2, lo
```

**O endereço de cada host veio do seu `primary_ip4`**, o plugin levou o site e todos os outros
campos junto como dados, e o NAPALM alcançou os três roteadores. Um roteador acrescentado ao
NetBox com o papel de roteador e um endereço primário está no inventário da próxima execução sem
ninguém editar um arquivo.

Uma coisa a saber sobre o plugin: **sem `NB_TOKEN` ele não para para avisar.** Ele recorre a um
token de placeholder escrito no próprio código-fonte e envia esse, e o NetBox o recusa:

```
ana@ctl:~$ cd sot && python nr_nb.py 2>&1 | tail -1
ValueError: Failed to get data from NetBox instance https://netbox
```

A mensagem diz que a requisição falhou e não diz por quê, e nada nela menciona um token. Quando um
script que sempre funcionou falha assim, olhe o ambiente primeiro.
