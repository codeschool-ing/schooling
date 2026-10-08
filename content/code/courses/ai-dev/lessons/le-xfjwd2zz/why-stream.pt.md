---
title: A espera que dá para encurtar
version: 2
---

Um modelo escreve a resposta um token por vez, e uma resposta longa leva segundos. **O streaming não
deixa a resposta mais rápida.** Ele muda quando o leitor vê a primeira palavra: assim que ela existe,
em vez de depois da última. Esta aula mede isso, lê o stream enquanto ele passa pelo fio, leva-o até
um navegador e trata os dois jeitos de um stream acabar antes da hora.

As respostas desta aula vêm do `llama3.2:3b` na máquina da gravação, a uns dez tokens por segundo,
devagar o bastante para a diferença ser difícil de não ver.

## A mesma resposta, duas vezes

```python
"""The same reply twice: once waited for, once streamed. When does the first word arrive?"""
import time

import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]

t0 = time.monotonic()
r = model.messages.create(model="llama3.2:3b", max_tokens=300, messages=ASK)
done = time.monotonic() - t0
print(f"create: first word after {done:.1f} s, all {r.usage.output_tokens} tokens after {done:.1f} s")

t0 = time.monotonic()
first = None
with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        if first is None:
            first = time.monotonic() - t0
    final = stream.get_final_message()
done = time.monotonic() - t0
print(f"stream: first word after {first:.1f} s, all {final.usage.output_tokens} tokens after {done:.1f} s")
```

```
ana@dev:~/shop$ python timing.py
create: first word after 13.6 s, all 132 tokens after 13.6 s
stream: first word after 0.3 s, all 154 tokens after 14.8 s
```

**Os totais são próximos**, 13,6 e 14,8 segundos, porque o modelo precisa de
mais ou menos o mesmo tempo para 132 tokens que para 154; as duas respostas são dois sorteios e não
têm o mesmo tamanho. O que mudou foi o primeiro número. Esperando, a primeira palavra chega junto com
a última, depois de treze segundos de nada. Em streaming, ela chega depois de três décimos de
segundo, e o leitor já está lendo enquanto o resto é escrito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Duas linhas do tempo de uma resposta de uns quinze segundos. Esperando, nada aparece até o fim, e então tudo de uma vez. Em streaming, a primeira palavra aparece depois de três décimos de segundo e o resto chega aos poucos até o mesmo fim.\"><defs><marker id=\"wt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"115\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">esperando</text><rect x=\"130\" y=\"40\" width=\"490\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"375.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nada na tela</text><rect x=\"620\" y=\"40\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"616\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">tudo de uma vez</text><text x=\"115\" y=\"112\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">em streaming</text><rect x=\"146.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"158.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"171.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"183.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"196.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"209.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"221.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"234.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"246.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"259.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"272.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"284.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"297.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"309.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"322.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"335.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"347.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"360.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"372.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"385.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"398.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"410.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"423.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"435.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"448.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"461.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"473.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"486.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"498.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"511.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"524.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"536.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"549.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"561.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"574.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"587.0\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"599.6\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"612.2\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"624.8\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"637.4\" y=\"100\" width=\"9\" height=\"24\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"146\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">primeira palavra, 0,3 s</text><path d=\"M654 34 L654 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"658\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14,8 s</text></svg>", "caption": "O streaming adianta a primeira palavra, não a última. O tempo total é do modelo, de um jeito ou de outro."}
```

## Dois números que vale registrar

- **Tempo até o primeiro token**: do envio da requisição ao primeiro pedaço de texto. É o que uma
  pessoa sente como "está pensando", e é sobretudo a fila do provedor e o tamanho do seu prompt, já
  que o modelo lê toda a entrada antes de escrever qualquer coisa.
- **Tempo total**: da requisição ao último pedaço. Ele cresce com o tamanho da resposta, e o
  streaming não faz nada por ele.

Um primeiro token lento com um total rápido apontam para a entrada: um prompt longo, um cache frio,
um modelo ocupado. Um primeiro token rápido com um total lento apontam para a saída: uma resposta
mais longa do que precisa, que o `max_tokens` e um prompt mais justo resolvem, como na aula 2.

## Quando não fazer streaming

**Streaming é para uma pessoa olhando.** Um programa que lê a resposta como JSON, como na aula 8,
não usa metade dela, e um job que registra chamados de madrugada não tem a quem mostrar a primeira
palavra. Para esses, uma requisição comum é código mais simples com o mesmo tempo total.
