---
title: Editando com uma máscara
version: 1
---

A aula 3 argumentou que uma imagem quase certa deve ser **editada, não gerada de novo**. Na Images API uma edição é a imagem original, uma **máscara** e um prompt para o que vai na parte mascarada. A máscara é um PNG do mesmo tamanho da imagem, com canal alfa: **pixels transparentes marcam onde o modelo pode desenhar, e os opacos ficam**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três retângulos com o mesmo formato 3 por 2. O banner, com uma pilha de livros esboçada à esquerda. A máscara, sólida nos dois terços da esquerda e transparente no terço da direita. O banner editado, com os dois terços da esquerda iguais e só o terço da direita repintado.\"><defs><marker id=\"l09msk-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">banner.png</text><rect x=\"20\" y=\"34\" width=\"180\" height=\"120\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"34\" y=\"120\" width=\"70\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"34\" y=\"104\" width=\"64\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"34\" y=\"88\" width=\"58\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"34\" y=\"72\" width=\"52\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"210\" y1=\"94\" x2=\"260\" y2=\"94\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l09msk-ah-phosphor)\"></line><text x=\"270\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mask.png</text><rect x=\"270\" y=\"34\" width=\"120.0\" height=\"120\" rx=\"0\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></rect><rect x=\"390.0\" y=\"34\" width=\"60.0\" height=\"120\" rx=\"0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"420.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">vazio</text><text x=\"330.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--ink)\">opaco</text><line x1=\"460\" y1=\"94\" x2=\"510\" y2=\"94\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l09msk-ah-phosphor)\"></line><text x=\"520\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a edição</text><rect x=\"520\" y=\"34\" width=\"180\" height=\"120\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"534\" y=\"120\" width=\"70\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"534\" y=\"104\" width=\"64\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"534\" y=\"88\" width=\"58\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"534\" y=\"72\" width=\"52\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"640.0\" y=\"34\" width=\"60.0\" height=\"120\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"670.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">novo</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Pixels transparentes na máscara dizem onde o modelo pode desenhar; tudo o que é opaco fica.</text></svg>", "caption": "Uma edição mantém o que estava certo e redesenha só a região mascarada, o que uma nova geração não consegue."}
```

```python
"""A mask for the edits endpoint: opaque where the picture stays, transparent where it may change."""
from PIL import Image, ImageDraw

banner = Image.open("banner.png")
w, h = banner.size
mask = Image.new("RGBA", (w, h), (0, 0, 0, 255))
ImageDraw.Draw(mask).rectangle([w * 2 // 3, 0, w, h], fill=(0, 0, 0, 0))
mask.save("mask.png")
wrong = Image.new("RGBA", (1024, 1024), (0, 0, 0, 255))
wrong.save("mask-wrong-size.png")
print("mask.png", mask.size, mask.mode, "| mask-wrong-size.png", wrong.size)
```

```python
"""Repaint only the masked part of the banner."""
import base64
import sys

from openai import OpenAI

client = OpenAI(base_url="http://localhost:8800/v1")   # lesson 3's images_server.py
try:
    result = client.images.edit(model="gpt-image-1", image=open("banner.png", "rb"), mask=open(sys.argv[1], "rb"),
                                prompt="the same café table, with a small pot of basil on the right")
except Exception as e:
    print(type(e).__name__, e)
else:
    open("banner-edited.png", "wb").write(base64.b64decode(result.data[0].b64_json))
    print("banner-edited.png written")
```

```
ana@lab:~/mm$ python mask.py
mask.png (1536, 1024) RGBA | mask-wrong-size.png (1024, 1024)
ana@lab:~/mm$ python edit.py mask.png
banner-edited.png written
ana@lab:~/mm$ python edit.py mask-wrong-size.png
BadRequestError Error code: 400 - {'error': {'message': 'The mask must be the same size as the image: the image is 1536x1024 and the mask 1024x1024.', 'type': 'invalid_request_error', 'param': 'mask', 'code': None}}
ana@lab:~/mm$ python edit.py banner.png
BadRequestError Error code: 400 - {'error': {'message': 'The mask must have an alpha channel.', 'type': 'invalid_request_error', 'param': 'mask', 'code': None}}
```

A primeira edição passou: o substituto devolveu o banner com o terço direito acinzentado, que é o jeito dele de mostrar onde um modelo real teria pintado. As duas seguintes foram recusadas, e as duas recusas são os jeitos mais comuns de errar uma máscara:

- **Uma máscara de outro tamanho.** A imagem tem 1536 por 1024 e a máscara 1024 por 1024, então a região transparente não tem lugar definido na imagem.
- **Uma máscara sem canal alfa.** Passar o próprio banner como máscara dele significa que nada é transparente, e o substituto o recusou por não ter alfa. Uma máscara desenhada num editor e salva como JPEG, que não tem alfa nenhum, falha do mesmo jeito.

Essas duas mensagens são do substituto, escritas para dizer o que está errado; a redação de uma API real é outra, e a recusa dela é o que se deve esperar. A conferência que vale escrever é a sua, antes da chamada: mesmo tamanho, modo `RGBA` e pelo menos um pixel transparente.

**Como exatamente o modelo respeita a máscara é assunto do provedor.** A documentação da OpenAI descreve a máscara como uma orientação: o modelo pode mudar pixels logo fora dela para a edição se misturar. Então a conferência depois de uma edição é a da aula 3: olhar, contra a lista, antes de publicar.
