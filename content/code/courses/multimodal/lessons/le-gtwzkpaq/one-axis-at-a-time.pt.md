---
title: Mude uma coisa, depois olhe
version: 2
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

Depois cada prompt é enviado **duas vezes**, porque uma imagem de um prompt não é uma medida dele. A API de imagens não tem semente (seção 02), então pedir `n=2` por prompt é o jeito de distinguir "este prompt dá luz fria" de "esta imagem calhou de sair fria".

**Nenhum gerador de imagens roda no seu computador neste curso.** Os modelos de imagem do Ollama só rodam no macOS por enquanto, e a máquina do curso é Linux. Então os pedidos vão para um substituto que o curso fornece, que responde exatamente como a API de imagens da OpenAI e desenha um cartão cinza no lugar de uma imagem. Tudo em volta da imagem é real: o pedido, as conferências sobre ele, o formato da resposta e o arquivo no seu disco. Com uma chave sua, o mesmo programa chega à OpenAI mudando uma linha.

`images_server.py`, o substituto:

```python
"""images_server: the course's stand-in for an image API, on localhost:8800. NO MODEL DRAWS HERE.

It answers three routes the way the real services do, closely enough that the
openai and google-genai SDKs talk to it unchanged:

    POST /v1/images/generations              OpenAI: a picture from a prompt
    POST /v1/images/edits                    OpenAI: a picture changed inside a mask
    POST /v1beta/models/MODEL:generateContent    Gemini: words in, words and a picture out

Every picture it returns is a grey card with the request written on it. What is
real is everything around the picture: the request the SDK built, the checks
on it, the shape of the answer, and the file on your disk. Each request is also
written to images_server.log, one JSON line, so a lesson can see what arrived.
"""
import base64
import json
import math
import re
import textwrap
from email.parser import BytesParser
from email.policy import HTTP
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from io import BytesIO

import tiktoken
from PIL import Image, ImageDraw, ImageFont

SIZES = ["auto", "1024x1024", "1024x1536", "1536x1024"]   # the sizes OpenAI lists for its GPT image models
FONT = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 24)
BOLD = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 28)
TOKENS = tiktoken.get_encoding("o200k_base")


class Refused(Exception):
    def __init__(self, message, param=None):
        super().__init__(message)
        self.message, self.param = message, param


def card(size, lines, base=None):
    """The picture this stand-in returns: what was asked, on a card that says what it is."""
    img = base.convert("RGB").resize(size) if base else Image.new("RGB", size, (58, 63, 71))
    d = ImageDraw.Draw(img)
    d.rectangle([24, 24, size[0] - 24, 88 + 34 * len(lines)], fill=(30, 33, 38))
    d.text((48, 44), "images_server stand-in: no model drew this", font=BOLD, fill=(255, 214, 102))
    for i, line in enumerate(lines):
        d.text((48, 96 + i * 34), line, font=FONT, fill=(235, 235, 235))
    return img


def png(img):
    buf = BytesIO()
    img.save(buf, "PNG")
    return buf.getvalue()


def generate(req):
    size = req.get("size") or "auto"
    if size not in SIZES:
        raise Refused(f"Invalid value: '{size}'. Supported values are: " + ", ".join(f"'{s}'" for s in SIZES), "size")
    w, h = (1024, 1024) if size == "auto" else map(int, size.split("x"))
    n = int(req.get("n") or 1)
    lines = textwrap.wrap(req.get("prompt", ""), 60)[:8] + [f"{req.get('model')}, {w}x{h}"]
    data = [png(card((w, h), lines + [f"picture {k + 1} of {n}"])) for k in range(n)]
    return {"data": [{"b64_json": base64.b64encode(d).decode()} for d in data], "size": f"{w}x{h}"}, \
        {"size": f"{w}x{h}", "n": n, "bytes": [len(d) for d in data]}


def edit(fields, files):
    base = Image.open(BytesIO(files["image"]))
    mask = Image.open(BytesIO(files["mask"])) if "mask" in files else None
    if mask is not None:
        if mask.size != base.size:
            raise Refused(f"The mask must be the same size as the image: the image is {base.size[0]}x{base.size[1]} "
                          f"and the mask {mask.size[0]}x{mask.size[1]}.", "mask")
        if mask.mode != "RGBA":
            raise Refused("The mask must have an alpha channel.", "mask")
        hole = mask.getchannel("A").point(lambda a: 255 if a == 0 else 0)   # transparent = may be repainted
        base = Image.composite(Image.new("RGB", base.size, (128, 128, 128)), base.convert("RGB"), hole)
    lines = textwrap.wrap(fields.get("prompt", ""), 50)[:6] + ["the grey area is what an edit would repaint"]
    out = png(card(base.size, lines, base))
    return {"data": [{"b64_json": base64.b64encode(out).decode()}]}, {"size": "%dx%d" % base.size}


def gemini_tokens(w, h):
    """Google's published rule for an image sent to Gemini 2.x: 258 tokens per 768-pixel tile."""
    return 258 if w <= 384 and h <= 384 else 258 * math.ceil(w / 768) * math.ceil(h / 768)


def gemini(model, req):
    texts, pictures, tokens_in = [], [], 0
    for content in req.get("contents", []):
        for part in content.get("parts", []):
            if "text" in part:
                texts.append(part["text"])
                tokens_in += len(TOKENS.encode(part["text"]))
            blob = part.get("inlineData") or part.get("inline_data")
            if blob:
                raw = base64.urlsafe_b64decode(blob["data"] + "=" * (-len(blob["data"]) % 4))
                pictures.append(Image.open(BytesIO(raw)))
                tokens_in += gemini_tokens(*pictures[-1].size)
    config = req.get("generationConfig") or req.get("generation_config") or {}
    wants = [m.upper() for m in config.get("responseModalities") or config.get("response_modalities") or ["TEXT"]]
    reply = "images_server is a stand-in: no model read this request or drew a picture for it."
    parts = [{"text": reply}]
    if "IMAGE" in wants:
        img = card((1024, 1024), textwrap.wrap(" ".join(texts), 60)[:8], pictures[0] if pictures else None)
        parts.append({"inlineData": {"mimeType": "image/png", "data": base64.b64encode(png(img)).decode()}})
    tokens_out = len(TOKENS.encode(reply)) + (1290 if "IMAGE" in wants else 0)   # Google prices a picture as 1,290
    return {"candidates": [{"content": {"role": "model", "parts": parts}, "finishReason": "STOP", "index": 0}],
            "usageMetadata": {"promptTokenCount": tokens_in, "candidatesTokenCount": tokens_out,
                              "totalTokenCount": tokens_in + tokens_out}, "modelVersion": model}, \
        {"tokens_in": tokens_in, "tokens_out": tokens_out}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def answer(self, status, obj):
        body = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        self.answer(200, {"server": "images_server.py, a stand-in: no model draws here"})

    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        record = {"path": self.path}
        try:
            if self.path == "/v1/images/generations":
                req = json.loads(body)
                record["model"] = req.get("model")
                out, more = generate(req)
            elif self.path == "/v1/images/edits":
                head = f"Content-Type: {self.headers['Content-Type']}\r\n\r\n".encode()
                fields, files = {}, {}
                for part in BytesParser(policy=HTTP).parsebytes(head + body).iter_parts():
                    name = part.get_param("name", header="content-disposition").removesuffix("[]")
                    if part.get_filename():
                        files[name] = part.get_payload(decode=True)
                    else:
                        fields[name] = part.get_content()
                record["model"] = fields.get("model")
                out, more = edit(fields, files)
            elif m := re.fullmatch(r"/v1beta/models/([^:]+):generateContent", self.path.split("?")[0]):
                record["model"] = m[1]
                out, more = gemini(m[1], json.loads(body))
            else:
                raise Refused(f"no route for POST {self.path}")
            record.update(more, status=200)
            self.answer(200, out)
        except Refused as e:
            record.update(status=400, error=e.message)
            self.answer(400, {"error": {"message": e.message, "type": "invalid_request_error",
                                        "param": e.param, "code": None}})
        with open("images_server.log", "a") as log:
            log.write(json.dumps(record) + "\n")


if __name__ == "__main__":
    print("images_server: a stand-in on http://localhost:8800, no model behind it", flush=True)
    ThreadingHTTPServer(("127.0.0.1", 8800), Handler).serve_forever()
```

Ele responde a três rotas, e esta aula usa a primeira; a aula 9 usa as outras duas. Inicie-o num segundo terminal, no `~/mm`, e deixe-o rodando:

```sh
python images_server.py
```

`grid.py`, que manda os prompts:

```python
"""Send every prompt in grid.json, twice, and keep each picture with what asked for it."""
import base64
import csv
import json
import os

from openai import OpenAI

client = OpenAI(base_url="http://localhost:8800/v1")   # the stand-in; OpenAI is https://api.openai.com/v1
os.makedirs("grid", exist_ok=True)
with open("grid/log.csv", "w", newline="") as f:
    log = csv.writer(f)
    log.writerow(["file", "axis", "value", "prompt"])
    for i, row in enumerate(json.load(open("grid.json"))):
        result = client.images.generate(model="gpt-image-1", prompt=row["prompt"], size="1536x1024", n=2)
        for k, image in enumerate(result.data):
            name = f"grid/{i:02}-{k}.png"
            open(name, "wb").write(base64.b64decode(image.b64_json))
            log.writerow([name, row["axis"], row["value"], row["prompt"]])
print(open("grid/log.csv").read().count("\n") - 1, "pictures,", len(os.listdir("grid")) - 1, "files")
```

```
ana@lab:~/mm$ python grid.py
10 pictures, 10 files
ana@lab:~/mm$ tail -n 2 images_server.log
{"path": "/v1/images/generations", "model": "gpt-image-1", "size": "1536x1024", "n": 2, "bytes": [41497, 41437], "status": 200}
{"path": "/v1/images/generations", "model": "gpt-image-1", "size": "1536x1024", "n": 2, "bytes": [41550, 41490], "status": 200}
```

**As imagens que voltaram não são imagens de livros.** Cada uma é um cartão cinza no tamanho pedido, com o prompt escrito nele e a linha *no model drew this*. O pedido, o registro do servidor e os dez arquivos no disco são reais; o desenho não. Cada imagem tem uns 41 kilobytes, e as duas de um mesmo pedido diferem em algumas dezenas de bytes, porque cada cartão leva o próprio número. O que este curso consegue ensinar sobre geração de imagens é o método em volta do modelo, e o método é o que sobrevive quando o modelo muda.

## O que guardar de cada execução

O `grid/log.csv` tem uma linha por imagem: o arquivo, qual parte mudou, o valor dela e o prompt inteiro. Sem essa linha, uma imagem boa é um acidente feliz que ninguém consegue repetir. Acrescente mais três coisas quando rodar isto contra um modelo real:

- **o modelo e a versão dele**, porque o mesmo prompt no modelo do próximo trimestre é outro experimento;
- **a semente**, onde o modelo a expõe;
- **o veredito**: a imagem atendeu à exigência (espaço vazio à direita, sem texto, a luz certa)? Uma coluna de sim e não é o que transforma uma pasta de imagens numa decisão.

Duas rodadas disso costumam resolver as partes que importam. Depois fixe essas, e gaste a rodada seguinte na próxima parte.
