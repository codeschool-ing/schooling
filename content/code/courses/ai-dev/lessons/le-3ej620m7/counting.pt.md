---
title: Contar antes de enviar
version: 2
---

Para saber se uma requisição cabe, e quanto vai custar, você precisa da contagem de tokens
**antes** de ela sair. A aula 1 seção 07 mostrou que uma contagem pertence a um tokenizador, e que
só a OpenAI publica os tokenizadores dela. Então há dois jeitos de contar, e eles respondem a
perguntas um pouco diferentes:

- **localmente, com uma biblioteca de tokenizador**: rápido, grátis, offline, e exato só para os
  modelos a que aquele tokenizador pertence;
- **perguntando a quem roda o modelo**: o endpoint `count_tokens` da Anthropic recebe o mesmo corpo
  de uma requisição e devolve o número que a conta vai usar, sem gerar nada, e a API do Google
  também tem uma chamada de contagem. Elas custam uma ida e volta pela rede, e chamadas de contagem
  têm limites de taxa próprios. **O Ollama não tem esse endpoint.** O jeito de perguntar a ele é
  mandar a requisição com `max_tokens=1` e ler o `usage`, o que custa um token gerado: nada na sua
  própria máquina, e o preço de um token num provedor que tem uma chamada de contagem, que é a que
  você deve usar.

## A diferença não é só o tokenizador

O `~/shop/scratch/count.py` conta uma pergunta com o `tiktoken`, e depois pergunta ao Ollama sobre a
mesma pergunta de três jeitos: sozinha, com o `CONVENTIONS.md` do projeto como prompt de sistema, e
com uma definição de ferramenta.

```python
import anthropic
import tiktoken

client = anthropic.Anthropic()
enc = tiktoken.get_encoding("o200k_base")
question = "Why does a 210.00 cart with WELCOME10 pay shipping?"
system = open("CONVENTIONS.md").read()
tool = {"name": "get_cart", "description": "Read a customer's cart by its id.",
        "input_schema": {"type": "object", "properties": {"cart_id": {"type": "string"}},
                         "required": ["cart_id"]}}
cases = [("question only", {}),
         ("with the conventions as system prompt", {"system": system}),
         ("with one tool definition", {"tools": [tool]})]
print(f"tiktoken on the question alone: {len(enc.encode(question))}")
for label, extra in cases:
    r = client.messages.create(model="llama3.2:3b", max_tokens=1,
                               messages=[{"role": "user", "content": question}], **extra)
    print(f"{r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0):5}  {label}")
```

```
ana@dev:~/shop$ python scratch/count.py
tiktoken on the question alone: 15
   40  question only
  418  with the conventions as system prompt
  168  with one tool definition
```

O `tiktoken` diz 15 e o modelo leu 40 para a mesma pergunta. Parte da diferença é o tokenizador,
já que o `o200k_base` é o da OpenAI e o deste modelo é o da Meta. A maior parte é **o embrulho em
volta da mensagem**, que o modelo lê e a conta conta. O Ollama mostra: todo modelo traz um
**template de conversa**, o texto que transforma uma lista de mensagens na única string que o
modelo continua.

```
ana@dev:~/shop$ ollama show llama3.2:3b --template | head -n 12
<|start_header_id|>system<|end_header_id|>

Cutting Knowledge Date: December 2023

{{ if .System }}{{ .System }}
{{- end }}
{{- if .Tools }}When you receive a tool call response, use the output to format an answer to the orginal user question.

You are a helpful assistant with tool calling capabilities.
{{- end }}<|eot_id|>
{{- range $i, $_ := .Messages }}
{{- $last := eq (len (slice $.Messages $i)) 1 }}
```

Os cabeçalhos que marcam quem está falando são tokens. Também é uma linha que ninguém pediu,
`Cutting Knowledge Date: December 2023`, que este template escreve em toda requisição: o corte de
treino do modelo, da aula 1 seção 11, dito ao modelo a cada turno. Os provedores reais embrulham
as mensagens do mesmo jeito, não publicam exatamente como, e é por isso que **a contagem de quem
roda o modelo é a confiável**. Contar o texto você mesmo dá uma boa estimativa do texto e perde o
embrulho.

As outras duas linhas são as que surpreendem:

- **O prompt de sistema é pago em toda requisição.** 378 tokens a mais pelo `CONVENTIONS.md`, que
  é uma página de texto, em toda pergunta que alguém fizer. A aula 2 seção 07 mostra como pagar
  menos por um prompt de sistema que nunca muda.
- **Ferramentas também são texto.** Uma ferramenta com um parâmetro acrescentou 128 tokens: o nome,
  a descrição e o esquema JSON dela são escritos no prompt, e o template de cima acrescenta um
  parágrafo de instruções sobre como chamá-la. Um agente com trinta ferramentas (aula 7) pode gastar
  milhares de tokens descrevendo-as antes de a conversa começar.

## Onde a contagem fica no código

Conte uma vez, na função que envia a requisição, e guarde o número:

- **antes de enviar**, para recusar uma requisição que não cabe ou passa de um orçamento (aula 2
  seção 09);
- **depois da resposta**, leia o `usage` da resposta em vez de contar de novo. É o número do próprio
  provedor para o que foi cobrado, incluindo a saída, que nada conseguiria contar antes.

```python
r = client.messages.create(model=model, max_tokens=300, messages=messages)
log.info("tokens", extra={"in": r.usage.input_tokens, "out": r.usage.output_tokens})
```

**Registre o `usage` em toda chamada desde o primeiro dia.** Quando a fatura chega, a pergunta é
que funcionalidade gastou, e o único dado que responde isso é o uso que você registrou por
requisição.
