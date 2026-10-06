---
title: Deixando uma biblioteca escrever os spans
version: 1
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
"""The same call with no span written by hand: OpenInference instruments the SDK."""
from openai import OpenAI
from openinference.instrumentation.openai import OpenAIInstrumentor

import telemetry

provider = telemetry.setup("auto.jsonl")
OpenAIInstrumentor().instrument(tracer_provider=provider)

client = OpenAI()
reply = client.chat.completions.create(
    model="extract-1", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
print(reply.choices[0].message.content)
```

O `instrument()` troca os métodos do SDK por versões que abrem um span, chamam o original, e preenchem
o span com o que entrou e o que saiu.

```
ana@lab:~/obs$ python auto.py
Marginalia gift cards are valid for one year from purchase.
ana@lab:~/obs$ python tree.py --spans auto.jsonl --attrs
trace 2c7a843d776d088f6cef8f657c830b0a   start(ms) took(ms)
      0     605 ms  ChatCompletion
                     llm.system = "openai"
                     input.value = "{\"model\": \"extract-1\", \"messages\": [{\"role\": \"user\", \"content\": \"How long is a gift card valid?\"}]}"
                     input.mime_type = "application/json"
                     output.value = "{\"id\":\"chatcmpl-lab0015\",\"choices\":[{\"finish_reason\":\"stop\",\"index\":0,\"message\":{\"content\":\"Marginalia gift cards are valid for one year from purchase.\",\"role\":\"assistant\"}}],\"created\":1791255600,\"model\":\"extract-1\",\"object\":\"chat.completion\",\"usage\":{\"completion_tokens\":13,\"prompt_tokens\":11,\"total_tokens\":24}}"
                     output.mime_type = "application/json"
                     llm.invocation_parameters = "{\"model\": \"extract-1\"}"
                     llm.input_messages.0.message.role = "user"
                     llm.input_messages.0.message.content = "How long is a gift card valid?"
                     llm.model_name = "extract-1"
                     llm.token_count.total = 24
                     llm.token_count.prompt = 11
                     llm.token_count.completion = 13
                     llm.output_messages.0.message.role = "assistant"
                     llm.output_messages.0.message.content = "Marginalia gift cards are valid for one year from purchase."
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

As duas convenções estão convergindo. A versão do OpenInference do laboratório tem uma configuração
que a faz escrever os nomes do OpenTelemetry no lugar dos seus:

```
ana@lab:~/obs$ rm auto.jsonl; OPENINFERENCE_ENABLE_GENAI_SEMCONV=true python auto.py
Marginalia gift cards are valid for one year from purchase.
ana@lab:~/obs$ python tree.py --spans auto.jsonl --attrs | grep gen_ai
                     gen_ai.operation.name = "chat"
                     gen_ai.provider.name = "openai"
                     gen_ai.request.model = "extract-1"
                     gen_ai.usage.input_tokens = 11
                     gen_ai.usage.output_tokens = 13
                     gen_ai.input.messages = "[{\"role\": \"user\", \"parts\": [{\"type\": \"text\", \"content\": \"How long is a gift card valid?\"}]}]"
                     gen_ai.output.messages = "[{\"role\": \"assistant\", \"parts\": [{\"type\": \"text\", \"content\": \"Marginalia gift cards are valid for one year from purchase.\"}], \"finish_reason\": \"stop\"}]"
                     gen_ai.response.finish_reasons = ["stop"]
                     gen_ai.response.id = "chatcmpl-lab0016"
                     gen_ai.response.model = "extract-1"
```

Mesma chamada, e agora `gen_ai.request.model` e `gen_ai.usage.input_tokens`, que qualquer ferramenta
que leia a convenção do OpenTelemetry entende. Espere que configurações assim mudem de nome e de
padrão de uma versão para a outra enquanto a convenção for nova; leia o span depois de toda
atualização.

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
