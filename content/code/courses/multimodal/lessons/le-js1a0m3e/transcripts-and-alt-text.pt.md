---
title: Transcrições com falantes, e texto alternativo que uma máquina confere
version: 2
---

Uma gravação sem vídeo, como uma ligação de suporte guardada para treinamento, precisa de uma **transcrição** pelo critério 1.2.1. Numa ligação, uma transcrição que não diz quem está falando é difícil de acompanhar, então esta junta a separação de falantes da aula 5 aos segmentos do Whisper: cada segmento vai para o falante que mais se sobrepõe a ele.

```python
"""A transcript of the call for someone who cannot hear it: who spoke, when, and what Whisper heard."""
from mmlab import diarizer, read_audio
from openai import OpenAI

turns = diarizer(speakers=2).process(read_audio("media/call-1042.wav")).sort_by_start_time()
with open("media/call-1042.wav", "rb") as f:
    heard = OpenAI(base_url="http://localhost:8700/v1").audio.transcriptions.create(model="whisper-base", file=f,
                                                                              response_format="verbose_json")


def speaker(start, end):
    """The diarized speaker who overlaps this segment the most."""
    return max(turns, key=lambda t: min(end, t.end) - max(start, t.start)).speaker


last = None
for s in heard.segments:
    who = speaker(s.start, s.end)
    if who != last:
        print("\n[%d:%02d] Speaker %d:" % (s.start // 60, s.start % 60, who + 1), end="")
        last = who
    print(" " + s.text.strip(), end="")
print()
```

```
ana@lab:~/mm$ python transcript.py | cut -c1-110

[0:00] Speaker 1: Good morning, you're through to Marginalia Support. My name is Kyo. How can it help
[0:06] Speaker 2: Hi Kau, I'm calling about Order M1042. It's a copy of Dom Kazmuro by Machado Desiss and it a
[0:15] Speaker 1: Let me pull that up. Yes, I can see it here. One copy of Dom Casmorrow delivered on the 24th
[0:25] Speaker 2: Cover is torn, and about 10 pages are folded at the corner. I'd like to send it back.
[0:29] Speaker 1: I'm sorry to hear that. You're well within the 30 day window so you can return it free of ch
[0:39] Speaker 2: Will I get the shipping back as well?
[0:41] Speaker 1: Yes, for a damaged book we refund the full 3480 shipping included as soon as the parcel reac
[0:50] Speaker 2: Perfect, thank you.
[0:52] Speaker 1: Thank you for calling Marginalia. Have a good day.
```

Nove turnos, todos dados à pessoa certa, de acordo com os 98% da aula 5 na mesma ligação. As palavras são do Whisper base, "Kyo" e "Dom Kazmuro" incluídos, então isto é um **rascunho**: publicado como está, diz a um leitor surdo que o atendente se chamava Kyo. Uma pessoa o corrige contra o áudio uma vez, o que leva bem menos tempo que digitar do zero, e os falantes ganham nome na mesma passada.

O último critério, o 1.1.1, é o mais antigo: uma imagem com significado precisa de uma alternativa em texto. Se um `alt` diz a coisa certa é um julgamento sobre a página. O que uma máquina confere é o formato das falhas, e elas são poucas:

```python
"""The alt text a machine can judge: present, not a file name, not 'image of', empty only when decorative."""
import re
import sys
from html.parser import HTMLParser


class Images(HTMLParser):
    def __init__(self):
        super().__init__()
        self.found = []

    def handle_starttag(self, tag, attrs):
        if tag == "img":
            self.found.append((self.getpos()[0], dict(attrs)))


page = Images()
page.feed(open(sys.argv[1]).read())
for line, a in page.found:
    alt, src = a.get("alt"), a.get("src", "")
    if alt is None:
        verdict = "MISSING: many screen readers fall back to the file name"
    elif alt == "":
        verdict = "empty: right only if the picture is decoration" + ("" if a.get("role") == "presentation" else "; is it?")
    elif re.fullmatch(r"[\w-]+\.(jpe?g|png|gif|webp)", alt, re.I):
        verdict = "a file name, not a description"
    elif re.match(r"(image|picture|photo) of", alt, re.I):
        verdict = "starts with 'image of': the reader already says it is an image"
    else:
        verdict = "ok to a machine; whether it says the right thing is a person's call"
    print("line %d  %-22s %s" % (line, src, verdict))
```

```html
<main>
  <h1>Dom Casmurro</h1>
  <img src="cover-b39.png" alt="Cover of Dom Casmurro: a moon over a dark house with two lit windows">
  <img src="back-cover.jpg" alt="IMG_2041.jpg">
  <img src="size-chart.png">
  <img src="divider.svg" alt="" role="presentation">
  <img src="author.jpg" alt="Image of Machado de Assis">
  <p>Machado de Assis's novel of 1899, in a new English translation.</p>
</main>
```

```
ana@lab:~/mm$ python alt_check.py product.html
line 3  cover-b39.png          ok to a machine; whether it says the right thing is a person's call
line 4  back-cover.jpg         a file name, not a description
line 5  size-chart.png         MISSING: many screen readers fall back to the file name
line 6  divider.svg            empty: right only if the picture is decoration
line 7  author.jpg             starts with 'image of': the reader already says it is an image
```

Quatro de cinco precisam que uma pessoa olhe. A tabela de tamanhos não tem `alt`, então muitos leitores de tela acabam anunciando o nome do arquivo. O `alt` da contracapa é um nome de arquivo. O do autor começa com "Image of", que o leitor de tela já disse. O `alt` vazio do divisor está certo, porque é decoração, e a conferência só diz isso porque a página o marcou com `role="presentation"`.

O `alt` da capa passa, e só uma pessoa pode dizer se ele é bom. Ele foi escrito a partir da descrição da aula 8, conferida contra o que o `make_media.py` desenhou e cortada ao que quem escolhe uma edição precisa. O rascunho de um modelo de visão é um bom começo para texto alternativo; a descrição completa que ele escreveu seria longa demais, e **o propósito da imagem naquela página** decide o que fica. Esta plataforma roda o `axe` em toda tela, nos dois temas, e ele acha o `alt` que falta; se um `alt` diz a coisa certa está fora do que ele decide. Uma conferência automática é onde uma revisão começa, não onde termina.
