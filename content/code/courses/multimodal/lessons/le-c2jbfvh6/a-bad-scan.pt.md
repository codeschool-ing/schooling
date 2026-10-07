---
title: Um escaneado ruim, e o que ajuda
version: 1
---

A segunda cópia da nota é a primeira depois de um scanner barato: girada 1,8 grau, borrada, salpicada de ruído, reduzida a 100 pontos por polegada e salva como JPEG de baixa qualidade. Cada um desses passos está escrito no `make_media.py` da aula 1, então o estrago é conhecido com exatidão. Lida no modo padrão, a tabela se desmancha:

```
ana@lab:~/mm$ tesseract media/invoice-0931-scan.jpg - 2>/dev/null | sed -n "/Qty/,/Total/p"
Qty Unit Amount
2 18.50 222.00

8 21.00 168.00

5 32.90 164,50

10 15.90 159,00

Subtotal 713.50

Shipping 45.00

Total BRL 758.50
```

**A primeira quantidade é `2`.** A página diz 12. No modo padrão o Tesseract pôs os números num bloco só deles, e o `1` na borda desse bloco se perdeu. Nada na saída diz que falta um caractere; um programa que a lesse encomendaria dois exemplares de *Dom Casmurro* e pagaria doze. Dois valores também voltaram com vírgula.

O modo de linhas se sai muito melhor, e ainda não perfeito:

```
ana@lab:~/mm$ tesseract media/invoice-0931-scan.jpg - --psm 6 2>/dev/null | sed -n "6,16p"
Marginalia Books
‘Av. Exemplo 1000, Sao Paulo SP
Title Qty Unit Amount
Dom Casmurro 12 18.50 222,00
The Posthumous Memoirs of Bras Cubas 8 21.00 168.00
Bleak House 5 32.90 164.50
The Secret Garden 10 15.96 159.00
Subtotal 713,50
Shipping 45.00
Total BRL 758.50
Payment by bank transfer within 30 days. Thank you for your business.
```

`222,00` e `713,50` com vírgula, e **`15.96` onde a página diz `15.90`**. O borrão fez um 0 parecer 6. E com o português:

```
ana@lab:~/mm$ tesseract media/invoice-0931-scan.jpg - --psm 6 -l eng+por 2>/dev/null | sed -n "6,16p"
Marginalia Books
‘Av. Exemplo 1000, São Paulo SP
Title Qty Unit Amount
Dom Casmurro 12 18.50 222.00
The Posthumous Memoirs of Brás Cubas 8 21.00 168.00
Bleak House 5 32.90 164.50
The Secret Garden 10 15.90 159.00
Subtotal 713,50
Shipping 45.00
Total BRL 758.50
Payment by bank transfer within 30 days. Thank you for your business.
```

Os acentos voltaram e o `15.90` está certo. Sobram só a vírgula em `713,50` e uma marca solta antes de *Av.*

## Os remédios mais procurados

Dois consertos são sugeridos para todo escaneado ruim: aumentar e endireitar. Os dois foram medidos, com a configuração que leu melhor.

`tidy.py`:

```python
"""Two cures people reach for on a bad scan: make it bigger, and turn it straight."""
import subprocess

import jiwer
from PIL import Image

TRUTH = " ".join(open("media/truth/invoice-0931.txt").read().split())
scan = Image.open("media/invoice-0931-scan.jpg")
tries = {
    "as scanned": scan,
    "twice the size": scan.resize((scan.width * 2, scan.height * 2), Image.LANCZOS),
    "turned 1.8 degrees back": scan.rotate(-1.8, resample=Image.BICUBIC, fillcolor=255),
}
for name, img in tries.items():
    img.save("/tmp/try.png")
    out = subprocess.run(["tesseract", "/tmp/try.png", "-", "--psm", "6", "-l", "eng+por"],
                         capture_output=True, text=True, check=True).stdout
    print(f"{name:24} CER {jiwer.cer(TRUTH, ' '.join(out.split())):6.1%}")
```

```
ana@lab:~/mm$ python tidy.py
as scanned               CER   0.4%
twice the size           CER   1.0%
turned 1.8 degrees back  CER   0.4%
```

**Dobrar o tamanho piorou**, de 0,4% para 1,0%. Ampliar uma imagem borrada amplia o borrão; o Tesseract já a lia num tamanho com que lida bem. **Girar de volta não mudou nada mensurável**: o Tesseract corrige sozinho rotações pequenas. Noutra página qualquer um dos dois poderia ajudar; a lição aqui é medir cada mudança em vez de aplicar uma receita, porque um remédio certo num tutorial pode estar errado para o seu scanner.

## Com que certeza ele leu?

O Tesseract dá a cada palavra uma confiança entre 0 e 100, e a saída `tsv` acrescenta onde a palavra está na página:

```python
"""Every word Tesseract read with less than 90% confidence, and where it is on the page."""
import csv
import io
import subprocess
import sys

lang = sys.argv[2] if len(sys.argv) > 2 else "eng+por"
tsv = subprocess.run(["tesseract", sys.argv[1], "-", "--psm", "6", "-l", lang, "tsv"],
                     capture_output=True, text=True, check=True).stdout
rows = list(csv.DictReader(io.StringIO(tsv), delimiter="\t", quoting=csv.QUOTE_NONE))
words = [r for r in rows if r["text"].strip()]
print(f"{len(words)} words")
for r in words:
    if float(r["conf"]) < 90:
        print(f"  {r['text']:14} conf {float(r['conf']):5.1f}  at x={r['left']:>4} y={r['top']:>4}")
```

```
ana@lab:~/mm$ python doubt.py media/invoice-0931-scan.jpg
76 words
  Palmeiras      conf  82.8  at x= 115 y= 118
  billing@lanternquill.example.com conf  69.9  at x=  47 y= 133
  Bill           conf  90.0  at x=  50 y= 233
  to             conf  90.0  at x=  83 y= 233
  ‘Av.           conf  78.9  at x=  51 y= 283
  Casmurro       conf  89.9  at x=  97 y= 393
  10             conf  83.7  at x= 513 y= 476
  713,50         conf  86.1  at x= 708 y= 527
ana@lab:~/mm$ python doubt.py media/invoice-0931-scan.jpg eng | grep -E "15|222|713|words"
76 words
  Palmeiras      conf  24.4  at x= 115 y= 118
  222,00         conf  86.2  at x= 704 y= 368
  15.96          conf  61.6  at x= 598 y= 472
  713,50         conf  86.1  at x= 708 y= 527
```

`713,50` está na lista, com 86,1: a vírgula que não devia estar ali foi uma leitura duvidosa. Também estão `10`, que está certo, e *Palmeiras*, que também está certo. O segundo comando lê só com inglês, em que o preço voltou como `15.96`, e guarda as linhas que importam: o preço errado está lá, com 61,6, e *Palmeiras*, que está certo, está ainda mais baixo, com 24,4.

**A confiança é uma pista de onde olhar, não um veredito.** Uma nota baixa marca uma palavra que vale conferir, e marca palavras certas também; uma nota alta não prova que a palavra está certa, e `222,00`, com a vírgula sobrando, teve 86,2. A próxima seção usa uma conferência que não depende de quão seguro o modelo se sentiu.
