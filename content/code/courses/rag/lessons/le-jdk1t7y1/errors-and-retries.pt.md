---
title: Erros e novas tentativas
version: 2
---

Um pipeline de RAG chama um provedor duas vezes por pergunta, uma para gerar o embedding e outra para
responder, e cada chamada pode falhar: requisições demais, um provedor sobrecarregado, uma rede que
derruba a conexão. A aula 5 encontrou a primeira ao indexar. Na hora da consulta isso pesa mais, porque
há um cliente esperando.

## O que o SDK tenta de novo

Os SDKs tentam de novo, sozinhos, as falhas que podem dar certo um instante depois: um 429 por
requisições demais, um 500 e tanto de um provedor sobrecarregado, uma conexão que caiu, e uma requisição
que demorou mais que o tempo limite do cliente. A aula 5 viu esse laço contra uma porta onde nada
escutava. O Ollama na sua própria máquina nunca limita a taxa e raramente fica sobrecarregado, então a
falha que um pipeline local encontra é a última: um modelo num processador sem placa de vídeo pode levar
mais que o tempo limite para responder.

## Uma falha que ele não absorve

O `fragile.py` dá ao `rag.py` um cliente que espera um segundo por qualquer resposta e o deixa tentar de
novo duas vezes:

```schooling-example
{
  "language": "python",
  "file": "fragile.py",
  "parts": [
    {
      "code": "import sys\n\nimport openai\nimport rag\n\n# A client that gives a reply one second, and gives up after two retries.\nrag.client = openai.OpenAI(max_retries=2, timeout=1)\ntry:\n    print(rag.ask(sys.argv[1])[0])\nexcept (openai.APITimeoutError, openai.APIConnectionError) as e:\n    print(\"gave up after retries:\", type(e).__name__)\n    print(\"Our assistant is busy right now. Please try again in a minute.\")",
      "note": "O cliente do `rag.py` trocado por um que espera um segundo por qualquer resposta, e a falha capturada onde um cliente veria, se não, um stack trace."
    }
  ]
}
```

```
ana@vm:~/rag$ OPENAI_LOG=info python fragile.py "How long is a gift card valid?" 2>&1
[2026-10-07 22:17:27 - httpx:1025 - INFO] HTTP Request: POST http://localhost:11434/v1/embeddings "HTTP/1.1 200 OK"
[2026-10-07 22:17:28 - openai._base_client:1172 - INFO] Retrying request to /chat/completions in 0.394029 seconds
[2026-10-07 22:17:29 - openai._base_client:1172 - INFO] Retrying request to /chat/completions in 0.835753 seconds
gave up after retries: APITimeoutError
Our assistant is busy right now. Please try again in a minute.
```

O pedido de embedding respondeu dentro do segundo, `200 OK`. **O pedido de chat não respondeu, três
vezes: uma tentativa, duas novas tentativas com uma espera crescente entre elas, e o SDK levantou
`APITimeoutError`.** O programa capturou o erro e mostrou ao cliente uma frase em vez de um stack trace.
Cada nova tentativa começou a geração de novo do zero, então um tempo limite curto demais não só falha:
ele gasta o equivalente a três gerações da máquina numa resposta que ninguém recebe.

O próprio `rag.py` define vinte segundos, o que na máquina em que este curso foi gravado bastou para
todas as execuções desta aula. Um modelo atrás de uma API comercial responde uma pergunta deste tamanho
em um ou dois segundos, e um tempo limite de dez ou vinte segundos ali pega uma requisição travada, não
uma lenta.

## As regras que valem a pena

**Defina o orçamento de novas tentativas e o tempo limite no cliente**, e meça o tempo limite contra o
modelo que você de fato roda. O `rag.py` define três novas tentativas e vinte segundos. O padrão da
maioria dos SDKs é duas novas tentativas e dez minutos, e dez minutos não é um tempo limite que alguém
esperando numa janela de chat escolheria.

**Tente de novo o que pode dar certo, não o que não pode.** Os SDKs tentam de novo limites de taxa,
sobrecargas e erros de conexão, e não tentam de novo uma requisição malformada ou uma chave recusada,
porque repetir essas não adianta. Código que embrulha o SDK num laço de novas tentativas próprio em geral
desfaz essa distinção.

**Decida o que o cliente vê quando tudo falha.** Uma frase dizendo que o assistente está ocupado é uma
decisão de produto; uma exceção é um acidente. Para um assistente de atendimento, a alternativa melhor
muitas vezes são os resultados da busca, os artigos da central de ajuda, sem resposta gerada: a
recuperação só precisa da chamada de embedding, e os próprios documentos são úteis.

**Separe as falhas das duas chamadas.** A chamada de embedding falhar significa nenhuma busca; a chamada
de chat falhar depois de uma busca significa que as fontes são conhecidas e podem ser mostradas. Um
pipeline que trata as duas como um erro só joga fora a metade que funcionou.

**E conte-as.** Toda nova tentativa é uma requisição que o provedor cobra ou limita, e com um provedor
comercial uma taxa crescente de 429 é o primeiro sinal de uma cota prestes a ficar pequena. O registro da
última seção desta aula é o lugar para anotá-las.
