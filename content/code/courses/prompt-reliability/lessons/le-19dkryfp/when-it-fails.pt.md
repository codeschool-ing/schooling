---
title: Quando uma resposta não é JSON válido
version: 2
---

Uma resposta em quarenta não era JSON válido com todos os prompts desta aula que pedem JSON. Com mil
mensagens por dia, essa taxa dá umas vinte e cinco respostas por dia que o roteador não consegue
ler. **O programa consumidor precisa de uma decisão escrita para esse caso antes que ele
aconteça**, porque a alternativa é o que o código fizer por acidente.

Há três decisões razoáveis e uma ruim.

## Tentar de novo

Chamar o modelo de novo com a mesma mensagem. Isso só funciona se a segunda chamada puder voltar
diferente, e com temperatura 0 não pode. `--samples 3` pergunta três vezes, com três sementes:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/retry.jsonl --samples 3
120 calls, prompt 651820d7, llama3.2:3b, written to runs/retry.jsonl
ana@lab:~/triage$ pl check runs/retry.jsonl --failures | grep json
json        117     3
t38    json      not a JSON object
t38#1  json      not a JSON object
t38#2  json      not a JSON object
```

O `t38` falha as três vezes, com o mesmo objeto quebrado. Com temperatura 0 o modelo sempre pega o
próximo token mais provável, então a semente não tem entre o que escolher, e perguntar de novo é
fazer a mesma pergunta e receber a mesma resposta. Suba a temperatura e as tiragens diferem:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/warm.jsonl --samples 3 --set temperature=0.8
120 calls, prompt 651820d7, llama3.2:3b, written to runs/warm.jsonl
ana@lab:~/triage$ pl check runs/warm.jsonl --failures | grep json
json        118     2
t13#2  json      not a JSON object
t17#2  json      not a JSON object
ana@lab:~/triage$ pl check runs/warm.jsonl
check      pass  fail
json        118     2
fields      118     2
labels      117     3
category     93    27
urgency      58    62
all          58    62
```

A 0,8, o `t38` foi JSON válido nas três tentativas, e duas outras respostas, `t13` e `t17`,
quebraram na terceira. As falhas mudaram de lugar; não foram embora. E olhe a última linha: 58
aprovações em 120, contra 19 em 40 com temperatura 0, mais ou menos a mesma taxa com mais coisa
deixada ao acaso. A aula 8 trata do que a temperatura faz com os rótulos.

Então **tentar de novo só é uma chance nova quando algo muda**: a tiragem, o prompt ou o modelo.
Uma segunda chamada que inclui a resposta que falhou e a reclamação do interpretador é um prompt
diferente, e é a nova tentativa que vale tentar primeiro. Seja o que for que você escolher, limite
o número de tentativas, e conte-as.

## Recorrer a outro caminho

Tenha um caminho que não precise da resposta do modelo. Na triagem, é a fila sem classificação, onde
uma pessoa lê a mensagem. **Uma mensagem na fila errada é pior que uma mensagem em fila nenhuma**: a
segunda está atrasada, e a primeira está atrasada e ainda perdida no meio das mensagens em que outra
pessoa está trabalhando.

## Mandar para uma pessoa

Para uma resposta que é JSON válido mas falha em `labels`, uma categoria de que ninguém ouviu falar,
o destino certo é o mesmo. Mande a resposta crua com a mensagem, para que a pessoa veja o que deu
errado e para que o caso possa ser acrescentado ao conjunto de teste depois.

## Nunca adivinhar

A decisão ruim é a que parece esperta: procurar `billing` ou `high` no texto ininterpretável e agir
de acordo com o que achar. Ela transforma toda falha de formato numa decisão de conteúdo que ninguém
conferiu, e é o interpretador tolerante da seção anterior levado para a produção, onde nada conta o
que ele faz.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O que o programa consumidor faz com uma resposta, da esquerda para a direita. A resposta passa por uma etapa de reparo que tira um bloco de código e conta quantas vezes faz isso, depois por uma análise rigorosa, depois pelas verificações fields e labels, e é encaminhada pela categoria. Uma resposta que falha na análise rigorosa, ou em fields ou labels, desce para a fila de não classificados, onde uma pessoa lê a mensagem. Nada adivinha.\"><defs><marker id=\"l03a-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Uma resposta, pelo programa consumidor</text><rect x=\"20\" y=\"44\" width=\"100\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">resposta</text><path d=\"M122 70.0 L146 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><rect x=\"150\" y=\"44\" width=\"130\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">etapa de reparo</text><text x=\"215.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">contada</text><path d=\"M282 70.0 L306 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><rect x=\"310\" y=\"44\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">análise rigorosa</text><path d=\"M432 70.0 L456 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><rect x=\"460\" y=\"44\" width=\"110\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"515.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fields, labels</text><path d=\"M572 70.0 L596 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><rect x=\"600\" y=\"44\" width=\"100\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">encaminhar</text><text x=\"650.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pela categoria</text><rect x=\"300\" y=\"160\" width=\"280\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fila de não classificados: uma pessoa lê</text><path d=\"M370 98 L370 156\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><text x=\"378\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">falha</text><path d=\"M515 98 L515 156\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><text x=\"523\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">falha</text></svg>", "caption": "Todo caminho termina num lugar decidido. A etapa de reparo é parte do programa e é contada; a medição da bancada continua rigorosa e nunca a vê."}
```

## Modos de saída estruturada

As APIs de vários provedores oferecem um modo JSON ou um modo de saída estruturada, em que a
decodificação do modelo é restringida para que a resposta seja JSON válido, ou siga um esquema que
você fornece. O Ollama tem um: o campo `format` aceita um esquema JSON. Este programa manda um caso
com o esquema da resposta deste curso. Salve-o como `schema.py`:

```python
"""schema: one case through Ollama's structured-output mode, which constrains
the reply to a JSON schema while the model writes it."""
import json
import sys
import urllib.request

from pl import DEFAULTS, LABELS, OLLAMA, read_jsonl, read_prompt, render

SCHEMA = {"type": "object", "required": ["category", "urgency", "summary"],
          "additionalProperties": False,
          "properties": {"category": {"enum": LABELS["category"]},
                         "urgency": {"enum": LABELS["urgency"]},
                         "summary": {"type": "string"}}}

prompt, cases, case_id = sys.argv[1:4]
case = next(c for c in read_jsonl(cases) if c["id"] == case_id)
_, template = read_prompt(prompt)
body = {"model": DEFAULTS["model"], "stream": False, "format": SCHEMA,
        "options": {"temperature": 0, "seed": 1},
        "messages": [{"role": "user", "content": render(template, {"message": case["message"]})}]}
req = urllib.request.Request(OLLAMA + "/api/chat", json.dumps(body).encode(),
                             {"Content-Type": "application/json"})
print(json.load(urllib.request.urlopen(req))["message"]["content"])
```

```
ana@lab:~/triage$ python3 schema.py prompts/v2-json.txt cases/dev.jsonl t38
{"category": "returns", "urgency": "high", "summary": "Ebook won't open on reader, needs replacement or refund"}
ana@lab:~/triage$ python3 schema.py prompts/v2-json.txt cases/dev.jsonl t17
{"category": "delivery", "urgency": "high", "summary": "Order has not arrived ten days after dispatch and is needed for a birthday on Saturday"}
```

O `t38` volta inteiro, apóstrofo e tudo, porque o decodificador não podia fechar o texto antes da
hora: um token que quebraria o esquema nunca foi candidato. O `t17` volta palavra por palavra como
voltou sem o esquema. **Ele restringe o formato e não a resposta.** Uma resposta que é JSON perfeito
com a categoria errada ainda passa em todas as verificações que o programa pode rodar em produção,
e é por isso que o conjunto de teste e os rótulos dados por uma pessoa continuam. A aula 6 mostra o
outro jeito de uma resposta não ser JSON válido, cortada no limite de saída, e nenhum modo de
formato consegue completar um objeto que o modelo foi impedido de terminar.
