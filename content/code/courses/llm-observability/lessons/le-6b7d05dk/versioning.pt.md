---
title: Uma versão, e o que a fixa
version: 2
---

Um conjunto que muda no meio de uma comparação torna a comparação sem sentido: uma versão do
assistente que tira nota melhor em trinta e dois casos do que a anterior tirou em vinte e quatro não
foi comparada com nada. Então um conjunto é **lançado em versões**, como código, e todo resultado
nomeia a versão em que foi medido.

O `buildset.py` faz a versão 2: os vinte e quatro casos da versão 1, os oito acréscimos, a divisão a que cada
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
for c in cases:   # every third question is held out, decided by its id and nothing else
    c["split"] = "held-out" if int(c["id"][1:]) % 3 == 0 else "dev"
body = "".join(json.dumps(c, ensure_ascii=False) + "\n" for c in cases).encode()
open("data/eval-v2.jsonl", "wb").write(body)
shop = docs.load()
manifest = {"set": "marginalia-help", "version": 2, "cases": len(cases),
            "sha256": hashlib.sha256(body).hexdigest(), "parent": hashlib.sha256(v1).hexdigest(),
            "splits": {s: sum(c["split"] == s for c in cases) for s in ("dev", "held-out")},
            "documents": {d: shop[d][0]["updated"] for d in sorted({g.split(":")[0] for c in cases for g in c["gold"]})}}
json.dump(manifest, open("data/eval-v2.manifest.json", "w"), indent=1)
print(json.dumps(manifest, indent=1))
```

O `docs.py`, que o build e a verificação dividem, lê o cabeçalho de cada documento e cada um dos seus
trechos, com o mesmo id e o mesmo texto que o `index.py` lhes dá. A primeira versão dele deixava o
título fora do texto, e a verificação da próxima seção reprovou dois casos da própria versão 1 na
primeira execução: "cannot be returned" está no título *Items that cannot be returned* e em nenhum lugar
embaixo dele. O assistente busca o título também, então o conjunto precisa lê-lo:

```python
"""docs.py: the shop's documents as the evaluation set sees them: front matter, and each chunk's text by id.

The ids and the text are the ones index.py gives: the document's name, a colon, and the heading in
lower case with dashes for spaces; and the heading kept with the text under it, because the assistant
searches both.
"""
import glob
import os


def load(folder="data/docs"):
    """{document: (front matter, {chunk id: text})} for every document in the folder."""
    docs = {}
    for path in sorted(glob.glob(os.path.join(folder, "*.md"))):
        head, body = open(path).read().split("---\n")[1:3]
        meta = dict(line.split(": ", 1) for line in head.strip().splitlines())
        doc = os.path.basename(path)[:-3]
        chunks = {}
        for part in body.split("\n## ")[1:]:
            heading, text = part.split("\n", 1)
            chunks[f"{doc}:{heading.lower().replace(' ', '-')}"] = f"{heading}\n{' '.join(text.split())}"
        docs[doc] = (meta, chunks)
    return docs
```

```
ana@dev:~/obs$ python buildset.py
{
 "set": "marginalia-help",
 "version": 2,
 "cases": 32,
 "sha256": "8763ed310b27473ff257e62183f344e732ebe41378cc25d3230976bc54810796",
 "parent": "00f7e3c48ddcc47924ba61629ff42baf8a1b90cdd405c4cd8088403e1b0b44dc",
 "splits": {
  "dev": 22,
  "held-out": 10
 },
 "documents": {
  "ebooks-and-audiobooks": "2026-02-11",
  "gift-cards": "2026-01-08",
  "payments-and-invoices": "2026-04-30",
  "returns-policy": "2026-03-02",
  "shipping-and-delivery": "2026-05-20"
 }
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas versões do conjunto de avaliação. A versão 1 tem 24 casos escritos a partir dos documentos, sha256 00f7e3c4. Oito casos das perguntas postas em dúvida na semana são acrescentados. A versão 2 tem 32 casos, 22 de desenvolvimento e 10 reservados, sha256 8763ed31, com o hash da versão 1 como pai e a data de cada documento contra o qual foi conferida.\"><rect x=\"20\" y=\"40\" width=\"200\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">versão 1</text><text x=\"36\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">24 casos</text><text x=\"36\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escritos a partir dos documentos</text><text x=\"36\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sha256 00f7e3c4</text><rect x=\"260\" y=\"150\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">+ 8 casos</text><text x=\"276\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">das perguntas da</text><text x=\"276\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">semana postas em dúvida</text><rect x=\"480\" y=\"40\" width=\"220\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"496\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">versão 2</text><text x=\"496\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">32 casos: 22 dev, 10 reservados</text><text x=\"496\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sha256 8763ed31</text><text x=\"496\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pai 5a8379ae</text><text x=\"496\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">documentos conferidos</text><path d=\"M220 85 L472 85\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M466 80 L474 85 L466 90\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M440 185 L590 185 L590 158\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M585 164 L590 156 L595 164\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path></svg>", "caption": "Uma versão é um arquivo fixo e um hash. O hash do pai faz da história uma corrente, e as datas dos documentos dizem quando o conjunto precisa ser conferido de novo."}
```

O manifesto é curto, e cada campo está lá para responder a uma pergunta que vem depois:

- **`sha256`** é o hash dos bytes exatos do conjunto. Uma execução que o registra pode ser conferida
  contra o conjunto que diz ter usado, e um arquivo editado à mão, por quem quer que seja, deixa de bater.
- **`parent`** é o hash da versão 1, então a história do conjunto é uma corrente que dá para seguir para
  trás, como quer que os arquivos se chamem.
- **`splits`** diz quantos casos cada divisão tem, assunto da última seção.
- **`documents`** é a data em que foi atualizado pela última vez cada documento para onde aponta um
  trecho gold, tirada do cabeçalho do próprio documento. O conjunto foi conferido contra essas datas, e
  uma mudança em qualquer uma é motivo para conferi-lo de novo.

## As regras que uma versão mantém

**Um id nunca é reaproveitado nem renumerado.** Os oito casos novos são e25 a e32, depois do último id
em uso. Se o e14 for aposentado um dia, o e14 continua aposentado, para que um resultado da versão 2 que
nomeia o e14 ainda queira dizer a pergunta que queria dizer então.

**Um caso não é editado no lugar.** Se o sentido de um caso muda, porque a loja mudou a política por trás
dele ou a pergunta estava errada, o caso velho é aposentado e um novo ganha um id novo. Uma redação
corrigida sem mudar o que se pergunta pode manter o id; de um jeito ou de outro a versão do conjunto
sobe, e o hash muda junto.

**Toda execução registra a versão e o hash do conjunto** ao lado dos resultados. A aula 14 compara duas
execuções e recusa quando as duas foram medidas em conjuntos diferentes; a aula 15 reprova um build
quando o conjunto no repositório não é o que o seu manifesto fixa.
