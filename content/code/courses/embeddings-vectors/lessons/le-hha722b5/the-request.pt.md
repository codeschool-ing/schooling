---
title: A requisição
version: 1
---

Todo vetor até aqui veio de um modelo rodando no notebook da Ana. Muitas equipes não rodam o
próprio: mandam texto para um provedor por HTTP, recebem vetores de volta e pagam por token. Esta
aula chama o endpoint de embeddings da OpenAI, cujo formato outros provedores copiam, com a
biblioteca Python da própria OpenAI, `openai`.

## Quem responde nesta máquina

**O servidor desta aula não é a OpenAI.** Nenhuma API de provedor estava ao alcance da máquina em
que o curso foi gravado, e uma chave de API é uma conta que um curso não pode distribuir. Então o
laboratório roda o **labembed**, um pequeno servidor escrito para o curso (`lab/labembed.py`), em
`127.0.0.1:8500`. Ele responde à requisição `/v1/embeddings` da OpenAI no formato da OpenAI, de
perto o bastante para que o SDK de verdade aceite as respostas sem modificação. Os vetores são
reais: vêm do all-MiniLM-L6-v2 e do WordLlama, os dois modelos que as aulas anteriores rodaram,
servidos com nomes do próprio laboratório, `lab-minilm` e `lab-wordllama`.

O SDK é apontado para ele por duas variáveis de ambiente, as que ele mesmo lê:

```
ana@lab:~/emb$ env | grep ^OPENAI
OPENAI_API_KEY=lab-openai-key-0001
OPENAI_BASE_URL=http://127.0.0.1:8500/v1
```

Contra o serviço de verdade, você apagaria `OPENAI_BASE_URL`, poria a sua chave e escreveria
`text-embedding-3-small` onde esta aula escreve `lab-minilm`. Nada mais no código muda. O que muda
é tudo o que o laboratório não consegue imitar: os preços da OpenAI, os limites de uso, a latência
e os vetores do próprio modelo. Onde esta aula fala disso, ela cita a documentação da OpenAI ou a
planilha de preços e diz que está citando.

## Uma chamada

```schooling-example
{
  "language": "python",
  "file": "first.py",
  "parts": [
    {
      "code": "from openai import OpenAI\n\nclient = OpenAI()",
      "note": "`OpenAI()` lê `OPENAI_API_KEY` e `OPENAI_BASE_URL` do ambiente. Nesta máquina a URL base aponta para o labembed; sem ela, o SDK fala com `https://api.openai.com/v1`."
    },
    {
      "code": "response = client.embeddings.create(\n    model=\"lab-minilm\",\n    input=\"When your refund arrives\",\n)",
      "note": "Uma chamada, dois argumentos: qual modelo e o texto. `input` aceita uma string ou uma lista de strings."
    },
    {
      "code": "vector = response.data[0].embedding\nprint(type(vector).__name__, len(vector), [round(x, 4) for x in vector[:4]])\nprint(response.usage)",
      "note": "O vetor está em `data[0].embedding`, uma lista Python comum de floats. `usage` diz por quantos tokens a requisição foi cobrada."
    }
  ]
}
```

```
ana@lab:~/emb$ python first.py
list 384 [-0.0865, -0.0142, -0.0045, 0.0386]
Usage(prompt_tokens=5, total_tokens=5)
ana@lab:~/emb$ tail -n 1 /var/log/labembed/requests.jsonl
{"at": "2026-10-05T14:19:26-03:00", "path": "/v1/embeddings", "provider": "openai", "model": "lab-minilm", "inputs": 1, "tokens": 5, "dims": 384, "encoding_format": "base64", "status": 200}
```

Os quatro primeiros números são os que a aula 1 imprimiu para o mesmo título, com o mesmo modelo,
arredondados do mesmo jeito. Um vetor vindo de uma API é o mesmo objeto que um vetor de um modelo
local: 384 floats, comprimento 1, comparável com outros vetores daquele modelo e de nenhum outro.

A última linha da transcrição é o registro que o próprio labembed faz da requisição, uma linha JSON
por chamada. Ele guarda o que o SDK mandou, e um dos campos, `encoding_format`, é um detalhe ao qual
a próxima seção volta.

## A mesma requisição sem o SDK

O SDK é uma comodidade em cima de uma requisição HTTP, e vale vê-la sem nada em volta. É um `POST`
com a chave num cabeçalho `Authorization: Bearer` e um corpo JSON:

```json
{"model": "lab-minilm", "input": "When your refund arrives"}
```

```
ana@lab:~/emb$ curl -s $OPENAI_BASE_URL/embeddings -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" -d @request.json | cut -c 1-150
{"object": "list", "data": [{"object": "embedding", "index": 0, "embedding": [-0.08653447031974792, -0.014246996492147446, -0.004477363079786301, 0.03
```

Esse é o protocolo inteiro: um nome de modelo, uma entrada e uma lista de números de volta.
Qualquer linguagem com um cliente HTTP consegue chamá-lo, e é por isso que tantos outros provedores
copiam o formato; a aula 10 encontra um que copia.

## Quando a requisição é recusada

Duas recusas aparecem logo no primeiro dia: uma chave errada e um nome de modelo que o servidor não
conhece.

```python
import openai
from openai import OpenAI

attempts = [
    (OpenAI(api_key="sk-not-the-lab-key"), "lab-minilm"),
    (OpenAI(), "text-embedding-3-small"),
]
for client, model in attempts:
    try:
        client.embeddings.create(model=model, input="When your refund arrives")
    except openai.APIStatusError as e:
        print(type(e).__name__, e.status_code, e.code)
        print("   ", e.body["message"])
```

```
ana@lab:~/emb$ python refused.py
AuthenticationError 401 invalid_api_key
    Incorrect API key provided.
NotFoundError 404 model_not_found
    The model `text-embedding-3-small` does not exist or you do not have access to it. This lab serves lab-minilm and lab-wordllama.
```

O SDK transforma cada status HTTP numa classe de exceção própria, `AuthenticationError` para 401 e
`NotFoundError` para 404, e guarda o JSON do servidor em `e.body`. Repare na segunda: o labembed
recusa `text-embedding-3-small` **de propósito**, para que nada neste curso possa fazer um modelo do
laboratório passar pelo da OpenAI. Contra o serviço de verdade, esse é o nome a usar, e os nomes do
laboratório não significam nada lá.
