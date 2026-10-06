---
title: Os mesmos spans, mandados para o Langfuse
version: 1
---

O Langfuse recebe traces do OpenTelemetry em `/api/public/otel`, autenticados com as duas chaves do
projeto. Então o assistente não precisa de **nenhum código novo** para usá-lo: o `telemetry.py` da aula 1
já acrescenta um exportador OTLP sempre que `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` está definida, e o SDK
lê os cabeçalhos de `OTEL_EXPORTER_OTLP_TRACES_HEADERS`. Duas variáveis de ambiente, e a reprodução do
domingo vai para o arquivo e para o Langfuse:

```
ana@lab:~/obs$ export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=$LANGFUSE_HOST/api/public/otel/v1/traces OTEL_EXPORTER_OTLP_TRACES_HEADERS="Authorization=Basic $(printf %s $LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY | base64 -w0)"; python replay.py --from 2026-10-04 --to 2026-10-05
replayed 118 requests from data/traffic.jsonl: 143 asked, 0 failed, 54 feedback events
```

O `lf.py` faz algumas perguntas à API pública do Langfuse e imprime uma linha por resposta, para que um
terminal mostre o que uma tela mostraria:

```python
"""lf.py: a few questions to Langfuse's public API, one line per answer."""
import base64
import json
import os
import sys
import urllib.request

KEY = f"{os.environ['LANGFUSE_PUBLIC_KEY']}:{os.environ['LANGFUSE_SECRET_KEY']}"
AUTH = {"Authorization": "Basic " + base64.b64encode(KEY.encode()).decode()}


def get(path):
    request = urllib.request.Request(os.environ["LANGFUSE_HOST"] + path, headers=AUTH)
    return json.load(urllib.request.urlopen(request))


what = sys.argv[1]
if what == "traces":   # traces DAY N: the first N traces of DAY, a local date
    day = f"fromTimestamp={sys.argv[2]}T03:00:00Z&toTimestamp={sys.argv[2]}T23:59:59Z"
    for t in get(f"/api/public/traces?{day}&limit={sys.argv[3]}&orderBy=timestamp.asc")["data"]:
        print(t["timestamp"][:19], t["id"][:8], t["name"], "user", t["userId"], "session", t["sessionId"],
              "cost", t["totalCost"], "input", repr(t["input"]))
elif what == "observations":   # observations TRACE: every observation of one trace, by its full id
    trace = sys.argv[2]
    for o in sorted(get(f"/api/public/observations?traceId={trace}")["data"], key=lambda o: o["startTime"]):
        print(f"{o['type']:10} {o['name']:16} model {o['model']}  usage {o['usageDetails']}  cost {o['calculatedTotalCost']}")
elif what == "daily":
    for d in get("/api/public/metrics/daily")["data"]:
        print(d["date"], f"{d['countTraces']:4} traces", "cost", round(d["totalCost"], 6))
elif what == "scores":
    values = [s["value"] for s in get(f"/api/public/v2/scores?name={sys.argv[2]}&limit=100")["data"]]
    print(f"{len(values)} scores named {sys.argv[2]}: {values.count(1)} of value 1, {values.count(0)} of value 0")
```

```
ana@lab:~/obs$ python lf.py traces 2026-10-04 1
2026-10-04T03:03:25 cfac41be ask user None session s1010 cost 0 input None
ana@lab:~/obs$ python lf.py observations cfac41be15f2ff86f623946c9fb05cdd
EMBEDDING  embed            model lab-minilm  usage {'input': 9, 'total': 9}  cost 0
GENERATION ask              model extract-1  usage {}  cost 0
SPAN       search           model None  usage {}  cost 0
GENERATION chat extract-1   model extract-1  usage {'input': 336, 'output': 69, 'total': 405}  cost 0
SPAN       generate         model None  usage {}  cost 0
SPAN       check_citations  model None  usage {}  cost 0
```

O trace chegou, com as suas observações: a palavra do Langfuse para spans. O horário está em UTC, três
horas à frente de São Paulo, então 03:03 na tela são três minutos depois da meia-noite na loja. E o
Langfuse leu os nossos nomes e decidiu o que cada span é.

**O embedding virou um `EMBEDDING`, e a chamada ao modelo uma `GENERATION`**, com as contagens de tokens
lidas de `gen_ai.usage.*`. É a convenção da aula 1 dando retorno: ninguém disse ao Langfuse o que esses
atributos significam.

**O `ask` também virou uma `GENERATION`, sem uso.** O span raiz leva `gen_ai.request.model` porque a aula
1 pôs nele o modelo da versão, e um span com um modelo parece uma chamada a modelo para uma ferramenta
que lê a convenção ao pé da letra. Um painel que contasse gerações contaria agora cada pedido duas
vezes.

**A sessão foi achada, e o usuário não.** `session.id` é um nome que o Langfuse lê; `user.hash`, que a
aula 2 escolheu como o nome da convenção semântica para um pseudônimo, não está entre os nomes que ele
procura. Nem `app.question`, então o trace não tem entrada.

**E todo custo é 0.** O Langfuse dá preço a uma geração a partir de uma tabela de modelos que conhece,
e o extract-1 não é um modelo de que ele tenha ouvido falar.

Nada disso é defeito de nenhum dos dois programas. É o que acontece sempre que dois softwares se
encontram por uma convenção ainda nova: cada um lê os nomes que conhece, e os que não conhece são
guardados, no caso do Langfuse como metadados, e não servem para nada. A próxima seção acrescenta os
nomes.
