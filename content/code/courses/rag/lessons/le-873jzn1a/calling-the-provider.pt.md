---
title: Chamando o provedor de embeddings
version: 2
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
      "code": "import hashlib\n\nimport psycopg\nimport tiktoken\nfrom chunking import load, structured\nfrom openai import OpenAI\nfrom pgvector.psycopg import register_vector\n\nMODEL = \"all-minilm\"\nSIZE = 60\nenc = tiktoken.get_encoding(\"cl100k_base\")\nclient = OpenAI(max_retries=5)",
      "note": "O SDK da OpenAI, apontado para o Ollama pela `OPENAI_BASE_URL`. O `max_retries=5` deixa o SDK tentar de novo uma requisição recusada até cinco vezes antes de desistir. `SIZE` são as 60 palavras que a seção anterior escolheu."
    },
    {
      "code": "def embed(texts, batch=32):\n    vectors = []\n    for i in range(0, len(texts), batch):\n        reply = client.embeddings.create(model=MODEL, input=texts[i:i + batch])\n        vectors += [d.embedding for d in reply.data]\n    return vectors",
      "note": "Trinta e dois textos por requisição. Menos requisições querem dizer menos idas e voltas e menos chances de bater num limite de taxa; todo provedor hospedado limita quantas entradas uma requisição pode levar."
    }
  ]
}
```

O SDK é o mesmo que a aula 7 do `embeddings-vectors` usou, `client.embeddings.create`, e o modelo é o
`all-minilm` no Ollama. Com um provedor hospedado, só mudam a URL base, a chave e o nome do modelo.

O SDK sabe dizer o que manda. Com `OPENAI_LOG=info` no ambiente ele escreve uma linha para cada
requisição HTTP, e contar essas linhas é contar as requisições.

## Lotes

```
ana@vm:~/rag$ OPENAI_LOG=info python ingest.py 2>&1 | grep -c "HTTP Request"
5
ana@vm:~/rag$ psql -tc "SELECT count(*) FROM chunks"
   137
```

**137 pedaços, cinco requisições**: quatro de 32 e uma de 9. Mandar um pedaço por requisição teria
dado 137 idas e voltas, cada uma pagando a latência da rede e cada uma contando no limite de requisições
por minuto do provedor. Todo provedor limita quantas entradas uma requisição pode levar, e alguns
limitam também o total de tokens, então o tamanho do lote é o maior que fica abaixo dos dois; 32 fica
folgadamente abaixo de todos os limites que este curso encontrou.

## Recusas

Um provedor hospedado recusa requisições quando elas chegam mais depressa do que o limite da conta
permite, com HTTP 429, e indexar um corpus grande é exatamente a rajada que provoca isso. O Ollama na
sua própria máquina não tem conta e nunca responde 429. Um servidor que não responde nada exercita o
mesmo código do SDK, porém, e isso dá para ter de propósito: aponte o programa para uma porta em que
nada escuta.

```
ana@vm:~/rag$ psql -qc "DROP TABLE chunks"
ana@vm:~/rag$ OPENAI_BASE_URL=http://localhost:11435/v1 OPENAI_LOG=info python ingest.py 2>&1 | grep -E "Retrying|Error:"
[2026-10-07 21:07:06 - openai._base_client:1172 - INFO] Retrying request to /embeddings in 0.395908 seconds
[2026-10-07 21:07:06 - openai._base_client:1172 - INFO] Retrying request to /embeddings in 0.755487 seconds
[2026-10-07 21:07:07 - openai._base_client:1172 - INFO] Retrying request to /embeddings in 1.818797 seconds
[2026-10-07 21:07:09 - openai._base_client:1172 - INFO] Retrying request to /embeddings in 3.450217 seconds
[2026-10-07 21:07:12 - openai._base_client:1172 - INFO] Retrying request to /embeddings in 7.545589 seconds
httpcore.ConnectError: [Errno 111] Connection refused
httpx.ConnectError: [Errno 111] Connection refused
openai.APIConnectionError: Connection error.
ana@vm:~/rag$ psql -tc "SELECT count(*) FROM chunks"
ERROR:  relation "chunks" does not exist
LINE 1: SELECT count(*) FROM chunks
                             ^
ana@vm:~/rag$ python ingest.py
chunks: 137  embedded: 137  removed: 0  kept: 0
```

**O SDK tentou seis vezes, esperando mais a cada vez, e então desistiu.** `max_retries=5` são cinco
novas tentativas depois da primeira, e as esperas quase dobram, de menos de meio segundo a uns sete,
com alguma aleatoriedade para que muitos clientes recusados juntos não voltem todos no mesmo instante.
Um 429 de um provedor passa exatamente por este laço, e um 429 que dura mais que o orçamento mata a
execução exatamente assim. Nada foi escrito, porque o `ingest.py` escreve dentro de uma transação e a
transação nunca foi confirmada; a execução seguinte, apontada de volta para o Ollama, começa do zero e
termina.

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
