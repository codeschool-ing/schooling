---
title: Mude uma coisa, depois olhe
version: 1
---

**Fazer prompt para um modelo de imagem é um experimento, e tem as regras de um.** Mude uma coisa por vez, mantenha todo o resto fixo, olhe o resultado e anote o que mudou. Mude o meio e a luz juntos e, quando a imagem melhorar, você não vai saber qual mudança fez isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"O prompt do banner cortado em seis partes com nome, cada uma em sua caixa: assunto, meio, estilo, composição, luz e paleta. Sob a caixa do meio estão os três valores testados, aquarela, linogravura e fotografia; sob a da luz, os seus três, sol do fim da tarde, luz de dia nublado e um abajur à noite. Todas as outras caixas mantêm um só valor.\"><rect x=\"20\" y=\"20\" width=\"105\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">assunto</text><rect x=\"135\" y=\"20\" width=\"105\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"145\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">meio</text><rect x=\"250\" y=\"20\" width=\"105\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">estilo</text><rect x=\"365\" y=\"20\" width=\"105\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"375\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">composição</text><rect x=\"480\" y=\"20\" width=\"105\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">luz</text><rect x=\"595\" y=\"20\" width=\"105\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"605\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">paleta</text><text x=\"145\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">watercolour</text><text x=\"145\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">linocut</text><text x=\"145\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">photograph</text><text x=\"490\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">afternoon sun</text><text x=\"490\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">overcast</text><text x=\"490\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">desk lamp</text><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Mude uma caixa por vez, deixe todas as outras como estavam, e veja o que mudou.</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Duas caixas mudadas de uma vez e não dá para saber qual fez a diferença.</text></svg>", "caption": "Um prompt com partes nomeadas é um prompt que se varia de propósito."}
```

O prompt da seção anterior, como um programa que mantém as partes nomeadas e monta uma grade de variantes, uma parte mudada por linha:

```python
"""A banner prompt as named parts, and a grid that changes one part at a time."""
import json
import sys

BASE = {
    "subject": "a stack of second-hand books on a café table",
    "medium": "watercolour illustration",
    "style": "loose brushwork, soft edges",
    "composition": "wide banner, books on the left third, empty space on the right",
    "light": "late afternoon sun from the left",
    "palette": "warm ochre and deep green",
}
TRIES = {
    "medium": ["watercolour illustration", "linocut print", "photograph, 35 mm lens"],
    "light": ["late afternoon sun from the left", "overcast daylight", "a single desk lamp at night"],
}


def prompt(parts):
    return ", ".join(parts[k] for k in BASE)


rows = [{"axis": "base", "value": "", "prompt": prompt(BASE)}]
for axis, values in TRIES.items():
    for v in values:
        if v != BASE[axis]:
            rows.append({"axis": axis, "value": v, "prompt": prompt(dict(BASE, **{axis: v}))})
json.dump(rows, open("grid.json", "w"), indent=1)
for r in rows:
    print(f"{r['axis']:7} {r['value'] or '(as above)':36} {len(r['prompt'])} characters")
print(rows[0]["prompt"], file=sys.stderr)
```

```
ana@lab:~/mm$ python axes.py
a stack of second-hand books on a café table, watercolour illustration, loose brushwork, soft edges, wide banner, books on the left third, empty space on the right, late afternoon sun from the left, warm ochre and deep green
base    (as above)                           224 characters
medium  linocut print                        213 characters
medium  photograph, 35 mm lens               222 characters
light   overcast daylight                    209 characters
light   a single desk lamp at night          219 characters
```

Cinco prompts: a base, dois outros meios, duas outras luzes. Nada mais se move entre eles, e o programa diz o tamanho de cada um, o que importa nos modelos que param de ler em 77 tokens.

Depois cada prompt é enviado **duas vezes**, porque uma imagem de um prompt não é uma medida dele. A API de imagens não tem semente (seção 02), então pedir `n=2` por prompt é o jeito de distinguir "este prompt dá luz fria" de "esta imagem calhou de sair fria":

```python
"""Send every prompt in grid.json, twice, and keep each picture with what asked for it."""
import base64
import csv
import json
import os

from openai import OpenAI

client = OpenAI()
os.makedirs("grid", exist_ok=True)
with open("grid/log.csv", "w", newline="") as f:
    log = csv.writer(f)
    log.writerow(["file", "axis", "value", "prompt"])
    for i, row in enumerate(json.load(open("grid.json"))):
        result = client.images.generate(model="lab-image-1", prompt=row["prompt"], size="1536x1024", n=2)
        for k, image in enumerate(result.data):
            name = f"grid/{i:02}-{k}.png"
            open(name, "wb").write(base64.b64decode(image.b64_json))
            log.writerow([name, row["axis"], row["value"], row["prompt"]])
print(open("grid/log.csv").read().count("\n") - 1, "pictures,", len(os.listdir("grid")) - 1, "files")
```

```
ana@lab:~/mm$ python grid.py
10 pictures, 10 files
ana@lab:~/mm$ tail -n 2 /var/log/labmm/requests.jsonl | python -c "import json, sys; [print({k: r[k] for k in (\"n\", \"path\", \"size\", \"images\", \"bytes\")}) for r in map(json.loads, sys.stdin)]"
{'n': 5, 'path': '/v1/images/generations', 'size': '1536x1024', 'images': 2, 'bytes': [41599, 41532]}
{'n': 6, 'path': '/v1/images/generations', 'size': '1536x1024', 'images': 2, 'bytes': [41650, 41586]}
```

**As imagens que voltaram não são imagens de livros.** O labmm é o substituto do curso, e o `lab-image-1` devolve um cartão cinza no tamanho pedido, com o prompt escrito nele e a linha *no model drew this*. O pedido, o registro e os arquivos no disco são reais; o desenho não é. O que este laboratório consegue ensinar sobre geração de imagens é o método em volta do modelo, e o método é o que sobrevive quando o modelo muda.

## O que guardar de cada execução

O `grid/log.csv` tem uma linha por imagem: o arquivo, qual parte mudou, o valor dela e o prompt inteiro. Sem essa linha, uma imagem boa é um acidente feliz que ninguém consegue repetir. Acrescente mais três coisas quando rodar isto contra um modelo real:

- **o modelo e a versão dele**, porque o mesmo prompt no modelo do próximo trimestre é outro experimento;
- **a semente**, onde o modelo a expõe;
- **o veredito**: a imagem atendeu à exigência (espaço vazio à direita, sem texto, a luz certa)? Uma coluna de sim e não é o que transforma uma pasta de imagens numa decisão.

Duas rodadas disso costumam resolver as partes que importam. Depois fixe essas, e gaste a rodada seguinte na próxima parte.
