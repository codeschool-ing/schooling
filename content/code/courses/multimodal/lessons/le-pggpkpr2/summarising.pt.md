---
title: Resumindo: o que entregar ao modelo
version: 1
---

O resumo de um vídeo é escrito por um modelo de linguagem, e a decisão que importa é **o que você dá a ele para ler**. Há três opções, e os custos não são parecidos:

Os números de imagem vêm da regra que a OpenAI publicou para o GPT-4o, escrita como um módulo pequeno que as aulas 8 e 13 usam de novo. A aula 8 explica a regra passo a passo.

`tokens.py`:

```python
"""What a picture costs a vision model, by the rules OpenAI published for GPT-4o and Google for Gemini."""
import math


def gpt4o_tokens(w, h, detail="high"):
    """85 for the picture, plus 170 for every 512-pixel tile after two resizes: (tokens, tiles)."""
    if detail == "low":                       # one small copy of the picture, whatever its size
        return 85, 0
    if max(w, h) > 2048:                      # first, fit inside 2048 x 2048
        s = 2048 / max(w, h)
        w, h = int(w * s), int(h * s)
    if min(w, h) > 768:                       # then shrink until the short side is 768
        s = 768 / min(w, h)
        w, h = int(w * s), int(h * s)
    tiles = math.ceil(w / 512) * math.ceil(h / 512)
    return 85 + 170 * tiles, tiles


def gemini_tokens(w, h):
    """258 for a picture with both sides at most 384, otherwise 258 for every 768-pixel tile."""
    if w <= 384 and h <= 384:
        return 258
    return 258 * math.ceil(w / 768) * math.ceil(h / 768)
```

`budget.py`, que só conta:

```python
"""What each way of handing this video to a model would cost, in input tokens."""
import json

import tiktoken
from tokens import gpt4o_tokens

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

Por essa regra, um quadro de 1280 por 720 são seis blocos de 512 pixels, 85 + 6 × 170 = 1.105 tokens em alto detalhe, e 85 em baixo detalhe, em que o modelo vê uma cópia pequena. Nada foi enviado a lugar nenhum; o programa só conta.

- **Todos os quadros** são 900.575 tokens em alto detalhe, para um vídeo de 32 segundos. Ninguém faz isso, e o número está aqui para mostrar por quê.
- **Um quadro por segundo** são 36.465 tokens, e perdeu o cartão.
- **Um quadro por cena** são 7.735 tokens e viu todos os slides.
- **A linha do tempo em texto** são 334 tokens. Ela guarda todo título e toda palavra dita.

**Para um vídeo feito de slides e fala, a linha do tempo é o que se manda**: 23 vezes mais barata que os quadros de cena e sem perder nada que importe, porque os slides são texto e o OCR já os leu. Acrescente quadros só para o que o texto não carrega: um gráfico, uma fotografia, a aparência de um livro danificado. Em baixo detalhe um quadro custa 85 tokens, então um ou dois quadros ao lado da linha do tempo saem baratos.

Modelos que recebem vídeo diretamente, como o Gemini, fazem a amostragem sozinhos; a documentação do Google descreve amostrar um quadro por segundo por padrão. É prático e é a regra de taxa fixa da seção 03, com o seu ponto cego: um cartão mostrado por 0,4 segundo também se perderia ali.

## Como fica um resumo feito desta linha do tempo

A linha do tempo é texto, então qualquer modelo de linguagem consegue resumi-la, e o modelo de texto do curso, o `llama3.2:3b`, roda na sua máquina. `temperature=0` e uma `seed` fixa fazem ele dar a mesma resposta toda vez numa mesma máquina; na sua, as palavras ainda podem mudar, e o que importa são as conferências abaixo.

`summary.py`:

```python
"""A summary of the returns video, written by llama3.2:3b from the timeline alone."""
import json

from openai import OpenAI

timeline = json.load(open("timeline.json"))
reply = OpenAI().chat.completions.create(
    model="llama3.2:3b", temperature=0, seed=1,
    messages=[{"role": "system", "content": "Summarise this video for a customer in one paragraph. "
                                            "Use only what the timeline says was shown or said."},
              {"role": "user", "content": json.dumps(timeline)}])
print(reply.choices[0].message.content)
```

```
ana@lab:~/mm$ python summary.py
Here's a summary of the video for a customer: To return a book purchased from Marginelia, follow these four easy steps. First, open the order and sign it, then choose a reason for return from the list. Next, print the prepared label and tape it over the old address. Finally, drop the parcel off at any post office and keep the receipt until your refund arrives, which will be credited back to the original payment card, including any shipping costs.
```

**Confira um resumo contra a linha do tempo, linha por linha.** Toda afirmação daquele parágrafo deveria apontar para uma entrada, e este mostra os dois jeitos como um resumo erra sem uma única frase que pareça errada.

**Ele repetiu os erros das suas fontes.** *Marginelia* é a grafia do Whisper, não a da loja, embora o título do primeiro slide a traga certa. *Prepared label* também é do Whisper, no lugar de *prepaid*. E *open the order and sign it* é o modelo tentando dar sentido ao *sign and end open the order* do Whisper: uma frase truncada na entrada, uma instrução errada e confiante na saída. A linha do tempo manteve os dois fluxos lado a lado, e o modelo ficou com o falado todas as vezes.

**Ele deixou de fora o que só foi mostrado.** Nada sobre o código RETURN30, os 30 dias ou a etiqueta que vale por 7 dias, e tudo isso está nas entradas `shown` da linha do tempo. E ele esticou a única condição que manteve: o vídeo devolve o frete de um livro *danificado*, e o resumo diz que todo reembolso inclui *any shipping costs*. Esse é o erro com que um cliente agiria.

As soluções são conferências, não um prompt melhor: peça cada afirmação com o tempo de onde ela vem, e compare os fatos do resumo com o texto dos slides, que o OCR já tem. A aula 14 precisa da mesma disciplina para as legendas.
