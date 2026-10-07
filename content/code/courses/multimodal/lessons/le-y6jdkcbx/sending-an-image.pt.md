---
title: Uma mensagem com uma imagem dentro
version: 2
---

Nas APIs da OpenAI uma imagem é **uma parte de uma mensagem do usuário**, ao lado do texto que pergunta sobre ela. O modelo lê as duas juntas. No Chat Completions, a parte tem o tipo `image_url`.

`vision.py`, o mesmo pedido que o `ask.py` da aula 2 fazia, com as contagens de tokens impressas:

```python
"""Send one picture and one question to a vision model, through Chat Completions."""
import base64
import sys

from openai import OpenAI

path, question = sys.argv[1], sys.argv[2]
kind = "png" if path.endswith(".png") else "jpeg"
data = base64.b64encode(open(path, "rb").read()).decode()
client = OpenAI()
reply = client.chat.completions.create(
    model="qwen2.5vl:3b", temperature=0, seed=1,
    messages=[{"role": "user", "content": [
        {"type": "text", "text": question},
        {"type": "image_url", "image_url": {"url": f"data:image/{kind};base64,{data}"}},
    ]}],
)
print(reply.choices[0].message.content)
print(f"[{reply.usage.prompt_tokens} tokens in, {reply.usage.completion_tokens} out]")
```

```
ana@lab:~/mm$ python vision.py media/cover-b39.png "Describe this cover for a blind customer."
The cover of the book "Dom Casmurro" by Machado de Assis features a minimalist design with a dark blue background. The title "DOM CASMURRO" is prominently displayed in large, white capital letters at the top of the cover. Below the title, the author's name, "Machado de Assis," is written in smaller white capital letters. The most striking element is the large, white circle located above the title, which adds a sense of balance and visual interest to the design. At the bottom of the cover, the publisher's name, "Marginalia Classics," is written in small white capital letters. The overall design is clean and modern, making it accessible to blind customers who rely on visual cues to identify books.
[1109 tokens in, 156 out]
```

**A resposta é do qwen2.5vl:3b**, e vale lê-la do jeito que um cliente cego a ouviria. Desta vez a lua está lá, como *a large, white circle*; a casa com as duas janelas acesas, a maior forma da capa, não é mencionada. As cores estão erradas com confiança de novo, como na aula 2, e a última frase chama o design de *accessible to blind customers who rely on visual cues*, o que não descreve ninguém. Uma descrição para quem não vê a imagem tem regras próprias, e a aula 14 trata delas.

A última linha é o que o pedido custou: **1.109 tokens de entrada**, quase todos da imagem, e 156 de saída. Essas são as contagens do Ollama para este modelo. Como um provedor transforma uma imagem em tokens é uma regra dele, e a próxima seção trata da regra da OpenAI.

## Dois jeitos de entregar a imagem

**Uma data URL**, como acima: os bytes do arquivo codificados em base64, dentro do pedido. Nada precisa ser publicado em lugar nenhum, o que é o certo para a foto de um cliente ou a nota de um fornecedor. O custo é o tamanho:

```
ana@lab:~/mm$ python -c "import base64; raw = open(\"media/invoice-0931.png\", \"rb\").read(); print(len(raw), len(base64.b64encode(raw)), round(len(base64.b64encode(raw)) / len(raw), 3))"
87530 116708 1.333
```

A nota de 87.530 bytes vira 116.708 caracteres, **um terço maior**, porque o base64 gasta quatro caracteres a cada três bytes.

**Uma URL que o provedor busca.** O pedido fica pequeno e o provedor baixa a imagem. Isso só funciona se o provedor alcança a URL, o que quer dizer que a imagem é pública, ou está atrás de um link assinado que expira. Aqui está a Responses API, a interface mais nova da OpenAI, tentando a capa primeiro como URL e depois como dados:

`respond.py`:

```python
"""The same question through the Responses API: the picture given as a URL, then as data."""
import base64

from openai import BadRequestError, OpenAI

client = OpenAI()
data = "data:image/png;base64," + base64.b64encode(open("media/cover-b39.png", "rb").read()).decode()
for image in ("http://localhost:8000/media/cover-b39.png", data):
    try:
        response = client.responses.create(model="qwen2.5vl:3b", temperature=0, input=[{"role": "user", "content": [
            {"type": "input_text", "text": "List every piece of text on the cover, exactly as written."},
            {"type": "input_image", "image_url": image},
        ]}])
        print(f"{image[:30]}... -> {response.output_text!r}")
        print(f"[{response.usage.input_tokens} tokens in, {response.usage.output_tokens} out]")
    except BadRequestError as e:
        print(f"{image} -> {e.status_code} {e.message}")
```

```
ana@lab:~/mm$ python respond.py
http://localhost:8000/media/cover-b39.png -> 400 Error code: 400 - {'error': {'message': 'image URLs are not currently supported, please use base64 encoded data instead', 'type': 'invalid_request_error', 'param': None, 'code': None}}
data:image/png;base64,iVBORw0K... -> 'DOM CASMURRO\nMachado de Assis\nMarginalia Classics'
[1114 tokens in, 18 out]
```

**O Ollama recusou a URL** antes de fazer qualquer coisa com ela: *image URLs are not currently supported, please use base64 encoded data instead*. Nada escutava naquele endereço, e nada precisava escutar, que é a parte útil: se um provedor busca uma URL ou não é uma regra dele, e o da OpenAI busca onde o Ollama não busca. A mesma imagem como dados voltou com as suas três linhas de texto, exatas.

Na Responses API as partes são `input_text` e `input_image`, e a imagem é uma string simples, uma URL ou uma data URL. A imagem custou 1.114 tokens aqui contra 1.109 pelo Chat Completions: a mesma imagem, com outra pergunta ao lado. O jeito de entregar a imagem muda o tamanho do pedido, não o que o modelo cobra para lê-la.

Os formatos aceitos são os comuns (PNG, JPEG, WEBP e GIF sem animação). Qualquer outro é convertido antes, pelo Pillow ou pelo ffmpeg, que é também a hora de redimensioná-lo (seção 03).
