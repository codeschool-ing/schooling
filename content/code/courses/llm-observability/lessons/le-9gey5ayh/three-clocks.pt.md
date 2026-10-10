---
title: Três relógios numa chamada
version: 2
---

Um pedido web tem uma latência: do pedido à resposta. Uma chamada a modelo em streaming tem três, e
elas respondem a perguntas diferentes, então um número só para "quanto o modelo levou" esconde a maior
parte do que importa.

O `stream.py` pede uma resposta em streaming e imprime o momento em que cada pedaço dela chegou:

```python
"""stream.py: one streamed reply, with the moment each piece arrived."""
import time

from openai import OpenAI

client = OpenAI()
start = time.monotonic()
stream = client.chat.completions.create(model="llama3.2:3b", temperature=0, stream=True, messages=[
    {"role": "user", "content": "[1] gift-cards.md\nGift cards are valid for two years from purchase "
     "and cannot be exchanged for cash.\n\nQuestion: How long is a gift card valid?"}])
last = None
for chunk in stream:
    for c in chunk.choices:
        if c.delta.content:
            now = (time.monotonic() - start) * 1000
            gap = f"+{now - last:.0f}" if last is not None else "first"
            print(f"{now:7.0f} ms  {gap:>6}  {c.delta.content!r}")
            last = now
```

```
ana@dev:~/obs$ python stream.py
    720 ms   first  'A'
    816 ms     +96  ' gift'
    912 ms     +96  ' card'
    998 ms     +87  ' is'
   1091 ms     +93  ' valid'
   1198 ms    +107  ' for'
   1304 ms    +106  ' two'
   1412 ms    +108  ' years'
   1524 ms    +112  ' from'
   1631 ms    +107  ' purchase'
   1739 ms    +108  '.'
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Um eixo de tempo de 0 a 1.800 ms. O pedido sai em 0. Nada chega até o primeiro pedaço, aos 720 ms. Depois disso chega um pedaço a cada 100 ms mais ou menos, onze ao todo, o último aos 1.739 ms. O trecho de 0 a 720 tem o rótulo tempo até o primeiro token; o trecho de 720 a 1.739, tempo por token de saída, vezes o número de tokens.\"><path d=\"M50 110 L680 110\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"50\" cy=\"110\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"50\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pedido enviado</text><rect x=\"299.0\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"332.6\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"366.2\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"396.3\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"428.8\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"466.3\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"503.4\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"541.2\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"580.4\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"617.8\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"655.6\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><path d=\"M50 136 L302.0 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M50 130 L50 142\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M302.0 130 L302.0 142\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"176.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">tempo até o primeiro token: 720 ms</text><path d=\"M302.0 80 L658.6 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M302.0 74 L302.0 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M658.6 74 L658.6 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"480.3\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">depois cerca de 100 ms por token, 11 pedaços</text><text x=\"658.6\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chamada inteira: 1.739 ms</text><path d=\"M50 170 L680 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M50.0 170 L50.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"50.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M155.0 170 L155.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"155.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300</text><path d=\"M260.0 170 L260.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"260.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600</text><path d=\"M365.0 170 L365.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"365.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">900</text><path d=\"M470.0 170 L470.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"470.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.200</text><path d=\"M575.0 170 L575.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"575.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.500</text><path d=\"M680.0 170 L680.0 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.800</text><text x=\"365\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">milissegundos desde que o pedido saiu</text></svg>", "caption": "Duas esperas diferentes. A primeira é o modelo lendo o prompt; a segunda cresce com o tamanho da resposta."}
```

**O tempo até o primeiro token**, 720 ms aqui, é quanto o cliente fica olhando para uma resposta
vazia. O modelo o gasta lendo o prompt e produzindo o primeiro token, e um fornecedor hospedado soma
o tempo que o pedido espera na fila dele; quanto mais longo o prompt, mais longa a leitura. Ele
decide se o assistente *parece* rápido, porque, uma vez que o texto começa a andar, quem lê está
lendo.

**O tempo por token de saída**, cerca de 100 ms aqui depois do primeiro, é a velocidade com que o
texto chega quando começa. É uma propriedade do modelo e da máquina que o roda, e de quão ocupada
ela está, e define quanto leva uma resposta longa: onze pedaços a 100 ms dão um segundo, cem dariam
dez.

**A chamada inteira**, 1.739 ms, é o primeiro mais o segundo vezes o número de tokens. Ela decide
por quanto tempo o pedido segura uma conexão, um worker e um lugar em qualquer limite de taxa, e é o
que a aplicação espera antes de poder verificar as citações ou guardar a resposta.

Esses são números de um processador: quatro núcleos e nenhuma placa de vídeo, rodando um modelo de
três bilhões de parâmetros. Um fornecedor hospedado, no hardware dele, é várias vezes mais rápido
nos dois relógios, e uma placa de vídeo na sua máquina também seria. **A forma é a mesma**, e é por
isso que vale medir cada relógio separadamente.

## No span

O assistente registra os três. O início e o fim do span dão a chamada inteira. O primeiro pedaço de
texto define `app.time_to_first_token_ms` e acrescenta um evento chamado `gen_ai.first_token` naquele
momento, para que uma ferramenta que desenhe o trace possa marcá-lo na barra. O tempo por token não é
registrado, porque é aritmética sobre os outros dois e a contagem de tokens de saída, e a próxima seção
o calcula para a semana inteira.

Registrar o primeiro token exige **streaming**. Uma chamada sem streaming devolve tudo de uma vez, e o
primeiro token e o último chegam no mesmo instante, até onde o cliente consegue ver. Esse é um dos
motivos de o assistente usar streaming mesmo onde nada mostra o texto enquanto ele chega: o relógio
vale a pena.
