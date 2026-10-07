---
title: A Images API da OpenAI
version: 1
---

A **Images API** da OpenAI tem três rotas: `generations` (uma imagem a partir de um prompt), `edits` (uma imagem alterada, opcionalmente dentro de uma máscara) e, para o modelo mais antigo, `variations`. Cada uma recebe um nome de modelo, um prompt e algumas configurações, e devolve a imagem na resposta em base64. Como na aula 3, os pedidos daqui vão para o substituto do curso, então inicie `python images_server.py` num segundo terminal antes; com uma chave sua, a linha do `base_url` é a que muda. O banner da aula 3, em código:

```python
"""Ask the Images API for one banner and keep it, with a record of what asked for it."""
import base64
import json
import sys
from datetime import datetime

from openai import OpenAI
from PIL import Image

PROMPT = ("a stack of second-hand books on a café table, watercolour illustration, loose brushwork, "
          "wide banner, books on the left third, empty space on the right")
size = sys.argv[1] if len(sys.argv) > 1 else "1536x1024"
client = OpenAI(base_url="http://localhost:8800/v1")   # lesson 3's images_server.py
try:
    result = client.images.generate(model="gpt-image-1", prompt=PROMPT, size=size, quality="medium",
                                    output_format="png", n=1)
except Exception as e:
    sys.exit(f"{type(e).__name__}: {e}")
raw = base64.b64decode(result.data[0].b64_json)
open("banner.png", "wb").write(raw)
json.dump({"model": "gpt-image-1", "prompt": PROMPT, "size": size, "quality": "medium",
           "made": datetime.now().isoformat(timespec="seconds"), "approved_by": None},
          open("banner.json", "w"), indent=1)
print(f"banner.png: {len(raw):,} bytes, {Image.open('banner.png').size[0]}x{Image.open('banner.png').size[1]}")
```

```
ana@lab:~/mm$ python banner.py
banner.png: 35,712 bytes, 1536x1024
ana@lab:~/mm$ python banner.py 1792x1024
BadRequestError: Error code: 400 - {'error': {'message': "Invalid value: '1792x1024'. Supported values are: 'auto', '1024x1024', '1024x1536', '1536x1024'", 'type': 'invalid_request_error', 'param': 'size', 'code': None}}
ana@lab:~/mm$ cat banner.json; echo
{
 "model": "gpt-image-1",
 "prompt": "a stack of second-hand books on a caf\u00e9 table, watercolour illustration, loose brushwork, wide banner, books on the left third, empty space on the right",
 "size": "1536x1024",
 "quality": "medium",
 "made": "2026-10-07T13:25:28",
 "approved_by": null
}
```

**A imagem é um cartão que diz que nenhum modelo a desenhou**: o pedido foi para o `images_server.py` da aula 3, que não tem modelo de imagem por trás. O pedido, as configurações, a validação e o arquivo no disco são reais.

As configurações que importam:

- **`size`** é uma escolha de uma lista, não qualquer largura e altura. O substituto aceita os quatro valores que a OpenAI documenta para os seus modelos de imagem GPT, `auto`, `1024x1024`, `1024x1536` e `1536x1024`, e recusou `1792x1024` com um 400 que cita os válidos. (`1792x1024` era um tamanho do DALL-E 3, e é assim que código escrito para um modelo quebra no seguinte.)
- **`quality`** (`low`, `medium`, `high`) é a configuração que mais mexe no preço: a seção 06 mostra um fator de quinze.
- **`n`** pede várias imagens numa chamada, que é como a aula 3 viu a variação de um prompt.
- **`output_format`** (`png`, `jpeg`, `webp`) decide o arquivo; o PNG preserva transparência.

**O registro ao lado da imagem** é a linha que faz disto código de produção e não uma demonstração: o `banner.json` guarda o modelo, o prompt, as configurações, a hora em que foi feito e quem aprovou (ninguém ainda: `null`). A aula 3 defendeu esse registro; aqui ele é escrito pelo mesmo programa que fez a imagem, então não tem como ser esquecido.
