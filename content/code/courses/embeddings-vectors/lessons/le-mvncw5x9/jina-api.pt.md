---
title: A API de embeddings da Jina
version: 1
---

A aula 7 chamou o endpoint de embeddings da OpenAI e a aula 8 chamou os do Gemini e da Cohere, cada
um pelo SDK do próprio fornecedor. O endpoint da Jina AI não precisa de SDK próprio, porque **ele
copia o formato da OpenAI**. A requisição é um `POST` em `/v1/embeddings` com um token bearer e um
corpo com `model` e `input`; na resposta, `data[i].embedding` traz os vetores e `usage` conta os
tokens. O que a Jina acrescenta são alguns campos próprios no mesmo corpo, e um deles muda o vetor.

O programa abaixo chama esse endpoint com o `httpx`, o cliente HTTP que o pacote `openai` já
trouxe. O endereço e a chave vêm do ambiente. Nesta máquina, `JINA_BASE_URL` aponta para o
**labembed**, o servidor substituto do curso em 127.0.0.1:8500. Ele responde ao formato de
requisição da Jina com vetores dos dois modelos que o laboratório roda, com nomes de modelo do
próprio laboratório, por isso o modelo aqui é `lab-wordllama`. Contra o serviço de verdade, o
endereço seria `https://api.jina.ai/v1`, a chave seria uma do painel da Jina e o modelo seria um
dos da Jina, como `jina-embeddings-v3`. Nada mais no programa muda.

```schooling-example
{
  "language": "python",
  "file": "jina.py",
  "parts": [
    {
      "code": "import os\nimport httpx\n\nurl = os.environ[\"JINA_BASE_URL\"] + \"/embeddings\"\nheaders = {\"Authorization\": \"Bearer \" + os.environ[\"JINA_API_KEY\"]}\n\ndef jina(texts, task, dimensions=None):\n    body = {\"model\": \"lab-wordllama\", \"task\": task, \"input\": texts}\n    if dimensions:\n        body[\"dimensions\"] = dimensions\n    return httpx.post(url, headers=headers, json=body)",
      "note": "O endereço e a chave vêm do ambiente, então o mesmo arquivo fala com o labembed aqui e com api.jina.ai em outro lugar. `jina()` monta o corpo que a Jina documenta: um modelo, uma tarefa, os textos e `dimensions` só quando alguém pede."
    },
    {
      "code": "r = jina([\"how do I get my money back\"], \"retrieval.query\", dimensions=64)\nd = r.json()\nprint(r.status_code, len(d[\"data\"][0][\"embedding\"]), d[\"usage\"])",
      "note": "Uma pergunta transformada em vetor como consulta e cortada em 64 dimensões. Imprima o status, o tamanho do vetor e os tokens contados."
    },
    {
      "code": "text = [\"When your refund arrives\"]\nq = jina(text, \"retrieval.query\").json()[\"data\"][0][\"embedding\"]\np = jina(text, \"retrieval.passage\").json()[\"data\"][0][\"embedding\"]\nprint(\"query and passage identical:\", q == p)",
      "note": "Um título transformado em vetor duas vezes, uma como consulta e outra como trecho, e os dois vetores comparados número a número."
    },
    {
      "code": "r = jina(text, \"retrieval.document\")\nprint(r.status_code, r.json()[\"error\"][\"message\"])",
      "note": "Um nome de tarefa que a Jina não tem. Imprima o status e a mensagem que volta."
    }
  ]
}
```

```
ana@lab:~/emb$ python jina.py
200 64 {'prompt_tokens': 7, 'total_tokens': 7}
query and passage identical: True
422 task must be one of ['classification', 'retrieval.passage', 'retrieval.query', 'separation', 'text-matching']
```

## Três campos que vale conhecer

**`dimensions` pede um vetor mais curto.** A primeira linha mostra 64 números onde o WordLlama
devolve 256. Funciona pelo motivo que a aula 7 deu para o parâmetro de mesmo nome da OpenAI: o
modelo foi treinado para que os primeiros números do vetor continuem funcionando sozinhos. A Jina
documenta o mesmo para o jina-embeddings-v3, cujo vetor completo tem 1024 números.

**`task` diz para que serve o texto.** A Jina documenta cinco valores para o jina-embeddings-v3:
`retrieval.query` para uma consulta de busca, `retrieval.passage` para o texto que a busca deve
encontrar, `text-matching` para comparar dois textos em pé de igualdade, `classification`, e
`separation` para agrupar textos em clusters. O modelo carrega um pequeno conjunto de pesos extras
por tarefa e usa o conjunto que a tarefa indica, então um mesmo texto recebe um vetor como consulta
e outro como trecho. É a busca assimétrica da aula 8 com os nomes da Jina: transforme os artigos de
ajuda em vetores com `retrieval.passage` e a pergunta da cliente com `retrieval.query`.

**O laboratório não faz isso, e a segunda linha mostra.** Os dois modelos do laboratório são
simétricos. O labembed confere a tarefa, registra e calcula o mesmo vetor, diga ela o que disser;
então `query and passage identical: True` é um fato sobre o labembed, e não sobre a Jina. Com o
jina-embeddings-v3 os dois vetores seriam diferentes, e o campo existe por causa dessa diferença.

**Uma tarefa que a Jina não conhece é recusada**, e o labembed copia a recusa: a mensagem lista as
cinco que ela aceita.
`retrieval.document` é o deslize esperado de quem acabou de usar o `RETRIEVAL_DOCUMENT` do Gemini
ou o `search_document` da Cohere: a Jina chama a mesma coisa de passage, um trecho. O status é 422,
onde as aulas 7 e 8 encontraram 400 para uma requisição malformada, então um código que só trata
um 400 como "minha requisição estava errada" vai tratar esta como outra coisa.

O log do labembed mostra o que ele entendeu:

```
ana@lab:~/emb$ tail -n 4 /var/log/labembed/requests.jsonl | jq -c "{provider, task, dims, status}"
{"provider":"jina","task":"retrieval.query","dims":64,"status":200}
{"provider":"jina","task":"retrieval.query","dims":256,"status":200}
{"provider":"jina","task":"retrieval.passage","dims":256,"status":200}
{"provider":"jina","task":null,"dims":null,"status":422}
```

As quatro requisições foram para `/v1/embeddings`, o caminho que uma requisição da OpenAI usa, e o
labembed as distinguiu só pela chave: `provider` diz `jina`. A primeira pediu 64 dimensões e as duas
seguintes receberam as 256 completas. A requisição recusada não tem tarefa registrada, porque o
labembed a barrou antes de aceitar uma.

## Late chunking, descrito e não executado

A aula 3 corta um documento longo em pedaços e transforma cada pedaço em vetor separadamente. Isso
perde contexto: um pedaço que diz *it arrives in five working days* ("chega em cinco dias úteis") já
não diz o que é esse *it*. O campo `late_chunking` da Jina mira exatamente nisso. Com ele ligado, o
modelo lê juntos os pedaços de uma mesma requisição, como um texto só, e só depois tira a média da
parte de cada pedaço para formar o vetor dele. A aula 9 mostrou essa média, o mean pooling no fim do
modelo; o late chunking põe o corte depois das camadas em vez de antes, e assim o vetor de cada
pedaço já viu os vizinhos.

```python
r = httpx.post("https://api.jina.ai/v1/embeddings",
               headers={"Authorization": "Bearer " + os.environ["JINA_API_KEY"]},
               json={"model": "jina-embeddings-v3", "task": "retrieval.passage",
                     "late_chunking": True, "input": chunks})
```

**Isto não foi executado.** A api.jina.ai está fora de alcance a partir da máquina em que este
curso foi gravado, e o labembed ignora o campo, então nada aqui mede se ele ajuda. O curso `rag`
leva os pedaços mais longe.

## O preço não está na tabela

Todo preço deste curso vem de um lugar só, a tabela do LiteLLM no commit b9e71e990aed, que o
`prices.py` da aula 7 lê. A próxima seção procura a Jina nessa tabela, e a única linha com o nome
dela é um reranker, não um modelo de embedding. **Por isso esta aula não cita preço da Jina.**
Leia na página de preços da própria Jina no dia em que for decidir, e anote a data ao lado.
