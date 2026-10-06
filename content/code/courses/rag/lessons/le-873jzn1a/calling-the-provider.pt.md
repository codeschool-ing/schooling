---
title: Chamando o provedor de embeddings
version: 1
---

O `ingest.py` é o programa que transforma o corpus num índice, e toda aula seguinte busca no que ele
constrói. O primeiro trabalho dele é conseguir vetores do provedor de embeddings, e isso é uma chamada de
rede com tudo o que uma chamada de rede traz: limites de quanto uma requisição pode levar, limites de
quantas requisições podem ser feitas, e recusas.

```schooling-example
{
  "language": "python",
  "file": "ingest.py",
  "parts": [
    {
      "code": "import hashlib\n\nimport psycopg\nimport tiktoken\nfrom chunking import load, structured\nfrom openai import OpenAI\nfrom pgvector.psycopg import register_vector\n\nMODEL = \"lab-minilm\"\nSIZE = 60\nenc = tiktoken.get_encoding(\"cl100k_base\")\nclient = OpenAI(max_retries=5)",
      "note": "O SDK da OpenAI, apontado para o labgen pela `OPENAI_BASE_URL`, que repassa os pedidos de embedding ao labembed. O `max_retries=5` deixa o SDK tentar de novo uma requisição recusada até cinco vezes antes de desistir. `SIZE` são as 60 palavras que a seção anterior escolheu."
    },
    {
      "code": "def embed(texts, batch=32):\n    vectors = []\n    for i in range(0, len(texts), batch):\n        reply = client.embeddings.create(model=MODEL, input=texts[i:i + batch])\n        vectors += [d.embedding for d in reply.data]\n    return vectors",
      "note": "Trinta e dois textos por requisição. Menos requisições querem dizer menos idas e voltas e menos chances de bater num limite de taxa; todo provedor limita quantas entradas uma requisição pode levar, e o limite do labembed é 2.048."
    }
  ]
}
```

O SDK é o mesmo que a aula 7 do `embeddings-vectors` usou, `client.embeddings.create`, e o modelo é o
`lab-minilm` do laboratório. Com um provedor real, só mudam a URL base, a chave e o nome do modelo.

## Lotes

```
ana@lab:~/rag$ python ingest.py
chunks: 137  embedded: 137  removed: 0  kept: 0
ana@lab:~/rag$ wc -l < /var/log/labembed/requests.jsonl
5
```

**137 pedaços, cinco requisições**: quatro de 32 e uma de 9. Mandar um pedaço por requisição teria
dado 137 idas e voltas, cada uma pagando a latência da rede e cada uma contando no limite de requisições
por minuto do provedor. Todo provedor limita quantas entradas uma requisição pode levar, e alguns
limitam também o total de tokens, então o tamanho do lote é o maior que fica abaixo dos dois; 32 fica
folgadamente abaixo de todos os limites que este curso encontrou.

## Recusas

Um provedor recusa requisições quando elas chegam mais depressa do que o limite da conta permite, com
HTTP 429. Indexar um corpus grande é exatamente a rajada que provoca isso. O labembed pode ser instruído
a recusar as próximas requisições de propósito, e o `ingest.py` rodado de novo a partir de uma tabela
vazia mostra o que acontece:

```
ana@lab:~/rag$ psql -qc "DROP TABLE chunks"
ana@lab:~/rag$ curl -s -X POST localhost:8500/lab/config -d "{\"fail\": 2, \"status\": 429}"; echo
{"fail": 2, "status": 429}
ana@lab:~/rag$ python ingest.py
chunks: 137  embedded: 137  removed: 0  kept: 0
ana@lab:~/rag$ python requests.py | tail -n 7
429  Rate limit reached for requests. Please try again in 1s.
429  Rate limit reached for requests. Please try again in 1s.
200 32 
200 32 
200 32 
200 32 
200 9 
```

**A primeira requisição foi recusada duas vezes e deu certo na terceira tentativa, e o programa nunca
soube.** O SDK da OpenAI tenta de novo um 429 sozinho, esperando um pouco mais a cada vez, e o
`max_retries=5` lhe deu espaço para cinco tentativas. O `requests.py` lê o registro de requisições do
labembed, uma linha por requisição recebida, que é o único lugar onde as duas recusas aparecem.

Duas coisas decorrem disso. **Defina o orçamento de tentativas de propósito**: o padrão da maioria dos
SDKs são duas novas tentativas, que uma indexação longa numa conta ocupada pode esgotar, e aí a execução
morre no meio. E **torne a execução segura para repetir**, porque cedo ou tarde uma vai morrer no meio
de qualquer jeito. A seção sobre ids mostra que o `ingest.py` é: uma segunda execução gera embedding só
do que a primeira não terminou.

## Custo

O embedding é cobrado por token de entrada. Este corpus tem 8.914 tokens pela contagem da aula 1, mais os
caminhos de títulos, e aos preços que os provedores cobram por modelos de embeddings custa uma fração de
centavo gerar todos. É por isso que a aula 3 chamou a reindexação de barata. O que não é barato é refazer
o embedding de um corpus de milhões de pedaços toda noite porque ninguém acompanhou quais mudaram, e é
isso que os ids das próximas seções evitam.
