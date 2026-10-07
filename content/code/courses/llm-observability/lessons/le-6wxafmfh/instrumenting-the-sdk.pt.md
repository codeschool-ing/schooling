---
title: Deixando uma biblioteca escrever os spans
version: 2
---

Escrever cada span à mão é o que o `assistant.py` faz, e não é o que a maioria das equipes faz
primeiro. O primeiro passo de costume é uma **biblioteca de instrumentação**: um pacote que embrulha o
SDK do fornecedor, de modo que toda chamada feita por ele produz um span sem uma linha de código de
rastreamento na aplicação. A aula 3 do `observability` faz o mesmo com frameworks web e drivers de
banco, e diz onde isso deixa de bastar; esta seção olha o que uma dessas bibliotecas registra numa
chamada a modelo.

O OpenInference é uma delas. É o conjunto de instrumentadores e convenções da Arize, e o Phoenix, na
aula 7, lê o que ele escreve. O `auto.py` é o `one_call.py` sem nenhum span:

```python
"""auto.py: the same call with no span written by hand: OpenInference instruments the SDK."""
from openai import OpenAI
from openinference.instrumentation.openai import OpenAIInstrumentor

import telemetry

provider = telemetry.setup("auto.jsonl")
OpenAIInstrumentor().instrument(tracer_provider=provider)

client = OpenAI()
reply = client.chat.completions.create(
    model="llama3.2:3b", temperature=0,
    messages=[{"role": "user", "content": "How long is a Marginalia gift card valid?"}])
print(reply.choices[0].message.content)
```

O `instrument()` troca os métodos do SDK por versões que abrem um span, chamam o original, e preenchem
o span com o que entrou e o que saiu.

```
ana@dev:~/obs$ python auto.py
I couldn't find any information on a gift card called "Marginalia." It's possible that it's a lesser-known or regional gift card, or it may be a misspelling or incorrect name.

If you could provide more context or clarify the name of the gift card, I'd be happy to try and help you find the information you're looking for.
ana@dev:~/obs$ python tree.py --spans auto.jsonl --attrs
trace 89dce4abc53cd3ca204f04e7edf8a68d   start(ms) took(ms)
      0   7,307 ms  ChatCompletion
                     llm.system = "openai"
                     input.value = "{\"model\": \"llama3.2:3b\", \"messages\": [{\"role\": \"user\", \"content\": \"How long is a Marginalia gift card valid?\"}], \"temperature\": 0}"
                     input.mime_type = "application/json"
                     output.value = "{\"id\":\"chatcmpl-771\",\"choices\":[{\"finish_reason\":\"stop\",\"index\":0,\"message\":{\"content\":\"I couldn't find any information on a gift card called \\\"Marginalia.\\\" It's possible that it's a lesser-known or regional gift card, or it may be a misspelling or incorrect name.\\n\\nIf you could provide more context or clarify the name of the gift card, I'd be happy to try and help you find the information you're looking for.\",\"role\":\"assistant\"}}],\"created\":1791416895,\"model\":\"llama3.2:3b\",\"object\":\"chat.completion\",\"system_fingerprint\":\"fp_ollama\",\"usage\":{\"completion_tokens\":75,\"prompt_tokens\":36,\"total_tokens\":111,\"prompt_tokens_details\":{\"cached_tokens\":35}}}"
                     output.mime_type = "application/json"
                     llm.invocation_parameters = "{\"model\": \"llama3.2:3b\", \"temperature\": 0}"
                     llm.input_messages.0.message.role = "user"
                     llm.input_messages.0.message.content = "How long is a Marginalia gift card valid?"
                     llm.model_name = "llama3.2:3b"
                     llm.token_count.total = 111
                     llm.token_count.prompt = 36
                     llm.token_count.completion = 75
                     llm.token_count.prompt_details.cache_read = 35
                     llm.output_messages.0.message.role = "assistant"
                     llm.output_messages.0.message.content = "I couldn't find any information on a gift card called \"Marginalia.\" It's possible that it's a lesser-known or regional gift card, or it may be a misspelling or incorrect name.\n\nIf you could provide more context or clarify the name of the gift card, I'd be happy to try and help you find the information you're looking for."
                     llm.finish_reason = "stop"
                     openinference.span.kind = "LLM"
```

## O que ela registrou, e com quais nomes

O span se chama `ChatCompletion`, e os seus atributos estão na **convenção própria do OpenInference**,
não na do OpenTelemetry: `llm.model_name` onde a seção anterior tinha `gen_ai.request.model`,
`llm.token_count.prompt` onde tinha `gen_ai.usage.input_tokens`, e `openinference.span.kind =
"LLM"`, que o Phoenix usa para escolher como desenhá-lo. Os fatos são os mesmos e os nomes não, e essa
é a primeira coisa a acertar ao escolher uma ferramenta: o que ela escreve e o que ela lê. A aula 7
volta a isso.

As duas convenções estão convergindo. A versão do OpenInference instalada na seção 03 tem uma configuração
que a faz escrever os nomes do OpenTelemetry no lugar dos seus:

```
ana@dev:~/obs$ rm auto.jsonl; OPENINFERENCE_ENABLE_GENAI_SEMCONV=true python auto.py
I couldn't find any information on a gift card called "Marginalia." It's possible that it's a lesser-known or regional gift card, or it may be a misspelling or incorrect name.

If you could provide more context or clarify the name of the gift card, I'd be happy to try and help you find the information you're looking for.
ana@dev:~/obs$ python tree.py --spans auto.jsonl --attrs | grep gen_ai
                     gen_ai.operation.name = "chat"
                     gen_ai.provider.name = "openai"
                     gen_ai.request.model = "llama3.2:3b"
                     gen_ai.request.temperature = 0.0
                     gen_ai.usage.input_tokens = 36
                     gen_ai.usage.output_tokens = 75
                     gen_ai.usage.cache_read.input_tokens = 35
                     gen_ai.input.messages = "[{\"role\": \"user\", \"parts\": [{\"type\": \"text\", \"content\": \"How long is a Marginalia gift card valid?\"}]}]"
                     gen_ai.output.messages = "[{\"role\": \"assistant\", \"parts\": [{\"type\": \"text\", \"content\": \"I couldn't find any information on a gift card called \\\"Marginalia.\\\" It's possible that it's a lesser-known or regional gift card, or it may be a misspelling or incorrect name.\\n\\nIf you could provide more context or clarify the name of the gift card, I'd be happy to try and help you find the information you're looking for.\"}], \"finish_reason\": \"stop\"}]"
                     gen_ai.response.finish_reasons = ["stop"]
                     gen_ai.response.id = "chatcmpl-603"
                     gen_ai.response.model = "llama3.2:3b"
```

Mesma chamada, e agora `gen_ai.request.model` e `gen_ai.usage.input_tokens`, que qualquer ferramenta
que leia a convenção do OpenTelemetry entende. Espere que configurações assim mudem de nome e de
padrão de uma versão para a outra enquanto a convenção for nova; leia o span depois de toda
atualização.

Leia mais um atributo: `gen_ai.provider.name = "openai"`. A biblioteca enxerga o SDK da OpenAI e
escreve o que o SDK é, e não tem como saber que o servidor do outro lado é o Ollama. O span escrito à
mão da seção 07 diz `ollama`, porque quem o escreveu sabia. Um relatório de custos que agrupasse as
chamadas por fornecedor poria todas estas sob o nome errado. Ela também registrou algo que os spans
escritos à mão não registram: 35 dos 36 tokens do prompt foram lidos do cache do Ollama, porque a
mesma pergunta tinha sido feita pouco antes.

## E o que ela registrou sem que ninguém pedisse

Leia `input.value` e `llm.input_messages.0.message.content` na primeira captura, ou
`gen_ai.input.messages` na segunda. **A biblioteca registrou o prompt inteiro, e a resposta inteira,
por padrão.** Aqui é uma pergunta sobre vale-presentes. Em produção é o que quer que um cliente tenha
digitado, e a aula 2 mostra o que os clientes digitam: nomes, endereços de e-mail, números de
telefone, números de pedido, e de vez em quando um número de cartão. Toda biblioteca de instrumentação
para modelos enfrenta a mesma escolha, e a maioria delas guarda o texto por padrão, porque o texto é o
que torna um trace útil para depurar. O OpenInference lê variáveis de ambiente como
`OPENINFERENCE_HIDE_INPUTS` e `OPENINFERENCE_HIDE_OUTPUTS` para deixá-lo de fora; a instrumentação do
próprio OpenTelemetry para o SDK da OpenAI faz o contrário, e deixa o conteúdo de fora a menos que
`OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` o peça. Essa segunda não foi rodada aqui.

Nenhum dos dois padrões está errado. Errado é não saber qual está rodando, e isso é fácil de
descobrir: chame o modelo uma vez e leia o span, como acima, antes que a mensagem de um único cliente
passe por ele.

## À mão, automático, ou os dois

| | à mão | por uma biblioteca |
|---|---|---|
| o que custa | uma linha por atributo, em cada lugar onde se faz uma chamada | uma chamada na inicialização |
| o que cobre | o que você lembrou | toda chamada por aquele SDK, inclusive em código que você não escreveu |
| o que sabe | os seus nomes: a funcionalidade, a versão, os trechos mantidos | o pedido e a resposta, e nada sobre por que a chamada foi feita |
| o que guarda | o que você escolheu | o padrão da biblioteca, que você precisa ir conferir |

Os dois se combinam. O span de uma biblioteca para cada chamada se aninha sob um span escrito à mão
para a etapa que a fez, desde que o span da etapa seja o corrente quando a chamada acontece, que é o
que o `span()` faz. O assistente escreve os próprios spans de modelo por um motivo só: ele faz
streaming, novas tentativas e mede o primeiro token no próprio código, e são essas as coisas de que as
aulas 4 e 5 precisam no span.
