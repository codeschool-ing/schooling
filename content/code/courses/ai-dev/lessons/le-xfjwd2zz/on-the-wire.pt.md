---
title: Como é um stream
version: 2
---

Uma resposta em streaming é uma resposta HTTP comum que não termina logo. O tipo de conteúdo dela é
`text/event-stream`, o formato que os navegadores chamam de **server-sent events**: blocos de linhas
separados por uma linha em branco, cada um com um nome em `event:` e uma linha `data:` de JSON. O
`curl -N` os imprime conforme chegam. O `cut` limita cada linha a 110 caracteres, o que encurta duas
delas aqui.

```
ana@dev:~/shop$ curl -sN $ANTHROPIC_BASE_URL/v1/messages -H "x-api-key: $ANTHROPIC_API_KEY" -H 'anthropic-version: 2023-06-01' -H 'content-type: application/json' -d '{"model": "llama3.2:3b", "max_tokens": 50, "stream": true, "messages": [{"role": "user", "content": "Say hello in five words."}]}' | cut -c1-110
event: message_start
data: {"type":"message_start","message":{"id":"msg_5e384c52b4778230567e6fc1","type":"message","role":"assistan

event: content_block_start
data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" to"}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" you"}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" right"}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" now"}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"."}}

event: content_block_stop
data: {"type":"content_block_stop","index":0}

event: message_delta
data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"input_tokens":11,"cache_read_input_

event: message_stop
data: {"type":"message_stop"}
```

## Lendo os eventos

- **`message_start`** abre a resposta com o id, o modelo e os tokens de entrada, que já são
  conhecidos antes de o modelo escrever qualquer coisa.
- **`content_block_start`** abre um bloco da resposta, aqui de texto. Uma resposta com chamada de
  ferramenta tem um segundo bloco, como a aula 9 seção 08 mostra.
- **`content_block_delta`** leva um pedaço: um `text_delta` com alguns caracteres. Seis deles
  formam a resposta, uma palavra ou um ponto final cada.
- **`content_block_stop`**, depois **`message_delta`** com o `stop_reason` e os tokens de saída,
  depois **`message_stop`**. Só depois desses a resposta está completa.

A própria API da Anthropic também manda eventos **`ping`**, que não levam nada e impedem que algo no
meio feche uma conexão quieta; o Ollama não manda nenhum, e um leitor tem de pulá-los de qualquer
jeito. **O fim é um evento, não a conexão fechando.** Uma conexão que fecha sem `message_stop` é uma
resposta que não terminou, e a aula 9 seção 07 trata de distinguir as duas coisas.

## Por que este formato

Server-sent events são texto, num sentido só, sobre HTTP comum. Eles passam por proxies que
barrariam outros tipos de conexão longa, um navegador tem um leitor embutido para eles, e uma pessoa
consegue depurá-los com `curl`, como aqui. Todo provedor deste curso faz streaming assim, com nomes
de evento próprios dentro do mesmo formato, e o Ollama copia os nomes da Anthropic neste endpoint.
