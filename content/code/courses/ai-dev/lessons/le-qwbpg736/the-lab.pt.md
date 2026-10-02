---
title: O laboratório em que este curso roda
version: 1
---

Todo comando deste curso foi executado, e toda linha de saída é o que o comando imprimiu. A
máquina em que ele rodou é um laboratório, montado pelo `lab.sh` ao lado dos arquivos do curso: um
computador Linux, uma desenvolvedora chamada ana, e o projeto dela.

```
ana@dev:~/shop$ python --version
Python 3.11.15
ana@dev:~/shop$ git log --oneline
19265e0 Conventions
b88cbb3 README
c2b5d79 Coupons
fe437dd A cart with lines, a discount and shipping
33fefcf Prices are integer cents
ana@dev:~/shop$ python -m pytest -q
........                                                                 [100%]
8 passed in 0.57s
```

**O `~/shop` é o carrinho, os preços e os cupons de uma pequena loja online**, com os testes, no
git. Dinheiro é centavo inteiro em todo lugar. As aulas acrescentam coisas a ele: as sugestões de
um assistente nas aulas 3 a 5, um manual de suporte para buscar na aula 6, ferramentas para um
modelo chamar nas aulas 7 e 8.

## O que é real, e o que foi escrito para o curso

Um curso sobre chamar modelos tem um problema que um curso de redes não tem. **Nenhuma API de
modelo estava ao alcance da máquina em que este curso foi gravado**, e mesmo que estivesse, uma
chave de API é uma conta presa ao cartão de alguém. Então o laboratório tem um provedor substituto,
e é importante saber exatamente onde cai a linha entre o real e o substituto.

| | o que é |
|---|---|
| real | os próprios SDKs Python dos provedores (`anthropic`, `openai`, `google-genai`), o SDK do MCP, o `tiktoken` com as codificações reais da OpenAI, o modelo de embeddings WordLlama, numpy, pytest e hypothesis |
| do laboratório | **o labllm**, um servidor em `127.0.0.1:8400` que fala o formato de fio das APIs da Anthropic, da OpenAI e do Gemini de perto o bastante para os três SDKs conversarem com ele sem modificação |
| do laboratório | **o `tiny-1`**, um dos dois modelos do labllm: o `tinylm`, o modelo de contagem de tokens da aula 1 seção 02. O texto dele é saída real de um modelo real, muito pequeno |
| do laboratório | **o `scripted-1`**, o outro: respostas **escritas pelo curso**, escolhidas por regras simples. Ele existe para que o código em volta de um modelo (laços de ferramentas, validação, busca, streaming) possa rodar de verdade |

**Toda aula que mostra uma resposta do `scripted-1` diz que ela foi escrita pelo curso.** Nada
neste curso apresenta o texto do substituto como algo que um modelo de linguagem disse. O que o
curso afirma é que o código em volta dessas respostas é exatamente o código que você escreveria
contra um provedor real: as mesmas chamadas de SDK, os mesmos corpos de requisição, a mesma leitura
das mesmas formas de resposta.

As versões, fixadas no `lab.sh`:

```
ana@dev:~/shop$ pip list 2>/dev/null | grep -iE "^(anthropic|openai|google-genai|mcp|tiktoken|wordllama|numpy|pytest|hypothesis) "
anthropic                 1.11.0
google-genai              2.27.0
hypothesis                6.168.3
mcp                       2.2.0
numpy                     2.4.6
openai                    3.23.0
pytest                    9.1.1
tiktoken                  0.14.0
wordllama                 0.4.0.post1
```

## Como os SDKs encontram o labllm

Cada SDK lê a chave e, em dois deles, a URL base do ambiente. Apontá-los para o laboratório são
três pares de variáveis, e as chaves são do próprio laboratório, que não abrem nada em lugar
nenhum:

```
ana@dev:~/shop$ env | grep -E "_(BASE_URL|API_KEY)=" | sort
ANTHROPIC_API_KEY=lab-anthropic-key-0001
ANTHROPIC_BASE_URL=http://127.0.0.1:8400
GEMINI_API_KEY=lab-google-key-0001
GEMINI_BASE_URL=http://127.0.0.1:8400
OPENAI_API_KEY=lab-openai-key-0001
OPENAI_BASE_URL=http://127.0.0.1:8400/v1
```

**Para rodar o código deste curso contra um provedor real, você muda essas variáveis e nada
mais**, fora o nome do modelo. A `GEMINI_BASE_URL` é invenção do laboratório: o SDK do Gemini
recebe o endereço no código em vez de no ambiente, e a aula 10 mostra a linha.

Uma requisição à mão, com `curl`, mostra o labllm respondendo no formato da Anthropic:

```
ana@dev:~/shop$ curl -s http://127.0.0.1:8400/v1/messages -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H "content-type: application/json" -d "{\"model\": \"tiny-1\", \"max_tokens\": 12, \"messages\": [{\"role\": \"user\", \"content\": \"Return the\"}]}" | python -m json.tool
{
    "id": "msg_lab_0004",
    "type": "message",
    "role": "assistant",
    "model": "tiny-1",
    "content": [
        {
            "type": "text",
            "text": " number of data.\nmode                Mode (most common values of"
        }
    ],
    "stop_reason": "max_tokens",
    "stop_sequence": null,
    "usage": {
        "input_tokens": 5,
        "output_tokens": 12,
        "cache_creation_input_tokens": 0,
        "cache_read_input_tokens": 0
    }
}
```

`stop_reason` e `usage` são os dois campos que este curso mais lê; a aula 2 começa por eles.

## O que o labllm decide por conta própria

Onde um provedor real tem uma regra, o labllm também tem, e as regras dele são dele. As aulas as
nomeiam onde importam, e estão todas aqui num lugar só:

- ele conta tokens com a `o200k_base`, mais 3 por mensagem;
- o `tiny-1` tem uma janela de contexto de 2.048 tokens e o `scripted-1` uma de 32.768, pequenas de
  propósito, para que a aula 2 consiga alcançá-las;
- ele leva 40 milissegundos para "gerar" cada token, para que a aula 9 tenha algo para medir;
- ele permite 50 requisições por minuto por chave, número baixado na aula 10 para mostrar o que
  acontece além dele.

O corpus que o `tinylm` contou são as docstrings de cinquenta módulos da biblioteca padrão:

```
ana@dev:~/shop$ python -c 'import tiktoken; t = open("/opt/aidev/share/corpus.txt").read(); print(len(t.split()), "words,", len(tiktoken.get_encoding("o200k_base").encode(t)), "tokens")'
51699 words, 78351 tokens
ana@dev:~/shop$ python -c 'import tiktoken; print(tiktoken.get_encoding("o200k_base").n_vocab, "tokens in o200k_base")'
200019 tokens in o200k_base
```

Modelos grandes são treinados com muitos trilhões de tokens. Este viu menos de oitenta mil, e a
aula 1 mostrou o que isso compra.
