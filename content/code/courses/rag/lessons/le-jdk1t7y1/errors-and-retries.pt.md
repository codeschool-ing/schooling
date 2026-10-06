---
title: Erros e novas tentativas
version: 1
---

Um pipeline de RAG chama um provedor duas vezes por pergunta, uma para gerar o embedding e outra para
responder, e cada chamada pode falhar: requisições demais, um provedor sobrecarregado, uma rede que cai.
A aula 5 encontrou o primeiro caso na indexação. Na hora da consulta isso importa mais, porque há um
cliente esperando.

## Uma recusa que o SDK absorve

O labgen pode ser instruído a recusar as próximas requisições, do mesmo jeito que o labembed foi na aula 5:

```
ana@lab:~/rag$ curl -s -X POST localhost:8600/lab/config -d "{\"fail\": 2, \"status\": 429}"; echo
{"fail": 2, "status": 429}
ana@lab:~/rag$ python rag.py "How long is a gift card valid?"
A gift card is valid for two years from the day it was bought. [1] Gift cards are valid for two years from purchase and cannot be exchanged for cash. [2]
  [1] Gift card terms > Validity, updated 2025-10-27
  [2] Payments, invoices and gift cards > Gift cards, updated 2026-03-30
ana@lab:~/rag$ python statuses.py
/v1/embeddings 200
/v1/chat/completions 200
/v1/embeddings 429
/v1/embeddings 429
/v1/embeddings 200
/v1/chat/completions 200
```

O `statuses.py` imprime as últimas seis requisições que o labgen recebeu. As duas primeiras são da consulta
anterior. Depois, **a requisição de embedding foi recusada duas vezes e deu certo na terceira tentativa**,
e a requisição de chat passou. O cliente viu uma resposta; o programa nunca soube. O `rag.py` criou o
cliente com `max_retries=3`, e o SDK gastou duas, esperando um pouco mais antes de cada uma.

## Uma recusa que ele não absorve

```
ana@lab:~/rag$ curl -s -X POST localhost:8600/lab/config -d "{\"fail\": 5, \"status\": 429}"; echo
{"fail": 5, "status": 429}
ana@lab:~/rag$ python fragile.py "How long is a gift card valid?"
gave up after retries: 429
Our assistant is busy right now. Please try again in a minute.
ana@lab:~/rag$ python statuses.py
/v1/embeddings 429
/v1/embeddings 200
/v1/chat/completions 200
/v1/embeddings 429
/v1/embeddings 429
/v1/embeddings 429
```

O `fragile.py` troca o cliente por um com só duas novas tentativas, e há cinco recusas esperando. **Três
tentativas, três recusas, e o SDK levantou `RateLimitError`.** O programa a capturou e mostrou ao cliente
uma frase em vez de um stack trace. As últimas seis linhas do registro mostram as três requisições da
consulta anterior e depois as três tentativas recusadas desta; o endpoint de chat nem foi alcançado,
porque não havia vetor com que buscar.

```
ana@lab:~/rag$ curl -s -X POST localhost:8600/lab/config -d "{\"fail\": 0}"; echo
{"fail": 0, "status": 429}
```

## As regras que valem a pena

**Defina o orçamento de tentativas e o tempo limite no cliente.** O `rag.py` define três tentativas e
vinte segundos. Os padrões da maioria dos SDKs são duas tentativas e dez minutos, e dez minutos não é um
tempo limite que alguém esperando numa janela de chat escolheria.

**Tente de novo o que pode dar certo, não o que não pode.** Os SDKs tentam de novo limites de taxa,
sobrecargas e erros de conexão, e não tentam de novo uma requisição inválida ou uma chave recusada,
porque repetir essas não ajuda. Código que embrulha o SDK num laço de tentativas próprio costuma desfazer
essa distinção.

**Decida o que o cliente vê quando tudo falha.** Uma frase dizendo que o assistente está ocupado é uma
decisão de produto; uma exceção é um acidente. Para um assistente de atendimento, a melhor alternativa
muitas vezes são os resultados simples da busca, os artigos da central de ajuda, sem resposta gerada: a
recuperação só precisa da chamada de embedding, e os próprios documentos são úteis.

**Separe as falhas das duas chamadas.** A chamada de embedding falhar quer dizer nenhuma busca; a chamada
de chat falhar depois de uma busca quer dizer que as fontes são conhecidas e podem ser mostradas. Um
pipeline que trata as duas como um erro só joga fora a metade que funcionou.

**E conte-as.** Toda nova tentativa é uma requisição que o provedor cobra ou limita, e uma taxa crescente
de 429 é o primeiro sinal de uma cota prestes a ficar pequena. O registro da última seção desta aula é o
lugar de anotá-las.
