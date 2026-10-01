---
title: Quais modelos um equipamento tem
version: 1
---

Um equipamento anuncia os modelos que suporta, e ler essa lista é o primeiro passo antes de
automatizá-lo, pelo mesmo motivo que a aula 4 leu as capacidades do gNMI. Servidores NETCONF e
RESTCONF a publicam num modelo próprio, o `ietf-yang-library`:

```
ana@ctl:~$ curl -s -n --cacert lab-ca.pem -H "Accept: application/yang-data+json" https://nc1.example.net/restconf/data/ietf-yang-library:yang-library | jq -r '.["ietf-yang-library:yang-library"]["module-set"][0].module[] | "\(.name) \(.revision)"' | sort
clixon-lib 2026-06-01
iana-if-type 2019-02-08
ietf-datastores 2018-02-14
ietf-inet-types 2021-02-22
ietf-interfaces 2018-02-20
ietf-ip 2018-02-22
ietf-list-pagination 2025-04-03
ietf-list-pagination-nc 2025-04-03
ietf-netconf 2011-06-01
ietf-netconf-acm 2018-02-14
ietf-netconf-monitoring 2010-10-04
ietf-netconf-nmda 2019-01-07
ietf-netconf-private-candidate 2025-10-30
ietf-netconf-with-defaults 2011-06-01
ietf-nmda-compare 2024-04-16
ietf-origin 2018-02-14
ietf-restconf 2017-01-26
ietf-system-capabilities 2021-04-02
ietf-yang-library 2019-01-04
ietf-yang-metadata 2016-08-05
ietf-yang-patch 2017-02-22
ietf-yang-types 2013-07-15
```

O `nc1` traz o `ietf-interfaces` e o `ietf-ip`, os dois que a aula 3 configurou, o `iana-if-type`
para os tipos de interface deles, e os módulos em que os próprios protocolos são definidos:
`ietf-netconf`, `ietf-restconf`, e o `ietf-yang-library`, que descreve esta mesma lista. O
`clixon-lib` é do próprio Clixon. Cada um vem com a sua **revisão**, a data da versão que o
equipamento implementa, e dois equipamentos com revisões diferentes do mesmo módulo podem
discordar sobre o que um caminho quer dizer.

O `example-branches` não está na lista, e o equipamento avisa isso se alguém pedir que ele guarde
dados desse modelo:

```
ana@ctl:~$ curl -si -n --cacert lab-ca.pem -X POST -H "Content-Type: application/yang-data+json" -d @branches.json https://nc1.example.net/restconf/data
HTTP/2 400 
content-type: application/yang-data+json
content-length: 309

{
"ietf-restconf:errors" : {
   "error": {
      "error-type": "application",
      "error-tag": "unknown-namespace",
      "error-info": {
         "bad-namespace": "example-branches"
      },
      "error-severity": "error",
      "error-message": "No yang module found for corresponding prefix"
   }
}

}
```

`unknown-namespace`: **um equipamento só consegue guardar dados dos modelos que tem.** Essa é a
diferença entre um modelo que o operador escreve, como o `example-branches`, que mora no
repositório da própria automação e valida os dados dela, e um modelo que vem com o equipamento,
que decide o que o equipamento vai aceitar. A aula 12 guarda as filiais no NetBox em vez disso, e
a aula 13 confere esse tipo de dado antes de ele virar configuração.
