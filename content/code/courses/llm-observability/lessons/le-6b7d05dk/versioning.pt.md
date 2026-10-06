---
title: Uma versão, e o que a fixa
version: 1
---

Um conjunto que muda no meio de uma comparação torna a comparação sem sentido: uma versão do assistente
que tira nota melhor em quarenta e dois casos do que a anterior tirou em trinta não foi comparada com
nada. Então um conjunto é **lançado em versões**, como código, e todo resultado nomeia a versão em que
foi medido.

O `buildset.py` faz a versão 2: os trinta casos da versão 1, os doze acréscimos, a divisão a que cada
caso pertence, e um manifesto:

```python
"""buildset.py: version 2 of the evaluation set, version 1 and the additions, and a manifest that pins it."""
import hashlib
import json

import docs

v1 = open("data/eval.jsonl", "rb").read()
cases = [json.loads(line) for line in v1.decode().splitlines()]
cases += [json.loads(line) for line in open("data/eval-additions.jsonl")]
ids = [c["id"] for c in cases]
assert len(ids) == len(set(ids)), "an id is used twice"
for c in cases:   # every third question is held out, decided by its id and nothing else, as in rag
    c["split"] = "held-out" if int(c["id"][1:]) % 3 == 0 else "dev"
body = "".join(json.dumps(c, ensure_ascii=False) + "\n" for c in cases).encode()
open("data/eval-v2.jsonl", "wb").write(body)
shop = docs.load()
manifest = {"set": "marginalia-help", "version": 2, "cases": len(cases),
            "sha256": hashlib.sha256(body).hexdigest(), "parent": hashlib.sha256(v1).hexdigest(),
            "splits": {s: sum(c["split"] == s for c in cases) for s in ("dev", "held-out")},
            "documents": {d: shop[d][0]["version"] for d in sorted({g[0] for c in cases for g in c["gold"]})}}
json.dump(manifest, open("data/eval-v2.manifest.json", "w"), indent=1)
print(json.dumps(manifest, indent=1))
```

O `docs.py`, que a construção e a verificação dividem, lê o cabeçalho de cada documento e o texto
sob cada um dos seus títulos:

```python
"""docs.py: the shop's documents as the evaluation set sees them: front matter, and the text under each heading."""
import glob
import os
import re


def load(folder="data/docs"):
    """{doc id: (front matter, {heading: text})} for every document in the folder."""
    docs = {}
    for path in sorted(glob.glob(os.path.join(folder, "*.md"))):
        _, front, body = open(path).read().split("---\n", 2)
        meta = dict(line.split(": ", 1) for line in front.strip().splitlines())
        sections, current = {}, None
        for line in body.splitlines():
            m = re.match(r"#{2,}\s+(.*)", line)
            if m:
                current = m.group(1).strip()
                sections[current] = ""
            elif current:
                sections[current] += line + "\n"
        docs[meta["id"]] = (meta, sections)
    return docs
```

```
ana@lab:~/obs$ python buildset.py
{
 "set": "marginalia-help",
 "version": 2,
 "cases": 42,
 "sha256": "0d464ef783cd67f0007967f4879bf902519d4d75cfb18745629ec4dfb448b1d1",
 "parent": "5a8379ae9de31e3f559bb27fbb151e99c5be6639f07ce189e34437e2f3fd8798",
 "splits": {
  "dev": 28,
  "held-out": 14
 },
 "documents": {
  "affiliate-api": "2.3",
  "ebooks-and-audiobooks": "5",
  "gift-cards": "2",
  "payments-and-invoices": "7",
  "privacy-notice": "6",
  "returns-policy": "4",
  "seller-agreement": "3",
  "shipping-and-delivery": "6",
  "support-handbook": "12",
  "terms-of-sale": "9"
 }
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas versões do conjunto de avaliação. A versão 1 tem 30 casos escritos a partir dos documentos, sha256 5a8379ae. Doze casos das perguntas da semana de que se duvidou são acrescentados. A versão 2 tem 42 casos, 28 de desenvolvimento e 14 reservados, sha256 0d464ef7, com o hash da versão 1 como pai e a versão de cada documento contra o qual foi conferida.\"><rect x=\"20\" y=\"40\" width=\"200\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">versão 1</text><text x=\"36\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">30 casos</text><text x=\"36\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escritos a partir dos documentos</text><text x=\"36\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sha256 5a8379ae</text><rect x=\"260\" y=\"150\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">+ 12 casos</text><text x=\"276\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">das perguntas da</text><text x=\"276\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">semana postas em dúvida</text><rect x=\"480\" y=\"40\" width=\"220\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"496\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">versão 2</text><text x=\"496\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">42 casos: 28 dev, 14 reservados</text><text x=\"496\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sha256 0d464ef7</text><text x=\"496\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pai 5a8379ae</text><text x=\"496\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">documentos conferidos</text><path d=\"M220 85 L472 85\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M466 80 L474 85 L466 90\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M440 185 L590 185 L590 158\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M585 164 L590 156 L595 164\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path></svg>", "caption": "Uma versão é um arquivo fixo e um hash. O hash do pai faz da história uma corrente, e as versões dos documentos dizem quando o conjunto precisa ser conferido de novo."}
```

O manifesto é curto, e cada campo está lá para responder a uma pergunta que vem depois:

- **`sha256`** é o hash dos bytes exatos do conjunto. Uma execução que o registra pode ser conferida
  contra o conjunto que diz ter usado, e um arquivo editado à mão, por quem quer que seja, deixa de bater.
- **`parent`** é o hash da versão 1, então a história do conjunto é uma corrente que dá para seguir para
  trás, como quer que os arquivos se chamem.
- **`splits`** diz quantos casos cada divisão tem, assunto da última seção.
- **`documents`** é a versão de cada documento para onde aponta uma seção gold, tirada do cabeçalho do
  próprio documento. O conjunto foi conferido contra essas versões, e uma mudança em qualquer uma delas é
  motivo para conferi-lo de novo.

## As regras que uma versão mantém

**Um id nunca é reaproveitado nem renumerado.** Os doze casos novos são e31 a e42, depois do último id
em uso. Se o e14 for aposentado um dia, o e14 continua aposentado, para que um resultado da versão 2 que
nomeia o e14 ainda queira dizer a pergunta que queria dizer então.

**Um caso não é editado no lugar.** Se o sentido de um caso muda, porque a loja mudou a política por trás
dele ou a pergunta estava errada, o caso velho é aposentado e um novo ganha um id novo. Uma redação
corrigida sem mudar o que se pergunta pode manter o id; de um jeito ou de outro a versão do conjunto
sobe, e o hash muda junto.

**Toda execução registra a versão e o hash do conjunto** ao lado dos resultados. A aula 14 compara duas
execuções e recusa quando as duas foram medidas em conjuntos diferentes; a aula 15 reprova um build
quando o conjunto no repositório não é o que o seu manifesto fixa.
