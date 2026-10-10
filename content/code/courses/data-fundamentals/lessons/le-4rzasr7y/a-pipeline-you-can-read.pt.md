---
title: Um pipeline que se lê de uma vez
version: 1
---

**As cinco etapas cabem em quatro programas de menos de quarenta linhas cada, e vê-las pequenas é o
jeito mais rápido de reconhecê-las quando são grandes.** Um programa faz o papel do aplicativo e gera
viagens; um ingere um dia delas; um transforma; um entrega o relatório da manhã. Cada um lê só o que
a etapa anterior gravou, então as fronteiras entre as etapas são arquivos que você pode abrir.

Esta aula trabalha num diretório próprio, dentro do laboratório da aula 1. Crie o diretório e entre
nele:

```sh
mkdir -p ~/roda/lifecycle && cd ~/roda/lifecycle
```

Todo programa abaixo começa com um comentário que nomeia o arquivo. Salve cada um com esse nome em
`~/roda/lifecycle`.

## Geração: o aplicativo

O primeiro programa faz as vezes do aplicativo da Roda Livre. Ele grava o banco do próprio
aplicativo, um arquivo SQLite chamado `app.db`, com três dias de viagens.

```schooling-example
{"language": "python", "file": "lifecycle/app.py", "parts": [
{"code": "# lifecycle/app.py\nimport random\nimport sqlite3\nfrom datetime import datetime, timedelta\n\nSTATIONS = {\"ST01\": \"Praça Tiradentes\", \"ST02\": \"Rua XV\", \"ST03\": \"Jardim Botânico\",\n            \"ST04\": \"Passeio Público\", \"ST05\": \"Rodoferroviária\", \"ST06\": \"Largo da Ordem\",\n            \"ST07\": \"Shopping Estação\", \"ST08\": \"Parque Barigui\", \"ST09\": \"UFPR Politécnico\",\n            \"ST10\": \"Batel\", \"ST11\": \"Mercado Municipal\", \"ST12\": \"Ópera de Arame\"}\nBUSY = [4, 6, 2, 3, 4, 3, 2, 5, 3, 3, 2, 1]\n\n", "note": "As doze estações, e o movimento de cada uma como um peso: a Rua XV aparece seis vezes mais que a Ópera de Arame. Um aplicativo de verdade não tem essa lista; é o jeito de este programa imitar uma cidade."},
{"code": "random.seed(15)\ndb = sqlite3.connect(\"app.db\")\ndb.executescript(\"\"\"\nDROP TABLE IF EXISTS stations;\nDROP TABLE IF EXISTS rides;\nCREATE TABLE stations (station_id TEXT PRIMARY KEY, name TEXT);\nCREATE TABLE rides (ride_id TEXT PRIMARY KEY, bike_id TEXT, start_station TEXT,\n                    end_station TEXT, started_at TEXT, minutes INTEGER, price_cents INTEGER);\n\"\"\")\ndb.executemany(\"INSERT INTO stations VALUES (?, ?)\", STATIONS.items())\n\n", "note": "O banco do aplicativo: um arquivo SQLite, duas tabelas. O SQL é assunto de `sql-databases`; leia aqui como uma lista de colunas. As linhas `DROP` fazem uma segunda execução recomeçar do zero, e a semente fixa faz ela recomeçar com as mesmas viagens."},
{"code": "n = 0\nfor day in (14, 15, 16):\n    count = random.randint(160, 220)\n    for offset in sorted(random.randint(0, 16 * 60) for _ in range(count)):\n        n += 1\n        start, end = random.choices(list(STATIONS), BUSY, k=2)\n        at = datetime(2025, 9, day, 6) + timedelta(minutes=offset)\n        minutes = random.randint(0, 45)\n        db.execute(\"INSERT INTO rides VALUES (?, ?, ?, ?, ?, ?, ?)\",\n                   (f\"R{n:06d}\", f\"B{random.randint(1, 90):03d}\", start, end,\n                    at.strftime(\"%Y-%m-%d %H:%M\"), minutes, 300 + 20 * minutes))\n", "note": "Três dias de viagens, de 14 a 16 de setembro, entre 06:00 e 22:00, numeradas na ordem em que começaram, como um aplicativo numeraria. `minutes` pode ser 0 ou 1, o que vai importar para a transformação. O preço é inventado: 300 centavos mais 20 por minuto."},
{"code": "db.commit()\nprint(n, \"rides in app.db, from 14 to 16 September\")\n", "note": "Nada vai para o arquivo antes do `commit`."}
]}
```

```
ana@lab:~/roda/lifecycle$ python app.py
562 rides in app.db, from 14 to 16 September
```

Daqui em diante, `app.db` é a origem: os outros programas o leem e nunca escrevem nele.

## Ingestão: um dia, copiado para fora

```schooling-example
{"language": "python", "file": "lifecycle/ingest.py", "parts": [
{"code": "# lifecycle/ingest.py\nimport json\nimport os\nimport sqlite3\nimport sys\n\n"},
{"code": "day = sys.argv[1]\napp = sqlite3.connect(\"file:app.db?mode=ro\", uri=True)\napp.row_factory = sqlite3.Row\nrides = app.execute(\"SELECT * FROM rides WHERE started_at LIKE ?\", (day + \"%\",)).fetchall()\nstations = app.execute(\"SELECT * FROM stations\").fetchall()\n\n", "note": "O dia vem da linha de comando. `mode=ro` abre o banco do aplicativo só para leitura, então a ingestão não consegue mudar a origem nem por engano. As viagens são copiadas um dia por vez, que é uma carga incremental; as doze estações são copiadas inteiras, toda vez, que é uma carga completa."},
{"code": "part = f\"raw/date={day}\"\nos.makedirs(part, exist_ok=True)\nfor name, rows in ((\"rides\", rides), (\"stations\", stations)):\n    with open(f\"{part}/{name}.jsonl\", \"a\", encoding=\"utf-8\") as f:\n        for row in rows:\n            f.write(json.dumps(dict(row), ensure_ascii=False) + \"\\n\")\n    print(f\"{len(rows):4} {name:8} -> {part}/{name}.jsonl\")\n", "note": "Cada tabela chega como JSON Lines, uma linha por registro, com os nomes de coluna do próprio aplicativo, num diretório com o nome do dia. O `\"a\"` abre cada arquivo para acrescentar, e é a essa linha que a próxima seção volta."}
]}
```

Rode para a segunda-feira:

```
ana@lab:~/roda/lifecycle$ python ingest.py 2025-09-15
 187 rides    -> raw/date=2025-09-15/rides.jsonl
  12 stations -> raw/date=2025-09-15/stations.jsonl
```

A zona bruta agora guarda a segunda, exatamente como o aplicativo a tinha. Cada linha é um registro
da tabela do aplicativo:

```
ana@lab:~/roda/lifecycle$ find raw -type f | sort
raw/date=2025-09-15/rides.jsonl
raw/date=2025-09-15/stations.jsonl
ana@lab:~/roda/lifecycle$ head -1 raw/date=2025-09-15/rides.jsonl
{"ride_id": "R000174", "bike_id": "B014", "start_station": "ST10", "end_station": "ST04", "started_at": "2025-09-15 06:01", "minutes": 44, "price_cents": 1180}
```

## Transformação: limpar, juntar, contar

```schooling-example
{"language": "python", "file": "lifecycle/transform.py", "parts": [
{"code": "# lifecycle/transform.py\nimport csv\nimport json\nimport os\nimport sys\n\n"},
{"code": "day = sys.argv[1]\n\n\ndef read(name):\n    with open(f\"raw/date={day}/{name}.jsonl\", encoding=\"utf-8\") as f:\n        return [json.loads(line) for line in f]\n\n", "note": "A transformação lê a zona bruta e mais nada. Ela nunca consulta o aplicativo."},
{"code": "names = {s[\"station_id\"]: s[\"name\"] for s in read(\"stations\")}\nrides = read(\"rides\")\nkept = [r for r in rides if r[\"minutes\"] >= 2]\n\n", "note": "A tabela de consulta para a junção, e a regra de limpeza: uma viagem de menos de 2 minutos é uma partida falsa e sai. O limite é uma decisão, e esta linha é onde ela fica escrita."},
{"code": "per_station = {}\nfor r in kept:\n    r[\"start_name\"] = names[r[\"start_station\"]]\n    per_station.setdefault(r[\"start_station\"], []).append(r[\"minutes\"])\n\n", "note": "A junção, que dá a cada viagem o nome da estação, e o agrupamento de onde saem as contagens."},
{"code": "os.makedirs(f\"clean/date={day}\", exist_ok=True)\nwith open(f\"clean/date={day}/rides.jsonl\", \"w\", encoding=\"utf-8\") as f:\n    for r in kept:\n        f.write(json.dumps(r, ensure_ascii=False) + \"\\n\")\n", "note": "A zona limpa: toda viagem mantida, com o nome. `\"w\"` sobrescreve, então este passo pode rodar quantas vezes for preciso."},
{"code": "os.makedirs(f\"curated/date={day}\", exist_ok=True)\nwith open(f\"curated/date={day}/rides_per_station.csv\", \"w\", newline=\"\", encoding=\"utf-8\") as f:\n    out = csv.writer(f)\n    out.writerow([\"station_id\", \"name\", \"rides\", \"minutes\"])\n    for st, mins in sorted(per_station.items()):\n        out.writerow([st, names[st], len(mins), sum(mins)])\nprint(f\"{len(rides)} raw, {len(kept)} kept, {len(rides) - len(kept)} under 2 minutes dropped\")\n", "note": "A zona curada: uma linha por estação, no formato que o relatório quer."}
]}
```

```
ana@lab:~/roda/lifecycle$ python transform.py 2025-09-15
187 raw, 176 kept, 11 under 2 minutes dropped
```

## Entrega: o relatório da manhã

O último programa lê a zona curada e mais nada. É curto o bastante para ler inteiro:

```python
# lifecycle/report.py
import csv
import sys

day = sys.argv[1]
with open(f"curated/date={day}/rides_per_station.csv", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

total = sum(int(r["rides"]) for r in rows)
print(f"Roda Livre, rides on {day}: {total}")
print("Busiest stations:")
for r in sorted(rows, key=lambda r: -int(r["rides"]))[:3]:
    print(f"  {r['station_id']} {r['name']:<16} {r['rides']:>4}")
```

```
ana@lab:~/roda/lifecycle$ python report.py 2025-09-15
Roda Livre, rides on 2025-09-15: 176
Busiest stations:
  ST02 Rua XV             29
  ST01 Praça Tiradentes   21
  ST08 Parque Barigui     16
```

Esse é o relatório da manhã de Marta, e cada etapa do ciclo de vida está no disco por trás dele:

```
ana@lab:~/roda/lifecycle$ find raw clean curated -type f | sort
clean/date=2025-09-15/rides.jsonl
curated/date=2025-09-15/rides_per_station.csv
raw/date=2025-09-15/rides.jsonl
raw/date=2025-09-15/stations.jsonl
ana@lab:~/roda/lifecycle$ head -4 curated/date=2025-09-15/rides_per_station.csv
station_id,name,rides,minutes
ST01,Praça Tiradentes,21,572
ST02,Rua XV,29,610
ST03,Jardim Botânico,12,325
```

**Cada diretório é a saída de uma etapa e a entrada da seguinte.** É isso que torna o pipeline
legível: quando o relatório parece errado, a pergunta "qual etapa?" tem uma resposta que você abre
num editor de texto. A próxima seção quebra uma etapa de propósito, e a seguinte usa os diretórios
para rastrear um número de volta até o aplicativo.
