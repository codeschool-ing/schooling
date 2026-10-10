---
title: Preços, e notas
version: 2
---

## Ensinando a ele o preço do modelo

O Langfuse dá preço a uma geração comparando o nome do modelo com uma tabela de **definições de
modelo**, cada uma com um preço por token de entrada e de saída e uma data de início. Ele vem com
definições para os modelos dos fornecedores e nenhuma para um modelo que roda na sua máquina. O
`lf_prices.py` as cria a partir do `prices.json` da aula 3, os dois preços do `llama3.2:3b` com as
suas datas:

```python
"""lf_prices.py: llama3.2:3b's two prices from prices.json, as model definitions in Langfuse."""
import base64
import json
import os
import urllib.request

KEY = f"{os.environ['LANGFUSE_PUBLIC_KEY']}:{os.environ['LANGFUSE_SECRET_KEY']}"
for i, p in enumerate(json.load(open("prices.json"))["models"]["llama3.2:3b"]):
    name = "llama3.2:3b" if i == 0 else f"llama3.2:3b from {p['from']}"   # a model's name is unique in a project
    body = {"modelName": name, "matchPattern": r"(?i)^llama3\.2:3b$", "startDate": p["from"] + "T00:00:00-03:00",
            "unit": "TOKENS", "inputPrice": float(p["input"]) / 1e6, "outputPrice": float(p["output"]) / 1e6}
    request = urllib.request.Request(os.environ["LANGFUSE_BASE_URL"] + "/api/public/models", data=json.dumps(body).encode(),
                                     headers={"Content-Type": "application/json",
                                              "Authorization": "Basic " + base64.b64encode(KEY.encode()).decode()})
    m = json.load(urllib.request.urlopen(request))
    print("model", m["modelName"], "from", m["startDate"], "input", m["inputPrice"], "output", m["outputPrice"])
```

Por que dois nomes: o nome de um modelo é único num projeto do Langfuse, e mandar o segundo preço
com o mesmo nome falha com `Model name ... already exists in project`. Então um segundo preço para o
mesmo modelo é uma segunda definição com outro nome, casando com o mesmo padrão, com uma data de
início posterior.

Depois a sexta é reproduzida, com o `spans.jsonl` esvaziado antes para guardar só a sexta:

```
ana@dev:~/obs$ python lf_prices.py
model llama3.2:3b from 2026-01-01T03:00:00.000Z input 2e-06 output 8e-06
model llama3.2:3b from 2026-09-30 from 2026-09-30T03:00:00.000Z input 1.5e-06 output 6e-06
ana@dev:~/obs$ export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=$LANGFUSE_BASE_URL/api/public/otel/v1/traces OTEL_EXPORTER_OTLP_TRACES_HEADERS="Authorization=Basic $(printf %s $LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY | base64 -w0)"; rm spans.jsonl; python replay.py --from 2026-10-02 --to 2026-10-03 --processor lf_names:LangfuseNames
replayed 46 requests from data/traffic.jsonl: 48 asked, 0 failed, 14 feedback events
ana@dev:~/obs$ python lf.py daily
2026-10-05    3 traces cost 0
2026-10-04   35 traces cost 0
2026-10-03   37 traces cost 0.001884
2026-10-02   43 traces cost 0.014011
ana@dev:~/obs$ python -c "import costs; print(sum(r[\"cost\"] for r in costs.requests()))"
0.01590828
```

Três coisas para ler aí.

**Sábado e domingo continuam custando 0.** Eles foram mandados antes de os preços existirem, e o
Langfuse calcula o custo **quando recebe uma geração**, não quando ela é lida. Acrescentar um preço
depois não reprecifica o que já está guardado. É o contrário do `costs.py`, que mantém tokens e preços
separados e multiplica quando lhe pedem, exatamente por isso: na aula 3 o preço de 30 de setembro pôde
ser aplicado a todo pedido depois dele, quando quer que tenha sido cadastrado.

**O custo da sexta está em dois dias**, 2 e 3 de outubro, porque as datas são UTC: a noite de sexta da
loja depois das nove já é sábado em UTC. Um relatório por dia desta API e um do `bill.py` vão discordar
a cada meia-noite, e os dois estão certos.

**Os totais batem, quase.** Os dois dias do Langfuse somam 0,015895 dólar; o `costs.py` sobre os
mesmos spans diz 0,01590828. Quase toda a diferença são os embeddings: os 639 tokens de embedding da
sexta, a 0,02 por milhão, dão 0,00001278, que o `costs.py` conta e para os quais o Langfuse não
recebeu preço, e o último meio milionésimo é o `lf.py` arredondando cada dia em seis casas. Dois
sistemas calculando a mesma conta são uma boa conferência dos dois, e a diferença diz o nome do que
falta a um deles.

## Notas

Uma **nota** (score) no Langfuse é um valor ligado a um trace, ou a uma observação dele: um número, uma
categoria, um booleano, um texto, cada um com um nome. Polegares são a primeira óbvia. Todo polegar do
`feedback.jsonl` já leva o id do seu trace, e os ids de trace do OpenTelemetry são os ids de trace do
Langfuse, então mandá-los é um laço:

```python
"""lf_scores.py: every thumb in feedback.jsonl, sent to Langfuse as a score on the trace it is about."""
import json

from langfuse import get_client

langfuse = get_client()
sent = 0
for f in map(json.loads, open("feedback.jsonl")):
    if f["kind"] == "thumbs":
        langfuse.create_score(trace_id=f["trace"], name="thumbs", value=1 if f["value"] == "up" else 0,
                              data_type="BOOLEAN")
        sent += 1
langfuse.flush()
print(sent, "scores sent")
```

```
ana@dev:~/obs$ python lf_scores.py
20 scores sent
ana@dev:~/obs$ python lf.py scores thumbs
20 scores named thumbs: 17 of value 1, 3 of value 0
```

Vinte polegares dos três dias reproduzidos, dezessete para cima e três para baixo, cada um agora no
trace que julga. A partir daqui uma tela pode filtrar traces por nota, desenhar a parcela de
polegares para baixo por dia, ou listar os traces com polegar para baixo e ainda sem nota de juiz. O
juiz da aula 9 guarda os vereditos também por id de trace, então eles poderiam ser mandados do mesmo
jeito como uma segunda nota, e o motivo de um polegar e um veredicto poderem ficar lado a lado é que
os dois foram ligados por id desde o começo.