---
title: Um relatório compartilhado, em STIX
version: 1
---

O **STIX 2.1** é o padrão da OASIS para escrever inteligência como objetos JSON: indicadores, as identidades
que os escreveram, campanhas, técnicas, e as relações entre eles. O **TAXII** é o protocolo para levar STIX
de um servidor a outro. Um relatório é um **bundle** de objetos. Aqui está um, escrito para este curso como a
mensagem do grupo de compartilhamento de 12 de setembro; salve-o em `~/week` como `intel.json`:

```json
{
  "type": "bundle",
  "id": "bundle--7c1d0e2f-3a4b-4c5d-8e6f-9a0b1c2d3e4f",
  "objects": [
    {
      "type": "marking-definition",
      "spec_version": "2.1",
      "id": "marking-definition--34098fce-860f-48ae-8e50-ebd3cc5e41da",
      "created": "2017-01-20T00:00:00.000Z",
      "definition_type": "tlp",
      "name": "TLP:GREEN",
      "definition": {
        "tlp": "green"
      }
    },
    {
      "type": "identity",
      "spec_version": "2.1",
      "id": "identity--5b1e3a9c-2f4d-4e8a-9b7c-1d2e3f405162",
      "created": "2026-09-12T14:00:00.000Z",
      "modified": "2026-09-12T14:00:00.000Z",
      "name": "Accounting sector sharing group",
      "identity_class": "organization"
    },
    {
      "type": "indicator",
      "spec_version": "2.1",
      "id": "indicator--1f2e3d4c-5b6a-4978-8a9b-0c1d2e3f4a5b",
      "created": "2026-09-12T14:00:00.000Z",
      "modified": "2026-09-12T14:00:00.000Z",
      "created_by_ref": "identity--5b1e3a9c-2f4d-4e8a-9b7c-1d2e3f405162",
      "name": "SSH password guessing source",
      "description": "Tried many account names against the SSH gateways of three member firms, a few seconds apart.",
      "indicator_types": [
        "malicious-activity"
      ],
      "pattern": "[ipv4-addr:value = '203.0.113.66']",
      "pattern_type": "stix",
      "valid_from": "2026-09-10T00:00:00Z",
      "valid_until": "2026-10-10T00:00:00Z",
      "confidence": 70,
      "object_marking_refs": [
        "marking-definition--34098fce-860f-48ae-8e50-ebd3cc5e41da"
      ]
    },
    {
      "type": "indicator",
      "spec_version": "2.1",
      "id": "indicator--2a3b4c5d-6e7f-4089-9a1b-2c3d4e5f6071",
      "created": "2026-09-12T14:00:00.000Z",
      "modified": "2026-09-12T14:00:00.000Z",
      "created_by_ref": "identity--5b1e3a9c-2f4d-4e8a-9b7c-1d2e3f405162",
      "name": "Upload destination after SSH access",
      "description": "Received large HTTPS uploads from file servers of two member firms, after the guessing above.",
      "indicator_types": [
        "malicious-activity"
      ],
      "pattern": "[ipv4-addr:value = '203.0.113.200']",
      "pattern_type": "stix",
      "valid_from": "2026-09-10T00:00:00Z",
      "valid_until": "2026-10-10T00:00:00Z",
      "confidence": 60,
      "object_marking_refs": [
        "marking-definition--34098fce-860f-48ae-8e50-ebd3cc5e41da"
      ]
    },
    {
      "type": "indicator",
      "spec_version": "2.1",
      "id": "indicator--3b4c5d6e-7f80-4192-a3b4-c5d6e7f80912",
      "created": "2026-09-12T14:00:00.000Z",
      "modified": "2026-09-12T14:00:00.000Z",
      "created_by_ref": "identity--5b1e3a9c-2f4d-4e8a-9b7c-1d2e3f405162",
      "name": "SSH scanner",
      "description": "Generic scanning of SSH servers, reported in June.",
      "indicator_types": [
        "malicious-activity"
      ],
      "pattern": "[ipv4-addr:value = '203.0.113.174']",
      "pattern_type": "stix",
      "valid_from": "2026-06-01T00:00:00Z",
      "valid_until": "2026-08-01T00:00:00Z",
      "confidence": 30,
      "object_marking_refs": [
        "marking-definition--34098fce-860f-48ae-8e50-ebd3cc5e41da"
      ]
    }
  ]
}
```

Ninguém lê STIX a olho por muito tempo. O `jq` lê bem:

```
ana@soc:~/week$ jq -r '.objects[] | [.type, .name] | @tsv' intel.json
marking-definition	TLP:GREEN
identity	Accounting sector sharing group
indicator	SSH password guessing source
indicator	Upload destination after SSH access
indicator	SSH scanner
```

Uma marcação, o grupo que o escreveu e três indicadores. A substância deles:

```
ana@soc:~/week$ jq '.objects[] | select(.type == "indicator") | {name, pattern, valid_until, confidence}' intel.json
{
  "name": "SSH password guessing source",
  "pattern": "[ipv4-addr:value = '203.0.113.66']",
  "valid_until": "2026-10-10T00:00:00Z",
  "confidence": 70
}
{
  "name": "Upload destination after SSH access",
  "pattern": "[ipv4-addr:value = '203.0.113.200']",
  "valid_until": "2026-10-10T00:00:00Z",
  "confidence": 60
}
{
  "name": "SSH scanner",
  "pattern": "[ipv4-addr:value = '203.0.113.174']",
  "valid_until": "2026-08-01T00:00:00Z",
  "confidence": 30
}
```

Cada `pattern` é a linguagem própria do STIX para "um endereço IPv4 cujo valor é…". Para usá-los, compare-os
com o que você viu. Salve isto como `match.py`:

```python
# match.py INTEL.json: look up every indicator address in siem.db, and say if it is still valid
import json, sqlite3, sys, datetime as dt

WEEK_END = dt.datetime(2026, 9, 21, 3, tzinfo=dt.timezone.utc)   # Sunday midnight, local
db = sqlite3.connect("siem.db")
for o in json.load(open(sys.argv[1]))["objects"]:
    if o["type"] != "indicator":
        continue
    ip = o["pattern"].split("'")[1]
    until = dt.datetime.fromisoformat(o["valid_until"].replace("Z", "+00:00"))
    state = "valid" if until > WEEK_END else "expired"
    seen = db.execute("SELECT count(*), min(timestamp), max(timestamp) FROM logs "
                      "WHERE src_ip = ? OR dst_ip = ?", (ip, ip)).fetchone()
    print(f"{ip:15} {state:8} confidence {o['confidence']:3}  seen {seen[0]:3} times"
          + (f", {seen[1]} to {seen[2]} UTC" if seen[0] else ""))
```

```
ana@soc:~/week$ python3 match.py intel.json
203.0.113.66    valid    confidence  70  seen 118 times, 2026-09-17 05:10:06 to 2026-09-17 06:05:22 UTC
203.0.113.200   valid    confidence  60  seen   2 times, 2026-09-17 05:41:12 to 2026-09-17 05:41:12 UTC
203.0.113.174   expired  confidence  30  seen  12 times, 2026-09-17 19:26:54 to 2026-09-21 01:44:02 UTC
```

Três respostas diferentes. `203.0.113.66` é um **indicador válido com 118 eventos** na semana, todos na noite
de quinta: o relatório e os logs descrevem o mesmo visitante, o que aumenta a confiança nos dois.
`203.0.113.200` casa com **dois** eventos, a linha do firewall e o fluxo de 612 MB: o relatório diz que outras
três empresas viram envios para o mesmo endereço depois da mesma adivinhação, então **a transferência de
quinta muito provavelmente foi a mesma coisa**, e não um envio inocente. E `203.0.113.174`, um scanner visto
doze vezes nesta semana, casa com um indicador que **venceu em agosto** com confiança 30: explica um pouco do
ruído de fundo e não justifica nada.

Repare no que as correspondências fizeram e no que não fizeram. Elas não acharam nada novo: a aula 7 já
tinha escalado. Elas **aumentaram a confiança numa hipótese** e disseram à equipe que se trata de uma
campanha contra o setor, o que importa para as aulas 11 e 19. Esse é o valor de costume de um indicador:
raramente a primeira pista, muitas vezes a que diz o que a primeira pista era.
