---
title: Dois jeitos de rodar um modelo em casa
version: 1
---

A aula 3 calculou o que é preciso para rodar um modelo por conta própria: memória para os pesos, um
runtime e alguém para mantê-lo de pé. As aulas 10 a 12 mostraram de onde vêm os pesos abertos.
Ollama e LM Studio são as duas ferramentas que a maioria das pessoas usa para juntar as duas coisas
numa máquina. O Ollama é o que a aula 1 instalou, e tudo o que esta aula mostra dele rodou de
verdade. O LM Studio não: o site dele foi recusado pela rede da máquina em que este curso foi
gravado, e ele é um aplicativo de desktop. O que esta aula mostra do LM Studio é a documentação
dele, lida num commit fixado.

## Ollama

O Ollama é um servidor que roda em segundo plano e um comando, `ollama`, que fala com ele. Ele
baixa modelos da própria biblioteca em ollama.com e os nomeia assim:

```
# ollama/ollama@42e911bc docs/api.md
  24: Model names follow a `model:tag` format, where `model` can have an optional namespace
      such as `example/model`. Some examples are `orca-mini:3b-q8_0` and `llama3:70b`. The tag
      is optional and, if not provided, will default to `latest`. The tag is used to identify
      a specific version.
```

A tag carrega o tamanho e muitas vezes a precisão: `llama3:70b`, `orca-mini:3b-q8_0`. E **um nome
sem tag quer dizer `latest`**, que é de novo o apelido da seção 06 da aula 2: o mesmo nome, outros
bytes, no dia em que a biblioteca o atualiza. Um programa que deve continuar se comportando como foi
avaliado diz a tag completa.

Por baixo, quem faz a conta é o llama.cpp, um runtime de código aberto feito para rodar pesos
quantizados, os menos bits por peso da seção 04 da aula 3, em CPUs e GPUs comuns:

```
# ollama/ollama@42e911bc README.md
 141: ## Supported backends
 143: - [llama.cpp](https://github.com/ggml-org/llama.cpp) project founded by Georgi Gerganov.
```

## LM Studio

O LM Studio é um aplicativo de desktop: busque no Hugging Face, baixe um modelo, converse com ele e
ligue um servidor. Ele vem em mais duas formas, e a documentação diz para que servem:

```
# lmstudio-ai/docs@9b8bc200 0_app/1_basics/lmstudio-vs-llmster-vs-lms.md
  28: llmster is LM Studio’s headless daemon – a standalone background service that can run
      without a GUI. This means you do not have to download the LM Studio app to use llmster
      via the terminal.
  68: Once the server is running, it listens on http://localhost:1234. Point any SDK or
      compatible tool at our OpenAI or Anthropic-compatible endpoints to use your LM Studio
      models.
```

O `llmster` é o de máquina sem tela, e o `lms` é a linha de comando dos dois. Os modelos vêm direto
do Hugging Face, no formato GGUF que o llama.cpp lê ou, num Mac, no formato MLX da Apple.

| | Ollama | LM Studio |
|---|---|---|
| o que é | um servidor e um comando | um app, um daemon sem interface (`llmster`) e um comando (`lms`) |
| modelos de | biblioteca própria | Hugging Face |
| escuta em | `localhost:11434` | `localhost:1234` |
| API própria | `/api/chat`, `/api/generate` | `/api/v1/chat` |
| formato da OpenAI | `/v1/chat/completions` | `/v1/chat/completions` |

Qual dos dois é questão de gosto para uma pessoa e de implantação para um programa: o Ollama num
servidor é uma instalação e um serviço, o LM Studio numa mesa é uma janela. O resto desta aula usa
primeiro a API própria do Ollama, porque ela informa mais, e depois o formato da OpenAI, que os dois
aceitam.
