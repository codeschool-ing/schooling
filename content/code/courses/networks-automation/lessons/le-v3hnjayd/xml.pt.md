---
title: XML e namespaces
version: 1
---

A estrutura do XML é elementos dentro de elementos, com texto dentro do mais interno. O que torna
difícil o XML do NETCONF não é a estrutura, são os **namespaces**. A aula 3 esbarrou na armadilha
uma vez; aqui ela aparece isolada, numa resposta com o formato das que o `nc1` envia:

```schooling-example
{
  "language": "python",
  "file": "xml_read.py",
  "parts": [
    {
      "code": "import xml.etree.ElementTree as ET\n\nREPLY = \"\"\"<data xmlns=\"urn:ietf:params:xml:ns:netconf:base:1.0\">\n  <interfaces xmlns=\"urn:ietf:params:xml:ns:yang:ietf-interfaces\">\n    <interface>\n      <name>eth1</name>\n      <description>uplink to core1</description>\n      <ipv4 xmlns=\"urn:ietf:params:xml:ns:yang:ietf-ip\">\n        <address><ip>198.51.100.2</ip><prefix-length>30</prefix-length></address>\n      </ipv4>\n    </interface>\n  </interfaces>\n</data>\"\"\"\n\nroot = ET.fromstring(REPLY)"
    },
    {
      "code": "print(root[0][0].tag)\nprint(root.findall(\".//interface\"))",
      "note": "**O nome real de todo elemento inclui o namespace.** O ElementTree o escreve entre chaves, e é por isso que uma busca só por `interface` não acha nada."
    },
    {
      "code": "NS = {\"if\": \"urn:ietf:params:xml:ns:yang:ietf-interfaces\", \"ip\": \"urn:ietf:params:xml:ns:yang:ietf-ip\"}\nfor i in root.findall(\".//if:interface\", NS):\n    print(i.findtext(\"if:name\", namespaces=NS), i.findtext(\"ip:ipv4/ip:address/ip:prefix-length\", namespaces=NS))",
      "note": "**Um mapa de prefixos para namespaces resolve.** Os prefixos são escolha do script; só os namespaces precisam bater."
    }
  ]
}
```

```
ana@ctl:~$ python xml_read.py
{urn:ietf:params:xml:ns:yang:ietf-interfaces}interface
[]
eth1 30
```

A primeira linha impressa é o **nome real** do elemento: o namespace entre chaves, depois o nome
local. É com esse nome que o ElementTree compara, então `findall(".//interface")` pede um elemento
chamado `interface` em **nenhum** namespace, e não há nenhum. A lista vazia na segunda linha é o
problema inteiro, e o silêncio é o que o torna caro: nada levanta erro, e um loop sobre uma lista
vazia não faz nada.

A terceira linha é a correção. Um dicionário mapeia prefixos curtos para namespaces, e toda busca
usa os prefixos. **Os prefixos são do próprio script**: o documento poderia usar `if`, `ns0` ou
prefixo nenhum, e a busca ainda casa, porque só o namespace é comparado. `ip:` alcança a parte
`ietf-ip` da árvore, onde estão o endereço e o tamanho do prefixo.

As regras que decorrem disso para todo script que lê NETCONF:

- **Declare todo namespace de que você lê**, uma vez, num só dicionário.
- **Trate um resultado vazio como suspeito.** Uma lista de interfaces que volta vazia de um
  equipamento que certamente tem interfaces é quase sempre um namespace, não o equipamento.
- **Use um filtro do lado do equipamento** quando puder, como a aula 3 fez, para que a resposta
  traga só o que você precisa e a busca tenha menos como errar.
