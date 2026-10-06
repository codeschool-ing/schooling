---
title: Resumindo: o que entregar ao modelo
version: 1
---

O resumo de um vídeo é escrito por um modelo de linguagem, e a decisão que importa é **o que você dá a ele para ler**. Há três opções, e os custos não são parecidos:

```python
"""What each way of handing this video to a model would cost, in input tokens."""
import json

import tiktoken
from labmm import gpt4o_tokens

high, _ = gpt4o_tokens(1280, 720, "high")
low, _ = gpt4o_tokens(1280, 720, "low")
text = json.dumps(json.load(open("timeline.json")))
enc = tiktoken.get_encoding("o200k_base")
print(f"one 1280x720 frame: {high} tokens at high detail, {low} at low")
for name, frames in (("every frame", 815), ("one a second", 33), ("one per scene", 7)):
    print(f"{name:14} {frames:4} frames  {frames * high:7,} tokens high  {frames * low:6,} low")
print(f"{'the timeline':14} as text      {len(enc.encode(text)):7,} tokens")
```

```
ana@lab:~/mm$ python budget.py
one 1280x720 frame: 1105 tokens at high detail, 85 at low
every frame     815 frames  900,575 tokens high  69,275 low
one a second     33 frames   36,465 tokens high   2,805 low
one per scene     7 frames    7,735 tokens high     595 low
the timeline   as text          334 tokens
```

Os números de imagem vêm da regra de blocos que a OpenAI publicou para o GPT-4o, como implementada no substituto do laboratório: um quadro de 1280 por 720 são seis blocos de 512 pixels, 85 + 6 × 170 = 1.105 tokens em alto detalhe, e 85 em baixo detalhe, em que o modelo vê uma cópia pequena. Nada foi enviado a lugar nenhum; o programa só conta.

- **Todos os quadros** são 900.575 tokens em alto detalhe, para um vídeo de 32 segundos. Ninguém faz isso, e o número está aqui para mostrar por quê.
- **Um quadro por segundo** são 36.465 tokens, e perdeu o cartão.
- **Um quadro por cena** são 7.735 tokens e viu todos os slides.
- **A linha do tempo em texto** são 321 tokens. Ela guarda todo título e toda palavra dita.

**Para um vídeo feito de slides e fala, a linha do tempo é o que se manda**: 24 vezes mais barata que os quadros de cena e sem perder nada que importe, porque os slides são texto e o OCR já os leu. Acrescente quadros só para o que o texto não carrega: um gráfico, uma fotografia, a aparência de um livro danificado. Em baixo detalhe um quadro custa 85 tokens, então um ou dois quadros ao lado da linha do tempo saem baratos.

Modelos que recebem vídeo diretamente, como o Gemini, fazem a amostragem sozinhos; a documentação do Google descreve amostrar um quadro por segundo por padrão. É prático e é a regra de taxa fixa da seção 03, com o seu ponto cego: um cartão mostrado por 0,4 segundo também se perderia ali.

## Como fica um resumo feito desta linha do tempo

Nenhum modelo de linguagem roda neste laboratório. Abaixo está um resumo escrito pelo curso a partir da linha do tempo acima, para mostrar o formato, e não produzido por modelo algum:

> *Marginalia's returns video explains four steps: open the order under Account › Orders, press Return this item and choose a reason, print the prepaid label sent by e-mail and tape it over the old address, and drop the parcel at a post office, keeping the receipt. Refunds go to the card used; damaged books are refunded in full with shipping, within 30 days of delivery. A code, RETURN30, is shown briefly for customers who call.*

**Confira um resumo contra a linha do tempo, linha por linha.** Toda afirmação daquele parágrafo deveria apontar para uma entrada. *Within 30 days* e *RETURN30* vêm do que foi mostrado; *the card used* vem do que foi dito. E um detalhe está errado de um jeito que a linha do tempo revela: o OCR leu o código com a letra O, e um resumo que o "corrigiu" para zero fez isso por conta própria. Aqui o slide diz mesmo 30, então a correção está certa, e um resumidor que corrige a entrada em silêncio é um resumidor que um dia vai corrigi-la errado. A aula 14 precisa da mesma disciplina para legendas.
