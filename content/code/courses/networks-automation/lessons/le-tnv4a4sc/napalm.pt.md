---
title: NAPALM, os mesmos métodos em todo lugar
version: 2
---

O Netmiko ainda deixa o script falando a língua de cada fabricante: os comandos, o formato da saída
e as mensagens de erro são todos diferentes. **O NAPALM põe uma interface só sobre todos eles.** Um
driver por plataforma implementa os mesmos métodos, então `get_facts()` devolve o mesmo dicionário
com as mesmas chaves de um roteador Juniper, Arista ou Cisco, e o script nunca vê um comando.

O NAPALM vem com drivers para EOS, IOS, IOS-XR, Junos e NX-OS, e outras plataformas têm drivers da
comunidade, encontrados pelo nome: `get_network_driver("xyz")` importa um pacote chamado
`napalm_xyz`. **Não existe nenhum para o FRR**, então o laboratório tem um, `napalm_frr`, o driver
que a seção anterior imprimiu; ele entra com o Netmiko e usa a ferramenta do próprio FRR, `frr-reload.py`, para
calcular as mudanças de configuração. O que esta seção mostra é a interface do NAPALM, que é a mesma
seja qual for o driver.

```schooling-example
{
  "language": "python",
  "file": "facts.py",
  "parts": [
    {
      "code": "import json\n\nfrom napalm import get_network_driver\n"
    },
    {
      "code": "driver = get_network_driver(\"frr\")\nwith driver(\"edge1\", \"netops\", None, optional_args={\"key_file\": \"/home/ana/.ssh/id_ed25519\"}) as dev:\n    print(json.dumps(dev.get_facts(), indent=2))\n    print(json.dumps(dev.get_interfaces_ip(), indent=2))",
      "note": "**O NAPALM pede um driver pelo nome** e recebe uma classe com os mesmos métodos em toda plataforma: `get_facts`, `get_interfaces`, `load_merge_candidate`. Aqui o nome é `frr`, o driver do laboratório, porque o NAPALM não traz um para FRR; com `eos` ou `junos` o resto do arquivo não mudaria."
    }
  ]
}
```

```
ana@ctl:~$ python facts.py
{
  "hostname": "edge1",
  "fqdn": "edge1.example.net",
  "vendor": "FRRouting",
  "model": "FRR",
  "os_version": "8.4.4",
  "serial_number": "",
  "uptime": -1.0,
  "interface_list": [
    "eth0",
    "eth1",
    "eth2",
    "lo"
  ]
}
{
  "eth0": {
    "ipv4": {
      "192.0.2.12": {
        "prefix_length": 24
      }
    }
  },
  "eth1": {
    "ipv4": {
      "198.51.100.2": {
        "prefix_length": 30
      }
    }
  },
  "eth2": {
    "ipv4": {
      "203.0.113.1": {
        "prefix_length": 26
      }
    }
  },
  "lo": {
    "ipv4": {
      "203.0.113.252": {
        "prefix_length": 32
      }
    }
  }
}
```

Dois getters, dois dicionários num formato documentado. `uptime` é `-1.0` porque o FRR não informa
há quanto tempo o roteador está no ar, e o driver diz isso com a convenção do NAPALM para um valor
desconhecido em vez de inventar um. **Essa é a troca que o NAPALM faz**: as mesmas chaves em todo
lugar, e algumas delas vazias nas plataformas que não conseguem preenchê-las.

Os getters cobrem o que a maioria dos scripts lê: interfaces, seus endereços e contadores, tabelas
ARP e MAC, vizinhos BGP, vizinhos LLDP, a configuração. Um script escrito sobre eles roda em toda
plataforma que tenha driver, e as verificações da aula 13 os usam exatamente por isso.
