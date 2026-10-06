---
title: O que legendas perfeitas ainda perdem
version: 1
---

Legendas carregam o que é **dito**. Quem não vê a tela recebe a narração e mais nada, então a próxima pergunta é o que a tela mostra que a narração nunca diz. A aula 4 leu os slides com o Tesseract; este programa faz isso num quadro do meio de cada slide e guarda toda linha em que metade ou mais das palavras nunca são faladas:

```python
"""What the video SHOWS that its narration never SAYS: OCR a frame from the middle of each slide."""
import json
import re
import subprocess

slides = json.load(open("media/truth/returns.json"))["slides"]
spoken = set(re.findall(r"[a-z0-9]+", " ".join(s["said"] for s in slides).lower()))

for s in slides:
    mid = (s["start"] + s["end"]) / 2
    png = subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-ss", f"{mid:.2f}", "-i", "media/returns.mp4",
                          "-frames:v", "1", "-f", "image2pipe", "-vcodec", "png", "-"], capture_output=True).stdout
    text = subprocess.run(["tesseract", "-", "-"], input=png, capture_output=True).stdout.decode()
    for line in filter(None, (l.strip() for l in text.splitlines())):
        words = re.findall(r"[a-z0-9]+", line.lower())
        unsaid = [w for w in words if w not in spoken]
        if len(unsaid) * 2 >= len(words):              # half or more of the line is never said
            print("%5.2f-%5.2f  %-38s never said: %s" % (s["start"], s["end"], line, " ".join(unsaid)))
```

```
ana@lab:~/mm$ python missing.py
 5.92-11.64  Account > Orders > M-1042              never said: m 1042
11.64-15.68  () Wrong book sent                     never said: wrong sent
11.64-15.68  () Changed my mind                     never said: changed my mind
20.72-21.12  Code: RETURN3O                         never said: code return3o
20.72-21.12  Quote it if you call us                never said: quote if call us
21.12-26.44  4. Drop it off                         never said: 4 off
26.44-32.60  Within 30 days of delivery             never said: within 30 days of delivery
26.44-32.60  The label is valid for 7 days          never said: valid for 7 days
```

O vídeo foi feito com essas lacunas de propósito, e o programa as achou, com duas linhas a mais que importam menos. **Três importam para quem está devolvendo um livro.** Os motivos do slide 3, que a narração chama de "a reason from the list" sem ler a lista. O cartão de 0,4 segundo entre os slides 4 e 5, `Code: RETURN30` e "Quote it if you call us", que ninguém fala (o Tesseract lê o código como `RETURN3O`, como na aula 4). E no último slide, **a etiqueta vale por 7 dias**, um prazo que quem só ouve descobriria perdendo.

O resto é ruído para quem descreve: o número do pedido no slide 2 é um exemplo, e "4. Drop it off" diz o que "Fourth, drop the parcel" já disse. Esse julgamento, de que texto mostrado importa, é a parte da audiodescrição que é sobre significado, e o programa não consegue fazê-lo. Ele consegue deixar a lista curta o bastante para uma pessoa decidir em um minuto.
