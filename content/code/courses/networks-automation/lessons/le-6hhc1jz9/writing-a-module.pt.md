---
title: Escrevendo um módulo
version: 1
---

Modelos não são só para equipamentos. As filiais do laboratório também são dados, e descrevê-las
em YANG dá a elas as mesmas verificações que um equipamento aplica. Um módulo para elas:

```
module example-branches {
  yang-version 1.1;
  namespace "urn:example:branches";
  prefix br;

  import ietf-inet-types { prefix inet; }

  description "The branches of the lab's network, as data.";

  revision 2026-09-29 { description "First version."; }

  typedef branch-id {
    type uint16 { range "1..999"; }
    description "A branch's number, as the finance team assigns it.";
  }

  container branches {
    list branch {
      key "id";
      must "status != 'active' or dns-server" {
        error-message "an active branch needs at least one DNS server";
      }
      leaf id { type branch-id; }
      leaf name {
        type string { length "1..32"; }
        mandatory true;
      }
      leaf lan {
        type inet:ipv4-prefix;
        mandatory true;
      }
      leaf edge-router { type string; }
      leaf-list dns-server {
        type inet:ipv4-address;
        max-elements 2;
      }
      leaf status {
        type enumeration {
          enum planned;
          enum active;
          enum closed;
        }
        default planned;
      }
    }
  }
}
```

Cada peça é de uma das seções anteriores: um `typedef` com um `range`, uma `list` com chave `id`,
um nome `mandatory` com um `length`, uma `lan` com o tipo `inet:ipv4-prefix` importado do
`ietf-inet-types`, uma `leaf-list` de no máximo dois servidores DNS, e uma `enumeration` com um
`default`. Uma instrução é nova. **`must` é uma regra entre nós**, uma expressão XPath que tem que
ser verdadeira para toda filial: aqui, uma filial `active` precisa de pelo menos um `dns-server`.

O `pyang` confere o próprio módulo, e não imprime nada quando ele é válido:

```
ana@ctl:~$ pyang -p ietf example-branches.yang; echo "exit status $?"
exit status 0
ana@ctl:~$ pyang -f tree -p ietf example-branches.yang
module: example-branches
  +--rw branches
     +--rw branch* [id]
        +--rw id             branch-id
        +--rw name           string
        +--rw lan            inet:ipv4-prefix
        +--rw edge-router?   string
        +--rw dns-server*    inet:ipv4-address
        +--rw status?        enumeration
```

Um erro de digitação no nome de um tipo, e o `pyang` aponta a linha:

```
ana@ctl:~$ sed 's/type uint16 {/type unit16 {/' example-branches.yang > broken.yang
ana@ctl:~$ pyang -p ietf broken.yang; echo "exit status $?"
broken.yang:1: warning: unexpected modulename "example-branches" in broken.yang, should be "broken"
broken.yang:13: error: type "unit16" not found in module "example-branches"
exit status 1
```

O aviso é o `pyang` percebendo que o nome do arquivo não bate mais com o nome do módulo, o que é
uma convenção e não uma regra. O erro é o achado de verdade. **Conferir o modelo é a primeira
metade; a segunda é conferir dados contra ele.** Três filiais na codificação JSON que a RFC 7951
define, a que o RESTCONF usou na aula 3:

```json
{
  "example-branches:branches": {
    "branch": [
      {
        "id": 1,
        "name": "Branch 1",
        "lan": "203.0.113.0/26",
        "edge-router": "edge1",
        "dns-server": ["192.0.2.53"],
        "status": "active"
      },
      {
        "id": 2,
        "name": "Branch 2",
        "lan": "203.0.113.64/26",
        "edge-router": "edge2",
        "dns-server": ["192.0.2.53"],
        "status": "active"
      },
      {
        "id": 3,
        "name": "Branch 3",
        "lan": "203.0.113.128/26"
      }
    ]
  }
}
```

O `yanglint`, da libyang, valida dados contra um modelo, e de novo o silêncio quer dizer válido:

```
ana@ctl:~$ yanglint -p ietf example-branches.yang branches.json; echo "exit status $?"
exit status 0
ana@ctl:~$ yanglint -f json -p ietf example-branches.yang branches.json | tail -9
      },
      {
        "id": 3,
        "name": "Branch 3",
        "lan": "203.0.113.128/26"
      }
    ]
  }
}
```

Quando se pede que imprima os dados de volta, ele os devolve como foram lidos; a filial 3 ficou só
com o que o arquivo deu a ela. **Agora quatro jeitos de quebrá-los**, cada um pego por uma linha do
módulo:

```
ana@ctl:~$ sed 's/"id": 3,/"id": 1000,/' branches.json > bad-id.json
ana@ctl:~$ yanglint -p ietf example-branches.yang bad-id.json; echo "exit status $?"
libyang err : Unsatisfied range - value "1000" is out of the allowed range. (Data location "/example-branches:branches/branch/id", line number 21.)
YANGLINT[E]: Failed to parse input data file "bad-id.json".
exit status 7
```

```
ana@ctl:~$ sed 's#203.0.113.128/26#203.0.113.128/33#' branches.json > bad-lan.json
ana@ctl:~$ yanglint -p ietf example-branches.yang bad-lan.json; echo "exit status $?"
libyang err : Unsatisfied pattern - "203.0.113.128/33" does not conform to "(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])/(([0-9])|([1-2][0-9])|(3[0-2]))". (Data location "/example-branches:branches/branch[id='3']/lan", line number 24.)
YANGLINT[E]: Failed to parse input data file "bad-lan.json".
exit status 7
```

```
ana@ctl:~$ python3 -c 'import json; d=json.load(open("branches.json")); b=d["example-branches:branches"]["branch"][2]; b["status"]="active"; json.dump(d, open("bad-dns.json","w"))'
ana@ctl:~$ yanglint -p ietf example-branches.yang bad-dns.json; echo "exit status $?"
libyang err : an active branch needs at least one DNS server (Data location "/example-branches:branches/branch[id='3']".)
YANGLINT[E]: Failed to parse input data file "bad-dns.json".
exit status 7
```

```
ana@ctl:~$ python3 -c 'import json; d=json.load(open("branches.json")); del d["example-branches:branches"]["branch"][1]["name"]; json.dump(d, open("bad-name.json","w"))'
ana@ctl:~$ yanglint -p ietf example-branches.yang bad-name.json; echo "exit status $?"
libyang err : Mandatory node "name" instance does not exist. (Schema location "/example-branches:branches/branch/name".)
YANGLINT[E]: Failed to parse input data file "bad-name.json".
exit status 7
```

O range de `branch-id`, o pattern dentro de `inet:ipv4-prefix`, o `must` com a sua própria
`error-message`, e `mandatory`. Cada erro diz em que ponto dos dados achou o problema, e o
`yanglint` sai com um status diferente de zero, que é o que faz dele uma etapa de um pipeline.
**A aula 13 valida os dados pretendidos da rede exatamente assim**, antes de qualquer coisa chegar
a um equipamento.
