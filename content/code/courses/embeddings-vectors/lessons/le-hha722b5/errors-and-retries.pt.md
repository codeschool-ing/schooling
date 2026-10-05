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
