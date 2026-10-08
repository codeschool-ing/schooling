---
title: Quanto custa uma imagem
version: 2
---

A aula 8 mediu a regra de blocos do GPT-4o numa capa. Este programa aplica essa regra, e a do Google para o Gemini, a três imagens de tamanhos muito diferentes. A terceira é o `cat_and_dog.jpg` ampliado para 4032 por 3024 pixels, o tamanho que uma câmera de celular de 12 megapixels salva, para uma foto de celular ter um substituto. Uma linha a faz:

```
ana@lab:~/mm$ python -c "from PIL import Image; Image.open(\"media/cat_and_dog.jpg\").resize((4032, 3024)).save(\"media/phone.jpg\", quality=90)"; stat -c "%s %n" media/phone.jpg
883497 media/phone.jpg
```

O programa lê as regras de tokens do `tokens.py` da aula 4:

```python
"""What one picture costs to send, by the token rules of lesson 8 and the sheet's input prices."""
import sys

from tokens import gemini_tokens, gpt4o_tokens
from PIL import Image

GPT4O = 2.5e-06          # sheet: gpt-4o input_cost_per_token
FLASH = 3e-07            # sheet: gemini/gemini-2.5-flash input_cost_per_token

print("%-22s %11s %7s %8s %7s %9s" % ("file", "pixels", "detail", "tokens", "$/1000", "gemini $/1000"))
for path in sys.argv[1:]:
    w, h = Image.open(path).size
    for detail in ("low", "high"):
        t, _ = gpt4o_tokens(w, h, detail)
        g = gemini_tokens(w, h) if detail == "high" else None
        line = "%-22s %11s %7s %8d %7.2f %9s" % (path.split("/")[-1], f"{w}x{h}", detail, t, t * GPT4O * 1000,
                                                "%.2f" % (g * FLASH * 1000) if g else "")
        print(line.rstrip())
```

```
ana@lab:~/mm$ python picture_cost.py media/cover-b39.png media/invoice-0931.png media/phone.jpg
file                        pixels  detail   tokens  $/1000 gemini $/1000
cover-b39.png              600x900     low       85    0.21
cover-b39.png              600x900    high      765    1.91      0.15
invoice-0931.png         1240x1754     low       85    0.21
invoice-0931.png         1240x1754    high     1105    2.76      0.46
phone.jpg                4032x3024     low       85    0.21
phone.jpg                4032x3024    high      765    1.91      1.86
```

Leia primeiro a coluna `tokens`.

- **`low` dá 85 tokens para qualquer imagem**, inclusive a foto de celular. É o padrão barato quando a pergunta é sobre a cena inteira e não sobre os detalhes.
- **`high` não é proporcional aos pixels.** A foto de celular tem mais de 22 vezes os pixels da capa e os mesmos 765 tokens, porque a OpenAI primeiro a encaixa em 2048 e depois reduz o lado menor para 768, o que deixa 1024 por 768 e quatro blocos. A nota é alta, então os mesmos passos deixam seis blocos e 1.105 tokens.
- **A regra do Gemini não encolhe antes.** Ela conta 258 tokens por bloco de 768 pixels da imagem como foi enviada, então a foto de celular dá 24 blocos e 6.192 tokens. O preço por token é bem menor, e mesmo assim a foto de celular é de longe a imagem mais cara dele.

**A mesma imagem pode ser barata num provedor e cara em outro**, e a ordem pode se inverter. A capa custa US$ 0,15 por mil no Gemini e US$ 1,91 em alto detalhe no GPT-4o; a foto de celular custa mais ou menos o mesmo nos dois. Uma estimativa feita com a regra de um provedor não diz nada sobre a do outro. Estas são as regras que o `tokens.py` escreve, tiradas dos documentos dos provedores; uma conta real é a contagem do próprio provedor, no `usage` de cada resposta.
