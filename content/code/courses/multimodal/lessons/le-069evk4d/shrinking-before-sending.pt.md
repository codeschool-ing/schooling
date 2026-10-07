---
title: Encolhendo uma imagem antes de enviar
version: 1
---

Se um provedor conta tokens pela largura e pela altura, a economia óbvia é mandar uma imagem menor. Este programa faz três cópias menores da nota e pergunta duas coisas a cada uma: quanto custaria, e **ainda dá para ler**? O Tesseract faz o papel do leitor, e duas medidas fazem o papel da resposta: a parte das palavras da página que ele achou, em qualquer ordem, e quantos dos 11 valores em dinheiro da página ele leu exatamente.

```python
"""The invoice, made smaller three ways: does Tesseract still read it, and what does each copy cost?"""
import io
import re
import subprocess
from collections import Counter

from tokens import gpt4o_tokens
from PIL import Image

truth = open("media/truth/invoice-0931.txt").read()
amounts = re.findall(r"\d+\.\d\d", truth)                  # the 11 money values on the page
page = Image.open("media/invoice-0931.png")


def read(data):
    return subprocess.run(["tesseract", "-", "-"], input=data, capture_output=True).stdout.decode()


def copy(img, fmt, **kw):
    buf = io.BytesIO()
    img.save(buf, fmt, **kw)
    return buf.getvalue()


print("%-26s %9s %7s %7s %8s" % ("copy", "bytes", "tokens", "words", "amounts"))
for name, short, fmt, kw in (("original png", 1240, "PNG", {}),
                             ("png, short side 768", 768, "PNG", {}),
                             ("jpeg q75, short side 768", 768, "JPEG", {"quality": 75}),
                             ("jpeg q75, short side 512", 512, "JPEG", {"quality": 75})):
    s = short / page.width
    img = page.resize((round(page.width * s), round(page.height * s)), Image.LANCZOS)
    data = copy(img.convert("RGB"), fmt, **kw) if short < 1240 else open("media/invoice-0931.png", "rb").read()
    tokens, _ = gpt4o_tokens(img.width, img.height, "high")
    text = read(data)
    found = sum((Counter(truth.split()) & Counter(text.split())).values()) / len(truth.split())
    print("%-26s %9d %7d %6.0f%% %5d/%d" % (name, len(data), tokens, 100 * found,
                                           sum(a in text for a in amounts), len(amounts)))
```

```
ana@lab:~/mm$ python shrink.py
copy                           bytes  tokens   words  amounts
original png                   87530    1105     97%    11/11
png, short side 768           106098    1105     91%    11/11
jpeg q75, short side 768       50761    1105     92%    11/11
jpeg q75, short side 512       26832     425     76%     4/11
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Quatro cópias da nota como barras. PNG original: 87.530 bytes, 1.105 tokens, 11 de 11 valores lidos. PNG com o lado menor em 768: 106.098 bytes, 1.105 tokens, 11 de 11. JPEG qualidade 75 em 768: 50.761 bytes, 1.105 tokens, 11 de 11. JPEG qualidade 75 em 512: 26.832 bytes, 425 tokens, 4 de 11. A barra de tokens só cai na última cópia, e é essa a cópia que perdeu a maior parte dos valores.\"><text x=\"170\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">bytes</text><text x=\"370\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">tokens</text><text x=\"570\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">valores lidos</text><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">png original</text><rect x=\"170\" y=\"44\" width=\"148.49855793700164\" height=\"22\" rx=\"3\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"174\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">87.530</text><rect x=\"370\" y=\"44\" width=\"180.0\" height=\"22\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.105</text><rect x=\"570\" y=\"44\" width=\"130.0\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"574\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11/11</text><text x=\"20\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">png, 768</text><rect x=\"170\" y=\"92\" width=\"180.0\" height=\"22\" rx=\"3\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"174\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">106.098</text><rect x=\"370\" y=\"92\" width=\"180.0\" height=\"22\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.105</text><rect x=\"570\" y=\"92\" width=\"130.0\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"574\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11/11</text><text x=\"20\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">jpeg q75, 768</text><rect x=\"170\" y=\"140\" width=\"86.11830571735565\" height=\"22\" rx=\"3\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"174\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50.761</text><rect x=\"370\" y=\"140\" width=\"180.0\" height=\"22\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.105</text><rect x=\"570\" y=\"140\" width=\"130.0\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"574\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11/11</text><text x=\"20\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">jpeg q75, 512</text><rect x=\"170\" y=\"188\" width=\"45.52168749646553\" height=\"22\" rx=\"3\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"174\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">26.832</text><rect x=\"370\" y=\"188\" width=\"69.23076923076923\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">425</text><rect x=\"570\" y=\"188\" width=\"47.27272727272727\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"574\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4/11</text></svg>", "caption": "Encolher para 768 mudou os bytes e nada mais; descer abaixo disso mudou os tokens e as respostas juntos."}
```

**Encolher para 768 não economizou nada.** Os tokens ficaram em 1.105, porque 768 no lado menor é onde a regra da OpenAI põe a imagem de qualquer jeito: o provedor ia fazer esse redimensionamento ele mesmo. O PNG até ficou maior, 106.098 bytes contra 87.530, porque redimensionar uma página preto e branco acrescenta bordas cinza que o PNG comprime mal. O JPEG no mesmo tamanho cortou os bytes pela metade, o que deixa o envio mais rápido e não muda nada na conta.

**Descer abaixo do tamanho da regra economizou tokens e perdeu a nota.** Em 512 a cópia custa 425 tokens, 62% a menos, e só 4 dos 11 valores voltaram certos. Um modelo lendo essa cópia estaria lendo o mesmo borrão.

Então a regra para imagens é curta. **Reduza até o que o provedor vai usar de qualquer jeito**, o que economiza tempo de envio e bytes diante de um limite. Não vá além disso, a não ser que uma medida na tarefa diga que a cópia menor ainda responde. "Ainda responde" é sobre a tarefa: aqui, os valores. Bytes economizados são fáceis de ver, e as respostas perdidas só aparecem numa conferência como esta.
