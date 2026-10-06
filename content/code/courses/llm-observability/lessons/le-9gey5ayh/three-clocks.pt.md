---
title: Três relógios numa chamada
version: 1
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
stream = client.chat.completions.create(model="extract-1", stream=True, messages=[
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
ana@lab:~/obs$ python stream.py
    244 ms   first  'Gift'
    262 ms     +17  ' cards'
    286 ms     +24  ' are'
    309 ms     +24  ' valid'
    333 ms     +24  ' for'
    357 ms     +24  ' two'
    381 ms     +24  ' years'
    404 ms     +24  ' from'
    428 ms     +24  ' purchase'
    452 ms     +24  ' and'
    476 ms     +24  ' cannot'
    500 ms     +24  ' be'
    524 ms     +24  ' exchanged'
    548 ms     +24  ' for'
    571 ms     +24  ' cash'
    595 ms     +24  '.'
    619 ms     +24  ' ['
    643 ms     +24  '1'
    667 ms     +24  ']'
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Um eixo de tempo de 0 a 700 ms. O pedido sai em 0. Nada chega até o primeiro pedaço, aos 244 ms. Depois disso chega um pedaço a cada 24 ms mais ou menos, dezenove ao todo, o último aos 667 ms. O trecho de 0 a 244 tem o rótulo tempo até o primeiro token; o trecho de 244 a 667, tempo por token de saída, vezes o número de tokens.\"><path d=\"M50 110 L680 110\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"50\" cy=\"110\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"50\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pedido enviado</text><rect x=\"266.6\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"282.8\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"304.4\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"325.1\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"346.7\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"368.3\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"389.9\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"410.6\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"432.2\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"453.8\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"475.4\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"497\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"518.6\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"540.2\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"560.9\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"582.5\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"604.1\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"625.7\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"647.3\" y=\"101\" width=\"6\" height=\"18\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><path d=\"M50 136 L269.6 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M50 130 L50 142\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M269.6 130 L269.6 142\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"159.8\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">tempo até o primeiro token: 244 ms</text><path d=\"M269.6 80 L650.3 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M269.6 74 L269.6 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M650.3 74 L650.3 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"459.5\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">depois cerca de 24 ms por token, 19 pedaços</text><text x=\"650.3\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chamada inteira: 667 ms</text><path d=\"M50 170 L50 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"50\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M140 170 L140 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"140\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M230 170 L230 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"230\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><path d=\"M320 170 L320 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"320\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300</text><path d=\"M410 170 L410 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"410\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400</text><path d=\"M500 170 L500 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"500\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">500</text><path d=\"M590 170 L590 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"590\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600</text><path d=\"M680 170 L680 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">700</text><path d=\"M50 170 L680 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"365\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">milissegundos desde que o pedido saiu</text></svg>", "caption": "Duas esperas diferentes. A primeira é o fornecedor enfileirando o pedido e lendo o prompt; a segunda cresce com o tamanho da resposta."}
```

**O tempo até o primeiro token**, 244 ms aqui, é quanto o cliente fica olhando para uma resposta vazia.
Um fornecedor o gasta enfileirando o pedido, lendo o prompt e produzindo o primeiro token; quanto mais
longo o prompt, mais longa a leitura. É ele que decide se o assistente *parece* rápido, porque, quando o
texto começa a correr, quem lê está lendo.

**O tempo por token de saída**, cerca de 24 ms aqui depois do primeiro, é a velocidade com que o texto
chega depois de começar. É uma propriedade do modelo e de quão ocupado está o fornecedor, e define
quanto leva uma resposta longa: dezenove pedaços a 24 ms dão uns 420 ms, cem passariam de dois
segundos.

**A chamada inteira**, 667 ms, é o primeiro mais o segundo vezes o número de tokens. Ela decide por
quanto tempo o pedido segura uma conexão, um worker e um lugar em qualquer limite de taxa, e é o que a
aplicação espera antes de poder conferir citações ou guardar a resposta.

Os dois primeiros são as regras do labobs aparecendo: 180 ms mais um pouco por token de entrada antes
do primeiro, 25 ms por token depois dele, os dois multiplicados por um fator sorteado por pedido. Os
números de um fornecedor real são maiores ou menores e variam mais; **a forma é a mesma**, e é por isso
que vale medir cada relógio separadamente.

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
