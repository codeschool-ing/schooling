---
title: Uma mensagem com uma imagem dentro
version: 1
---

Nas APIs da OpenAI uma imagem é **uma parte de uma mensagem do usuário**, ao lado do texto que pergunta sobre ela. O modelo lê as duas juntas. No Chat Completions, a parte tem o tipo `image_url`:

```python
"""Send one picture and one question to a vision model, through Chat Completions."""
import base64
import sys

from openai import OpenAI

path, question = sys.argv[1], sys.argv[2]
detail = sys.argv[3] if len(sys.argv) > 3 else "auto"
kind = "png" if path.endswith(".png") else "jpeg"
data = base64.b64encode(open(path, "rb").read()).decode()

client = OpenAI()
reply = client.chat.completions.create(
    model="lab-vision-1",
    messages=[{"role": "user", "content": [
        {"type": "text", "text": question},
        {"type": "image_url", "image_url": {"url": f"data:image/{kind};base64,{data}", "detail": detail}},
    ]}],
)
print(reply.choices[0].message.content)
print(f"[{reply.usage.prompt_tokens} tokens in, {reply.usage.completion_tokens} out]")
```

```
ana@lab:~/mm$ python look.py media/cover-b39.png "Describe this cover for a blind customer."
A book cover on a dark navy background. At the top right is a pale yellow full moon. The title, DOM CASMURRO, is set in large cream serif capitals, with Machado de Assis in smaller letters below it. Under the text is a dark rectangular shape with two gold rectangles in it, like a building with two lit windows, standing on a thin cream line. At the bottom: Marginalia Classics.
[776 tokens in, 87 out]
```

**A resposta acima foi escrita pelo curso.** O `lab-vision-1` do labmm casou o SHA-256 da capa e as palavras *Describe this cover* com uma regra em `lab/scripted/08-vision-api.json` e devolveu a descrição escrita lá. Tudo em volta é real: o SDK montou o pedido que um endpoint real receberia, e o labmm contou a entrada pela regra que um endpoint real publica. A resposta tem o formato de uma boa resposta para um cliente cego, e a aula 14 pergunta o que uma descrição dessas deve a ele.

## Dois jeitos de entregar a imagem

**Uma data URL**, como acima: os bytes do arquivo codificados em base64, dentro do pedido. Nada precisa ser publicado em lugar nenhum, o que é o certo para a foto de um cliente ou a nota de um fornecedor. O custo é o tamanho:

```
ana@lab:~/mm$ python -c "import base64; raw = open(\"media/invoice-0931.png\", \"rb\").read(); print(len(raw), len(base64.b64encode(raw)), round(len(base64.b64encode(raw)) / len(raw), 3))"
87530 116708 1.333
```

A nota de 87.530 bytes vira 116.708 caracteres, **um terço maior**, porque o base64 gasta quatro caracteres a cada três bytes.

**Uma URL que o provedor busca.** O pedido fica pequeno e o provedor baixa a imagem. Isso só funciona se o provedor alcança a URL, o que quer dizer que a imagem é pública, ou está atrás de um link assinado que expira. Aqui está a Responses API, a interface mais nova da OpenAI, com a capa dada como uma URL que o labmm serve:

```python
"""The same question through the Responses API, with the picture given as a URL."""
from openai import OpenAI

client = OpenAI()
response = client.responses.create(
    model="lab-vision-1",
    input=[{"role": "user", "content": [
        {"type": "input_text", "text": "List every piece of text on the cover, exactly as written."},
        {"type": "input_image", "image_url": "http://127.0.0.1:8700/files/cover-b39.png"},
    ]}],
)
print(response.output_text)
print(f"[{response.usage.input_tokens} tokens in, {response.usage.output_tokens} out]")
```

```
ana@lab:~/mm$ python look_url.py
DOM CASMURRO
Machado de Assis
Marginalia Classics
[781 tokens in, 16 out]
ana@lab:~/mm$ tail -n 2 /var/log/labmm/requests.jsonl | python -c "import json, sys; [print(r[\"path\"], r[\"images\"], r[\"rule\"]) for r in map(json.loads, sys.stdin)]"
/v1/chat/completions [{'bytes': 19605, 'width': 600, 'height': 900, 'detail': 'auto', 'tokens': 765, 'tiles': 4, 'sha256': '88a80dab896d'}] l08-cover-describe
/v1/responses [{'bytes': 19605, 'width': 600, 'height': 900, 'detail': 'auto', 'tokens': 765, 'tiles': 4, 'sha256': '88a80dab896d'}] l08-cover-text
```

Na Responses API as partes são `input_text` e `input_image`, e a URL da imagem é uma string simples. O registro do labmm mostra a mesma imagem chegando dos dois jeitos: 600 por 900 pixels, 19.605 bytes, e **765 tokens** nas duas vezes. O jeito de entregar a imagem muda o tamanho do pedido, não o que o modelo cobra para lê-la.

Os formatos aceitos são os comuns (PNG, JPEG, WEBP e GIF sem animação). Qualquer outro é convertido antes, pelo Pillow ou pelo ffmpeg, que é também a hora de redimensioná-lo (seção 03).
