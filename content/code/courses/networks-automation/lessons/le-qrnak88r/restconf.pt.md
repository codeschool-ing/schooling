---
title: RESTCONF, os mesmos dados sobre HTTPS
version: 2
---

O RESTCONF serve o mesmo datastore com os mesmos modelos, como REST. **O endereço de um recurso é
o caminho dele pela árvore YANG**: módulo e container, `ietf-interfaces:interfaces`, depois a lista
com a chave depois do `=`, `interface=eth2`. Não há nada a procurar num manual, porque o modelo é o
manual.

```
ana@ctl:~$ curl -s -n --cacert lab-ca.pem -H "Accept: application/yang-data+json" https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth2
{
   "ietf-interfaces:interface": [
      {
         "name": "eth2",
         "description": "to pc1",
         "type": "iana-if-type:ethernetCsmacd",
         "enabled": true
      }
   ]
}
```

O corpo é JSON, na codificação que a RFC 7951 define para dados YANG: **o primeiro elemento de
cada módulo leva o nome do módulo como prefixo**, `ietf-interfaces:interface`, e um valor de outro
módulo também, `iana-if-type:ethernetCsmacd`. É a forma JSON dos namespaces que o NETCONF escreve
em XML.

Os verbos são os da aula 2. `PATCH` mescla, como o `edit-config` padrão do NETCONF, e uma única
folha tem um endereço próprio:

```
ana@ctl:~$ curl -si -n --cacert lab-ca.pem -X PATCH -H "Content-Type: application/yang-data+json" -d '{"ietf-interfaces:interface": [{"name": "eth2", "description": "to pc1, desk 4"}]}' https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth2
HTTP/2 204 

ana@ctl:~$ curl -s -n --cacert lab-ca.pem -H "Accept: application/yang-data+json" https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth2/description
{
   "ietf-interfaces:description": "to pc1, desk 4"
}
```

`POST` na lista cria uma entrada e responde com o endereço dela, e `DELETE` a remove:

```
ana@ctl:~$ curl -si -n --cacert lab-ca.pem -X POST -H "Content-Type: application/yang-data+json" -d '{"ietf-interfaces:interface": [{"name": "eth3", "type": "iana-if-type:ethernetCsmacd", "enabled": false}]}' https://nc1.example.net/restconf/data/ietf-interfaces:interfaces
HTTP/2 201 
location: https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth3
```

```
ana@ctl:~$ curl -si -n --cacert lab-ca.pem -X DELETE https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth3
HTTP/2 204 
```

As credenciais são HTTP Basic, lidas pelo `curl -n` do `~/.netrc` para que nenhuma senha apareça
num comando; o `netlab.sh` grava esse arquivo com uma linha, para o `nc1`, e confere a mesma senha
do outro lado pelo plugin do começo da aula. **Aqui o cliente não gerencia candidate nenhum**: cada edição RESTCONF é validada e
passa pelo commit no servidor num passo só, e uma inválida é recusada antes que qualquer coisa
mude. O erro é o erro do NETCONF embrulhado em JSON, com a mesma tag e a mesma mensagem:

```
ana@ctl:~$ curl -si -n --cacert lab-ca.pem -X PATCH -H "Content-Type: application/yang-data+json" -d '{"ietf-interfaces:interface": [{"name": "eth2", "ietf-ip:ipv4": {"address": [{"ip": "192.0.2.99", "prefix-length": 33}]}}]}' https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth2
HTTP/2 400 
content-type: application/yang-data+json
content-length: 486

{
"ietf-restconf:errors" : {
   "error": {
      "error-type": "application",
      "error-tag": "bad-element",
      "error-info": {
         "bad-element": "prefix-length"
      },
      "error-severity": "error",
      "error-message": "Number 33 out of range: 0 - 32: yang node: \"leaf prefix-length\" with parent: \"choice subnet\" in file \"/etc/clixon/yang/ietf-ip.yang\" error-path: /interfaces/interface[name=\"eth2\"]/ipv4/address[ip=\"192.0.2.99\"]/prefix-length"
   }
}

}
```

A raiz da API diz o que ela serve, e `yang-library-version` aponta para a lista de modelos que o
servidor carrega, que a aula 5 lê:

```
ana@ctl:~$ curl -s -n --cacert lab-ca.pem -H "Accept: application/yang-data+json" https://nc1.example.net/restconf
{
   "ietf-restconf:restconf": {
      "data": {},
      "operations": {},
      "yang-library-version": "2019-01-04"
   }
}
```

Em Python, RESTCONF é `requests`, e o `requests` lê o `~/.netrc` sozinho quando nenhum `auth` é
passado:

```schooling-example
{
  "language": "python",
  "file": "restconf.py",
  "parts": [
    {
      "code": "import requests\n"
    },
    {
      "code": "BASE = \"https://nc1.example.net/restconf/data\"\nJSON = \"application/yang-data+json\"\nhttp = requests.Session()\nhttp.verify = \"lab-ca.pem\"\nhttp.headers.update({\"Accept\": JSON, \"Content-Type\": JSON})\n",
      "note": "**RESTCONF é HTTPS**, então este é o `requests` da aula 2 de novo. As credenciais HTTP Basic vêm do `~/.netrc`, que o `requests` lê sozinho quando nenhum `auth` é dado."
    },
    {
      "code": "r = http.get(f\"{BASE}/ietf-interfaces:interfaces/interface=eth1\", timeout=10)\nr.raise_for_status()\neth1 = r.json()[\"ietf-interfaces:interface\"][0]\nprint(eth1[\"name\"], eth1[\"description\"], eth1[\"enabled\"])\n",
      "note": "**A URL é o caminho pelo modelo**: módulo e container, depois a lista com a chave depois de `=`."
    },
    {
      "code": "r = http.patch(f\"{BASE}/ietf-interfaces:interfaces/interface=eth1\", timeout=10,\n               json={\"ietf-interfaces:interface\": [{\"name\": \"eth1\", \"description\": \"uplink to core1\"}]})\nprint(\"PATCH\", r.status_code)",
      "note": "**Um PATCH mescla.** O corpo tem o mesmo formato JSON que um GET devolve, só com as folhas que mudam."
    }
  ]
}
```

```
ana@ctl:~$ python restconf.py
eth1 uplink to core1, port 7 True
PATCH 204
```

**E é um datastore só.** A descrição definida pelo RESTCONF algumas requisições atrás é o que o
NETCONF lê agora:

```
ana@ctl:~$ python -c "from nc import connect, describe; print(describe(connect(), \"running\", \"eth2\"))"
running   eth2: description='to pc1, desk 4' enabled=true
```

Qual usar é mais uma questão do equipamento e da ferramenta. O NETCONF tem o candidate, os locks e
os confirmed commits, e por isso é o protocolo para mudanças que não podem acontecer pela metade.
O RESTCONF é mais leve, não precisa de nada além de um cliente HTTP, e serve bem para ler estado e
para mudanças únicas. Muitos equipamentos servem os dois a partir dos mesmos modelos, como o `nc1`
faz.
