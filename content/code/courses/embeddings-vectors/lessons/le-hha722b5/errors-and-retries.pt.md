---
title: Erros e novas tentativas
version: 1
---

Uma API é um serviço que outra pessoa opera, e algumas das recusas dela são sobre o momento, não
sobre a requisição. A mais comum é **429, Too Many Requests** (requisições demais): a conta mandou
mais requisições ou tokens por minuto do que o limite permite. Não há nada de errado com a
requisição; ela dá certo se for mandada de novo um pouco depois.

A ideia errada é embrulhar cada chamada num laço de repetição seu. O SDK `openai` já repete, e um
segundo laço em volta dele multiplica as tentativas: três suas vezes três dele são nove requisições
para um texto, todas caindo num provedor que acabou de dizer que está ocupado.

## Vendo o SDK tentar de novo

O labembed tem um interruptor que o serviço de verdade não tem: `POST /lab/config` com
`{"fail": 2}` faz ele recusar as duas próximas requisições com 429, então um limite de uso pode ser
produzido na hora.

```schooling-example
{
  "language": "python",
  "file": "retry.py",
  "parts": [
    {
      "code": "import time\nimport httpx\nimport openai\nfrom openai import OpenAI\n\nclient = OpenAI()\nprint(\"max_retries\", client.max_retries, \" timeout\", client.timeout)\n\n\ndef fail_next(n):  # the lab's switch, not OpenAI's\n    httpx.post(\"http://127.0.0.1:8500/lab/config\", json={\"fail\": n, \"status\": 429})",
      "note": "Os padrões do cliente e uma função que manda o labembed responder 429 às próximas requisições, como um provedor faz quando você manda demais, rápido demais."
    },
    {
      "code": "fail_next(2)\nstart = time.monotonic()\nr = client.embeddings.create(model=\"lab-minilm\", input=\"When your refund arrives\")\nprint(f\"answered after {time.monotonic() - start:.1f} s with {len(r.data[0].embedding)} numbers\")",
      "note": "Duas falhas, depois uma resposta. O SDK tenta de novo sozinho; o programa só vê o sucesso, um pouco atrasado."
    },
    {
      "code": "fail_next(3)\nstart = time.monotonic()\ntry:\n    client.embeddings.create(model=\"lab-minilm\", input=\"When your refund arrives\")\nexcept openai.RateLimitError as e:\n    print(f\"gave up after {time.monotonic() - start:.1f} s:\", type(e).__name__, e.status_code)",
      "note": "Três falhas: a primeira tentativa e as duas repetições são recusadas, e o SDK lança `RateLimitError`."
    },
    {
      "code": "try:\n    client.embeddings.create(model=\"lab-minilm\", input=\"\")\nexcept openai.BadRequestError as e:\n    print(\"not retried:\", type(e).__name__, e.status_code)",
      "note": "Uma string vazia é um 400. Pedir de novo não conserta a requisição, então o SDK lança o erro na hora."
    }
  ]
}
```

```
ana@lab:~/emb$ python retry.py
max_retries 2  timeout Timeout(connect=5.0, read=600, write=600, pool=600)
answered after 2.2 s with 384 numbers
gave up after 2.0 s: RateLimitError 429
not retried: BadRequestError 400
ana@lab:~/emb$ jq -c '{at, status}' /var/log/labembed/requests.jsonl | tail -n 7
{"at":"2026-10-05T14:19:34-03:00","status":429}
{"at":"2026-10-05T14:19:35-03:00","status":429}
{"at":"2026-10-05T14:19:36-03:00","status":200}
{"at":"2026-10-05T14:19:36-03:00","status":429}
{"at":"2026-10-05T14:19:37-03:00","status":429}
{"at":"2026-10-05T14:19:38-03:00","status":429}
{"at":"2026-10-05T14:19:38-03:00","status":400}
```

A primeira linha são os padrões do cliente: **`max_retries` 2**, e um tempo limite de 600 segundos
para ler a resposta e 5 para conectar.

Com duas falhas na fila, a chamada **voltou normalmente**. O programa nunca viu os 429; só demorou
mais, porque o SDK esperou entre as tentativas. O labembed manda um cabeçalho `retry-after: 1` com
cada 429, como fazem os provedores, e o SDK esperou mais ou menos isso a cada vez. O registro mostra
as três requisições por trás de uma chamada.

Com três falhas na fila, a primeira tentativa e as duas repetições foram recusadas, e só então o
SDK desistiu e lançou **`RateLimitError`**. Essa é a exceção a tratar no seu código, e tratá-la
quer dizer desacelerar: esperar, mandar menos por minuto ou pôr o trabalho numa fila para depois,
não uma quarta tentativa imediata.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 530\" role=\"img\" aria-label=\"Um diagrama de sequência de duas chamadas a embeddings.create, com o programa à esquerda e o labembed à direita, o tempo correndo para baixo. Primeira chamada: o SDK manda uma requisição às 14:19:34 e recebe 429, espera, manda de novo às 14:19:35 e recebe 429, espera, manda uma terceira vez às 14:19:36 e recebe 200; o programa recebe o vetor depois de 2.2 segundos e nunca vê as recusas. Segunda chamada: três requisições às 14:19:36, 14:19:37 e 14:19:38, todas recusadas com 429; depois de 2.0 segundos o SDK lança RateLimitError.\"><defs><marker id=\"seqpt-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"seqpt-ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"seqpt-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"seqpt-ah3\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"140\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">seu programa</text><path d=\"M90 44 L90 520\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"260\" y=\"14\" width=\"140\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">SDK openai</text><path d=\"M330 44 L330 520\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"530\" y=\"14\" width=\"140\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">labembed</text><path d=\"M600 44 L600 520\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">duas falhas na fila</text><path d=\"M90 86 L326 86\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah0)\"></path><text x=\"210\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">embeddings.create(...)</text><path d=\"M330 104 L596 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah1)\"></path><text x=\"608\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14:19:34</text><path d=\"M600 126 L334 126\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah2)\"></path><text x=\"465\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">429</text><rect x=\"290\" y=\"140\" width=\"80\" height=\"20\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">espera</text><path d=\"M330 170 L596 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah1)\"></path><text x=\"608\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14:19:35</text><path d=\"M600 192 L334 192\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah2)\"></path><text x=\"465\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">429</text><rect x=\"290\" y=\"206\" width=\"80\" height=\"20\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">espera</text><path d=\"M330 236 L596 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah1)\"></path><text x=\"608\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14:19:36</text><path d=\"M600 258 L334 258\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah3)\"></path><text x=\"465\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">200</text><path d=\"M330 272 L94 272\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah3)\"></path><text x=\"210\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">um vetor, 2.2 s depois</text><text x=\"20\" y=\"306\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">três falhas na fila</text><path d=\"M90 322 L326 322\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah0)\"></path><text x=\"210\" y=\"313\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">embeddings.create(...)</text><path d=\"M330 340 L596 340\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah1)\"></path><text x=\"608\" y=\"340\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14:19:36</text><path d=\"M600 362 L334 362\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah2)\"></path><text x=\"465\" y=\"353\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">429</text><rect x=\"290\" y=\"376\" width=\"80\" height=\"20\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"386\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">espera</text><path d=\"M330 406 L596 406\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah1)\"></path><text x=\"608\" y=\"406\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14:19:37</text><path d=\"M600 428 L334 428\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah2)\"></path><text x=\"465\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">429</text><rect x=\"290\" y=\"442\" width=\"80\" height=\"20\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"452\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">espera</text><path d=\"M330 472 L596 472\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah1)\"></path><text x=\"608\" y=\"472\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14:19:38</text><path d=\"M600 494 L334 494\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah2)\"></path><text x=\"465\" y=\"485\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">429</text><path d=\"M330 508 L94 508\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqpt-ah2)\"></path><text x=\"210\" y=\"499\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">RateLimitError, 2.0 s depois</text></svg>", "caption": "Por trás de uma chamada, o SDK manda até três requisições. Com duas falhas na fila o programa recebe um vetor e nunca fica sabendo dos 429; com três, o SDK desiste e lança o erro. Os horários à direita são do registro do labembed.", "same": ["labembed"]}
```

A string vazia foi recusada com 400 e o erro veio na hora, depois de uma requisição só. O SDK da
OpenAI documenta quais falhas ele repete: erros de conexão, 408, 409, 429 e qualquer 5xx. Um 400,
401 ou 404 diz que a própria requisição está errada, e mandá-la de novo daria a mesma resposta.

## Ajustes que vale escolher

Os dois padrões podem ser mudados por cliente ou por chamada, com
`OpenAI(max_retries=5, timeout=30)` ou `client.with_options(...)`. Dois casos em que você mudaria:

- **Um processo em segundo plano** que transforma um acervo em vetores durante a noite aguenta mais
  tentativas e esperas mais longas; falhar às três da manhã por um limite de uso passageiro
  desperdiça a execução inteira.
- **Uma caixa de busca** não aguenta. Um usuário está esperando o vetor da consulta, e dez minutos
  de tempo limite de leitura não é uma espera que alguém faça. Um tempo limite curto e poucas
  tentativas, com uma mensagem para o usuário, é melhor que uma página travada.

## Seguro repetir

Repetir só é seguro quando mandar uma requisição duas vezes não faz mal. Para embeddings não faz
nenhum: a requisição não muda nada no servidor, e a aula 1 mostrou que o mesmo texto pelo mesmo
modelo dá o mesmo vetor. Uma chamada de embedding repetida que dá certo duas vezes, porque a
primeira resposta se perdeu na volta, custa os tokens duas vezes e nada mais. Isso não vale para
toda API, e é por isso que o hábito do SDK de repetir por conta própria não faz mal aqui.
