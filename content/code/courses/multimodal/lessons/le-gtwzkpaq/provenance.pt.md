---
title: Dizendo que uma imagem foi gerada
version: 2
---

Uma imagem gerada publicada sem aviso pode enganar quem a vê, e cada vez mais lugares exigem um rótulo por lei. O AI Act da União Europeia exige que provedores de sistemas generativos marquem a saída de forma legível por máquina, e que deepfakes sejam declarados. Dois mecanismos técnicos fazem a marcação, e uma equipe de produto deveria saber ao que cada um sobrevive.

**Metadados.** O padrão C2PA, por trás das *Content Credentials*, anexa ao arquivo um registro assinado dizendo o que o fez e como foi editado. A OpenAI acrescenta credenciais C2PA às imagens que seus modelos produzem. O registro viaja dentro do arquivo, então o que mantiver o arquivo intacto mantém o registro.

**Marcas d'água nos pixels.** O SynthID do Google altera a própria imagem de um jeito que as pessoas não veem e um detector encontra, e o Google o aplica às imagens que seus modelos geram. Como mora nos pixels, ele foi feito para sobreviver às edições que tiram os metadados, como uma captura de tela, um recorte ou uma nova compressão.

Metadados se perdem fácil, sem querer. Aqui uma nota é escrita num PNG do jeito comum, e depois a imagem é redimensionada e salva de novo, como qualquer processamento de imagens faz:

```python
"""A note written into a PNG, and what happens to it when the picture is edited."""
from PIL import Image, PngImagePlugin

card = Image.open("grid/00-0.png")
info = PngImagePlugin.PngInfo()
info.add_text("Source", "images_server stand-in, gpt-image-1, 2026-10-07")
card.save("stamped.png", pnginfo=info)
print("saved:  ", Image.open("stamped.png").text)

edited = Image.open("stamped.png").resize((768, 512))
edited.save("edited.png")
print("edited: ", Image.open("edited.png").text)
```

```
ana@lab:~/mm$ python stamp.py
saved:   {'Source': 'images_server stand-in, gpt-image-1, 2026-10-07'}
edited:  {}
```

**A nota sumiu depois de um redimensionamento.** O Pillow salvou a imagem editada sem copiar o bloco de texto, porque nada pediu isso. O mesmo acontece na maioria dos geradores de miniaturas, uploads de CMS e redes sociais. Um registro C2PA é mais que um bloco de texto (é assinado, e uma ferramenta que conhece o C2PA consegue levá-lo adiante numa edição), mas uma ferramenta que não sabe nada dele o descarta do mesmo jeito.

## O que a Marginalia faz

1. **Guarda o registro fora da imagem**: o log da seção 04, com o modelo, o prompt e quem aprovou. Essa é a procedência que a loja controla.
2. **Avisa onde as pessoas veem**: uma linha sob o banner, "Ilustração gerada com IA", não custa nada e não depende de nenhum arquivo sobreviver.
3. **Não tira o que o provedor acrescentou.** Se o processamento redimensiona imagens, ele copia os metadados, e isso se confere lendo o arquivo publicado, não se presume.
