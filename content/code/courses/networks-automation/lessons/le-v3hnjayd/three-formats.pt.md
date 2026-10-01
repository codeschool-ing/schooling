---
title: Uma interface, três formatos
version: 1
---

A automação de redes lê e escreve três formatos de texto o dia inteiro, e cada um veio de um lugar
diferente. **XML** é o que o NETCONF fala. **JSON** é o que as APIs REST, o RESTCONF e o gNMI
falam. **YAML** é o que as pessoas escrevem à mão: inventários, playbooks do Ansible, o estado
pretendido guardado num repositório. A mesma interface, `eth1`, nos três:

```schooling-example
{
  "language": "python",
  "file": "three.py",
  "parts": [
    {
      "code": "import json\n\nimport requests\nimport yaml\n\nfrom nc import NS, connect\n\nwith connect() as m:\n    xml = m.get_config(source=\"running\", filter=(\"xpath\", (NS, \"/if:interfaces/if:interface[if:name='eth1']\"))).data_xml\nprint(xml)\n\nr = requests.get(\"https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth1\",\n                 headers={\"Accept\": \"application/yang-data+json\"}, verify=\"lab-ca.pem\", timeout=10)\nprint(r.text)\n",
      "note": "**A mesma interface por dois protocolos.** O NETCONF responde em XML, o RESTCONF em JSON; o auxiliar da aula 3 abre a sessão NETCONF."
    },
    {
      "code": "print(json.dumps(yaml.safe_load(open(\"eth1.yaml\")), indent=1))",
      "note": "**E um arquivo YAML que uma pessoa escreveu.** `safe_load` o transforma no mesmo tipo de dicionário Python que o `json.loads` devolve."
    }
  ]
}
```

```
ana@ctl:~$ python three.py
<?xml version="1.0" encoding="UTF-8"?><data xmlns="urn:ietf:params:xml:ns:netconf:base:1.0" xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0"><interfaces xmlns="urn:ietf:params:xml:ns:yang:ietf-interfaces"><interface xmlns:ianaift="urn:ietf:params:xml:ns:yang:iana-if-type"><name>eth1</name><description>uplink to core1</description><type>ianaift:ethernetCsmacd</type><enabled>true</enabled></interface></interfaces></data>
{
   "ietf-interfaces:interface": [
      {
         "name": "eth1",
         "description": "uplink to core1",
         "type": "iana-if-type:ethernetCsmacd",
         "enabled": true
      }
   ]
}

{
 "name": "eth1",
 "description": "uplink to core1",
 "type": "ethernetCsmacd",
 "enabled": true,
 "ipv4": {
  "address": [
   {
    "ip": "198.51.100.2",
    "prefix-length": 30
   }
  ]
 }
}
```

Leia as três respostas lado a lado e as diferenças não estão nos dados. **Estão no que cada
formato consegue dizer sobre eles.**

- O XML carrega **namespaces**, e o valor de `type` carrega um prefixo próprio. Nada no texto diz
  se `interface` é um elemento só ou o primeiro de vários.
- O JSON diz que `interface` é uma lista, com colchetes, mesmo com uma entrada só, e escreve o
  nome do módulo na chave, `ietf-interfaces:interface`, que é o jeito da RFC 7951 de fazer o que
  os namespaces faziam.
- O YAML diz o que o autor quis e nada mais. `type` é `ethernetCsmacd` sem módulo nenhum, porque
  quem escreve um inventário não pensa em módulos, e há um endereço `ipv4` que o `nc1` não tem.
  **Um arquivo que uma pessoa escreve é intenção; a resposta do equipamento é fato**, e a aula 11
  trata de perceber quando os dois divergem.

`yaml.safe_load` transformou o YAML no mesmo tipo de dicionário Python que o JSON teria dado.
Depois do parse, um script não sabe dizer de que formato os dados vieram, e esse é o ponto: **os
formatos servem para armazenar e transportar, e o programa trabalha sobre o dicionário.** Os
problemas todos acontecem nas bordas, no parse e na escrita de volta, e é ali que esta aula olha.
