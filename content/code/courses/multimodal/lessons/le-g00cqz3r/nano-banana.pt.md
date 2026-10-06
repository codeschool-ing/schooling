---
title: O modelo de imagem do Gemini, chamado Nano Banana
version: 1
---

**Nano Banana** é o apelido que ficou no Gemini 2.5 Flash Image do Google, o modelo de imagem lançado em 2025, e depois nos sucessores dele. Não é uma API separada. É um modelo Gemini chamado pelo mesmo `generate_content` do texto, pedindo que responda também com uma imagem:

```python
"""Gemini's image model: words in, and a picture and words out, in one call."""
from google import genai
from google.genai import types
from PIL import Image

client = genai.Client()
reply = client.models.generate_content(
    model="lab-flash-image",
    contents=["A poster for a second-hand book fair in a library courtyard, warm afternoon light"],
    config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
)
for part in reply.candidates[0].content.parts:
    if part.inline_data:
        open("poster.png", "wb").write(part.inline_data.data)
        print("image:", part.inline_data.mime_type, len(part.inline_data.data), "bytes", Image.open("poster.png").size)
    elif part.text:
        print("text: ", part.text)
u = reply.usage_metadata
print(f"tokens in {u.prompt_token_count}, out {u.candidates_token_count}")
```

```
ana@lab:~/mm$ python nano.py 2>/dev/null
text:  labmm has no reply written for this request. Its image replies are rules the course wrote, in lab/scripted/.
image: image/png 19775 bytes (1024, 1024)
tokens in 16, out 1314
```

A resposta volta como uma lista de **partes**: aqui uma parte de texto e uma de imagem, a imagem como bytes crus com um tipo MIME. As duas são do labmm: a imagem é um cartão, e o texto é o labmm dizendo que não tem regra para este prompt, o que é verdade. Uma resposta real do Gemini muitas vezes traz uma frase sobre o que desenhou ao lado da imagem, e um programa deve esperar qualquer uma das partes, as duas, ou só uma parte de texto quando o modelo se recusa a desenhar.

As contagens de tokens são do labmm, pelas regras publicadas pelo Google: o prompt custou 16 tokens de texto, e a resposta 1.314, dos quais **1.290 são a imagem**. O Google cobra a saída de imagem por token, e 1.290 tokens aos 30 dólares por milhão da tabela dão os mesmos 0,039 dólar por imagem que a tabela também lista (a aula 3 leu esse preço).

## Editando sem máscara

A diferença em relação à API da OpenAI que mais importa na prática é como uma edição é descrita. O Gemini recebe **a imagem e uma frase**, e a frase diz o que mudar:

```python
"""The same model with a picture in the request: an edit described in words, with no mask."""
from google import genai
from google.genai import types
from PIL import Image

client = genai.Client()
reply = client.models.generate_content(
    model="lab-flash-image",
    contents=[Image.open("media/cover-b39.png"), "Make the moon a thin crescent and keep everything else."],
    config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
)
u = reply.usage_metadata
images = [p for p in reply.candidates[0].content.parts if p.inline_data]
print(f"{len(images)} image back; tokens in {u.prompt_token_count}, out {u.candidates_token_count}")
```

```
ana@lab:~/mm$ python nano_edit.py 2>/dev/null
1 image back; tokens in 528, out 1314
```

Sem máscara, sem canal alfa, sem regra de mesmo tamanho: *make the moon a thin crescent and keep everything else*. A capa entrou como 528 tokens, 516 deles pela imagem, pela regra do Gemini de 258 por bloco de 768 pixels (a capa de 600 por 900 ocupa dois). É mais fácil de escrever e mais difícil de controlar. Uma máscara diz exatamente quais pixels podem mudar; uma frase diz o que uma pessoa quer e deixa o modelo decidir onde isso fica. Para um banner de produto que precisa manter os dois terços da esquerda idênticos, a máscara é a ferramenta mais segura; para "deixe mais claro" ou "tire a xícara", a frase dá muito menos trabalho.

## Qual modelo, e quando ele acaba

```
ana@lab:~/mm$ sheet where flash-image | grep -E "^(gemini|vertex_ai)/"
gemini/gemini-2.5-flash-image                        gemini                          0.3      2.5
gemini/gemini-3.1-flash-image                        gemini                          0.5        3
gemini/gemini-3.1-flash-image-preview                gemini                          0.5        3
vertex_ai/gemini-2.5-flash-image                     vertex_ai-language-models       0.3      2.5
vertex_ai/gemini-3.1-flash-image                     vertex_ai-language-models       0.5        3
vertex_ai/gemini-3.1-flash-image-preview             vertex_ai-language-models       0.5        3
ana@lab:~/mm$ for m in gemini/gemini-2.5-flash-image gemini/gemini-3.1-flash-image; do echo "$m"; sheet show $m | grep -E "output_cost_per_image |deprecation"; done
gemini/gemini-2.5-flash-image
deprecation_date                           2026-10-02
output_cost_per_image                      0.039
gemini/gemini-3.1-flash-image
output_cost_per_image                      0.045
```

**A entrada do Gemini 2.5 Flash Image traz uma data de descontinuação em 2 de outubro de 2026**, quatro dias antes do calendário do laboratório, e o sucessor, o 3.1, aparece a 0,045 dólar por imagem. Os hábitos da seção 03 valem aqui sem mudança.
