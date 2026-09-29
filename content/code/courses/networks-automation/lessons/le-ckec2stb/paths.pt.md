---
title: Caminhos
version: 1
---

O gNMI nomeia os dados com um **caminho**, escrito como o caminho de um arquivo pela árvore YANG:
container, lista, chave entre colchetes, folha. `/interfaces/interface[name=eth1]/state/oper-status`
é o estado operacional da `eth1`:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 get --path "/interfaces/interface[name=eth1]/state/oper-status"
[
  {
    "source": "edge1.example.net:9339",
    "timestamp": 1790681185316367229,
    "time": "2026-09-29T08:26:25.316367229-03:00",
    "updates": [
      {
        "Path": "interfaces/interface[name=eth1]/state/oper-status",
        "values": {
          "interfaces/interface/state/oper-status": "UP"
        }
      }
    ]
  }
]
```

A resposta traz um **timestamp** em nanossegundos desde 1970, definido pelo equipamento quando ele
leu o valor; o `gnmic` acrescenta o mesmo instante numa forma legível. Todo valor que o gNMI envia
tem um, e a seção 08 é sobre por que isso importa.

**O OpenConfig separa `config` de `state`.** Sob cada interface, `config` guarda o que alguém pediu
e `state` guarda o que o equipamento está fazendo: as mesmas folhas, `enabled` ou `mtu`, mais as
que só existem como estado, como `oper-status` e `counters`. Uma descrição definida por `config`
aparece em `state` depois de aplicada; uma interface habilitada em `config` ainda pode estar `DOWN`
em `state` porque o cabo está desconectado. O monitoramento lê `state`.

Uma chave pode ser um **curinga**. `name=*` pede todas as interfaces, e a resposta tem um update
por correspondência, cada um com o próprio caminho completo:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 get --path "/interfaces/interface[name=*]/state/counters/in-octets"
[
  {
    "source": "edge1.example.net:9339",
    "timestamp": 1790681185402065380,
    "time": "2026-09-29T08:26:25.40206538-03:00",
    "updates": [
      {
        "Path": "interfaces/interface[name=eth0]/state/counters/in-octets",
        "values": {
          "interfaces/interface/state/counters/in-octets": 9441
        }
      },
      {
        "Path": "interfaces/interface[name=eth1]/state/counters/in-octets",
        "values": {
          "interfaces/interface/state/counters/in-octets": 1858
        }
      },
      {
        "Path": "interfaces/interface[name=eth2]/state/counters/in-octets",
        "values": {
          "interfaces/interface/state/counters/in-octets": 0
        }
      },
      {
        "Path": "interfaces/interface[name=lo]/state/counters/in-octets",
        "values": {
          "interfaces/interface/state/counters/in-octets": 0
        }
      }
    ]
  }
]
```

Um caminho também pode parar num container. Aí o valor é a subárvore inteira, como um único objeto
JSON:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 get --path "/interfaces/interface[name=eth1]/config"
[
  {
    "source": "edge1.example.net:9339",
    "timestamp": 1790681185471864500,
    "time": "2026-09-29T08:26:25.4718645-03:00",
    "updates": [
      {
        "Path": "interfaces/interface[name=eth1]/config",
        "values": {
          "interfaces/interface/config": {
            "description": "uplink to core1",
            "enabled": true,
            "mtu": 1500,
            "name": "eth1"
          }
        }
      }
    ]
  }
]
```

**Um caminho que não corresponde a nada é um erro**, não uma resposta vazia. Não existe `eth9`:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 get --path "/interfaces/interface[name=eth9]/state"
target "edge1.example.net:9339" Get request failed: "edge1.example.net:9339" GetRequest failed: rpc error: code = NotFound desc = nothing at /interfaces/interface[name=eth9]/state
Error: one or more requests failed
```

O `NotFound` nomeia o caminho. Um equipamento responde o mesmo código para uma interface que não
existe e para um caminho que a versão do modelo dele não tem, e é por isso que se leem as
capacidades primeiro.
