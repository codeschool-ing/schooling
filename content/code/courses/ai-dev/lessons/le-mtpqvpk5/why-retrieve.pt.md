---
title: Por que recuperar
version: 2
---

Um assistente de suporte da loja tem de responder a partir das regras da própria loja: trinta dias
para uma devolução, 15,00 de frete, o que quer dizer E1042. Nenhum modelo foi treinado com isso, e a
aula 1 seção 11 mostrou o que um modelo faz com uma pergunta para a qual não foi treinado. **A geração
aumentada por recuperação (RAG) põe as regras relevantes na requisição**, no momento da pergunta, para
o modelo continuar a partir do texto certo em vez de reconstruí-lo.

::: track ai
Você construiu isto de ponta a ponta no `rag`, com um banco vetorial de verdade e um conjunto de
avaliação de centenas de perguntas. Esta aula é a versão que um desenvolvedor encontra quando a
tarefa é "ponha busca na nossa página de suporte": pequena, com toda parte visível, e com as
checagens que você deve manter qualquer que seja o tamanho.
:::

::: track *
A técnica inteira são três passos, e esta aula constrói cada um em poucas linhas de Python: achar os
trechos relevantes para a pergunta, pô-los no prompt, e conferir que a resposta os usa.
:::

## O manual

O manual de suporte da loja são oito arquivos Markdown curtos, escritos para o curso como o resto da
loja. Um script escreve os oito em `docs/handbook`; salve-o como `scratch/make-handbook.sh`:

```sh
# make-handbook.sh: the shop's support handbook, eight files in docs/handbook
mkdir -p docs/handbook
cat > docs/handbook/returns.md <<'EOF'
# Returns and refunds

A customer may return any item within 30 days of delivery, for any reason. The
item must be unused and in its original packaging. Mugs and glasses must also
be unbroken; a breakage in transit is a damaged delivery, not a return.

To start a return, the customer opens the order in their account and chooses
"Return an item". The shop emails a prepaid label within one working day.

The refund goes back to the original payment method once the item arrives at
the warehouse and is checked, which takes up to five working days. Shipping
costs are refunded only when the whole order is returned.

After 30 days the shop does not accept returns, but a faulty item is covered
by the warranty described in warranty.md.
EOF
cat > docs/handbook/shipping.md <<'EOF'
# Shipping

Orders ship within two working days from the warehouse in Campinas. Delivery
inside Brazil takes three to eight working days depending on the region.

Shipping costs a flat 15.00 per order. It is free when the order total after
any coupon is 200.00 or more; the threshold is checked after the discount, so a
coupon can bring an order back under it.

The shop ships only to addresses in Brazil. It does not ship abroad and does
not deliver to post office boxes.

A customer can follow the parcel with the tracking code in the shipping email.
A parcel with no tracking update for ten working days is reported as lost.
EOF
cat > docs/handbook/coupons.md <<'EOF'
# Coupons

Two coupons are active. WELCOME10 takes 10% off and has no end date.
FRIENDS15 takes 15% off and is valid until 31 October 2026, inclusive.

Only one coupon applies per order; entering a second one replaces the first.
Codes may be typed in any case. A coupon cannot be applied after the order is
placed, and it is never exchanged for cash.

The discount is taken from the items, not from shipping, and is rounded down
to a whole cent.
EOF
cat > docs/handbook/payment-errors.md <<'EOF'
# Payment errors at checkout

The checkout shows a code when a payment fails. Read the code before anything
else; most failures are on the card issuer's side.

E1001: the card was declined by the issuer. Ask the customer to contact their
bank or use another card. The shop cannot see the reason.

E1042: the payment timed out between the shop and the payment service. No
money was taken. The customer can simply try again after a minute; if it
happens three times in a row, escalate to the on-call developer.

E2003: the billing address does not match the card. The customer should check
the postcode, which is the usual mistake.
EOF
cat > docs/handbook/warranty.md <<'EOF'
# Warranty

Every item has a 90-day warranty against manufacturing faults, counted from
delivery. A fault is something that stops the item working as described: a
lamp that does not light, a handle that comes off a mug in normal use.

Damage from a fall, from a dishwasher on a product marked hand-wash only, or
from ordinary wear is not covered.

Under warranty the shop replaces the item, or refunds it if it is out of
stock. The customer sends a photo of the fault from their account; there is
no need to send the item back unless the shop asks for it.
EOF
cat > docs/handbook/account.md <<'EOF'
# Accounts and passwords

A customer can check out without an account, but needs one to follow orders,
start a return or use the warranty.

To reset a password, the customer chooses "Forgot password" on the sign-in
page and follows the link in the email, which is valid for one hour. Support
staff never ask for a password and cannot see one.

To close an account, the customer writes to support from the account's email
address. Orders from the last five years are kept for tax reasons; everything
else is deleted within 30 days.
EOF
cat > docs/handbook/contact.md <<'EOF'
# Contacting support

Support answers by email and chat from 9:00 to 18:00, Monday to Friday,
Brasília time, except public holidays. Messages that arrive outside those hours
are answered the next working day, in the order they arrived.

The target for a first reply is four working hours. Anything about a payment
taken twice, or a parcel reported as lost, goes to the front of the queue.
EOF
cat > docs/handbook/products.md <<'EOF'
# Products

The shop sells mugs, glasses, lamps and small furniture. Mugs and glasses are
ceramic or tempered glass; all mugs are dishwasher-safe except the hand-painted
line, which is marked hand-wash only on the box and on the product page.

Lamps take a standard E27 bulb, not included. Furniture arrives flat-packed,
with tools, and the instructions are also on the product page.

Prices on the site include taxes. A price shown in an email or an advert is
valid only if it is also the price on the product page at checkout.
EOF
```

```
ana@dev:~/shop$ bash scratch/make-handbook.sh && git add docs && git commit -qm "Support handbook" && ls docs/handbook && wc -w docs/handbook/*.md | tail -1
account.md
contact.md
coupons.md
payment-errors.md
products.md
returns.md
shipping.md
warranty.md
 793 total
ana@dev:~/shop$ python -c 'import tiktoken, pathlib; print(sum(len(tiktoken.get_encoding("o200k_base").encode(p.read_text())) for p in pathlib.Path("docs/handbook").glob("*.md")), "tokens in the handbook")'
993 tokens in the handbook
```

**993 tokens.** Isso é pequeno o bastante para mandar inteiro com cada pergunta, e para um manual
desse tamanho seria uma escolha razoável. A recuperação passa a valer quando os documentos deixam de
caber, ou deixam de ser baratos de mandar: algumas centenas de páginas de políticas, um catálogo de
produtos, todo chamado de suporte já aberto. A conta da aula 2 decide onde fica essa linha para você,
e este manual é pequeno para cada passo do pipeline caber numa tela.

## O programa

Tudo o que esta aula roda é um módulo, `scratch/rag.py`, e três scripts curtos que o chamam. Aqui está
o módulo inteiro. Cada uma das próximas seções pega uma parte dele, mostra de novo e roda, então não
é preciso ler tudo agora:

```schooling-example
{
  "language": "python",
  "file": "scratch/rag.py",
  "parts": [
    {
      "code": "\"\"\"Retrieval over the shop's handbook: chunk, embed, search, and check citations.\"\"\"\nimport json\nimport logging\nimport math\nimport re\nfrom collections import Counter\nfrom pathlib import Path\n\nimport numpy as np\nimport tiktoken\nfrom wordllama import WordLlama\n\nENC = tiktoken.get_encoding(\"o200k_base\")\nINDEX = Path(\".rag\")\nlogging.getLogger().setLevel(logging.WARNING)  # importing wordllama turns INFO logging on\n\n\n",
      "note": "**Um arquivo, e um índice ao lado.** Os trechos e os vetores deles vão para `.rag/` no projeto, construídos uma vez e lidos a cada busca."
    },
    {
      "code": "def chunks(folder=\"docs/handbook\"):\n    \"\"\"One chunk per paragraph, carrying its document's title, with an id that says where it is.\"\"\"\n    out = []\n    for path in sorted(Path(folder).glob(\"*.md\")):\n        title, *paragraphs = path.read_text().split(\"\\n\\n\")\n        for n, p in enumerate(paragraphs, 1):\n            out.append({\"id\": f\"{path.name}#{n}\", \"text\": title.lstrip(\"# \") + \". \" + \" \".join(p.split())})\n    return out\n\n\n",
      "note": "**Cortar**: um trecho por parágrafo, com o título e um id. Seção 03."
    },
    {
      "code": "def build():\n    cs = chunks()\n    vectors = WordLlama.load().embed([c[\"text\"] for c in cs], norm=True)\n    INDEX.mkdir(exist_ok=True)\n    np.save(INDEX / \"vectors.npy\", vectors)\n    (INDEX / \"chunks.json\").write_text(json.dumps(cs, indent=1))\n    return cs, vectors\n\n\n",
      "note": "**Embutir**: cada trecho num vetor, salvo. Seção 04."
    },
    {
      "code": "def load():\n    return json.loads((INDEX / \"chunks.json\").read_text()), np.load(INDEX / \"vectors.npy\")\n\n\n"
    },
    {
      "code": "def vector_search(query, k=3):\n    cs, vectors = load()\n    scores = vectors @ WordLlama.load().embed([query], norm=True)[0]\n    return [(cs[i], float(scores[i])) for i in np.argsort(-scores)[:k]]\n\n\n",
      "note": "**Buscar por significado**: o vetor da pergunta contra o de cada trecho. Seção 05."
    },
    {
      "code": "def words(text):\n    return re.findall(r\"\\w+\", text.lower())\n\n\ndef keyword_search(query, k=3):\n    \"\"\"BM25: a word counts more when it is rare in the handbook and frequent in the chunk.\"\"\"\n    cs, _ = load()\n    docs = [words(c[\"text\"]) for c in cs]\n    avg = sum(map(len, docs)) / len(docs)\n    df = Counter(w for d in docs for w in set(d))\n    scores = []\n    for d in docs:\n        tf = Counter(d)\n        s = 0.0\n        for w in set(words(query)):\n            if w in tf:\n                idf = math.log(1 + (len(docs) - df[w] + 0.5) / (df[w] + 0.5))\n                s += idf * tf[w] * 2.2 / (tf[w] + 1.2 * (0.25 + 0.75 * len(d) / avg))\n        scores.append(s)\n    order = sorted(range(len(cs)), key=lambda i: -scores[i])[:k]\n    return [(cs[i], scores[i]) for i in order]\n\n\n",
      "note": "**Buscar por palavras**, o BM25, e o caso que precisa dele. Seção 06."
    },
    {
      "code": "def hybrid_search(query, k=3):\n    \"\"\"Reciprocal rank fusion: each list votes 1/(60 + rank) for each chunk it found.\"\"\"\n    votes = Counter()\n    by_id = {}\n    for found in (vector_search(query, 10), keyword_search(query, 10)):\n        for rank, (c, _) in enumerate(found):\n            votes[c[\"id\"]] += 1 / (60 + rank)\n            by_id[c[\"id\"]] = c\n    return [(by_id[i], v) for i, v in votes.most_common(k)]\n\n\n",
      "note": "**As duas, combinadas** pela fusão de postos recíprocos. Seção 06 também."
    },
    {
      "code": "NOT_THERE = \"The handbook does not say.\"\n\n\ndef prompt(question, found):\n    passages = \"\\n\".join(f\"[{c['id']}] {c['text']}\" for c, _ in found)\n    return (\"Answer only from the passages below. Cite the passage id in square brackets after \"\n            \"every sentence. If the passages do not contain the answer, reply with exactly: \"\n            f\"{NOT_THERE}\\n\\n{passages}\\n\\nQuestion: {question}\")\n\n\n",
      "note": "**O prompt**: os trechos com os ids, e o que dizer quando eles não respondem. Seção 07."
    },
    {
      "code": "def check_citations(answer, found):\n    \"\"\"Every sentence cites a passage that was retrieved, and every quoted phrase is in it.\"\"\"\n    given = {c[\"id\"]: c[\"text\"] for c, _ in found}\n    if answer.strip() == NOT_THERE:\n        return []\n    problems = []\n    for sentence in re.split(r\"(?<=[.!?\\]])\\s+(?!\\[)\", answer.strip()):\n        cited = re.findall(r\"\\[([\\w.-]+#\\d+)\\]\", sentence)\n        if not cited:\n            problems.append(f'cites nothing: \"{sentence[:50]}\"')\n        for cid in cited:\n            if cid not in given:\n                problems.append(f\"cites {cid}, which was not among the passages\")\n        for quote in re.findall(r'\"([^\"]+)\"', sentence):\n            if cited and not any(quote.lower() in given.get(c, \"\").lower() for c in cited):\n                problems.append(f'quotes \"{quote}\", which {\", \".join(cited)} does not say')\n    return problems\n",
      "note": "**A checagem** do que volta. Seção 08."
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Geração aumentada por recuperação numa figura. Antes, o manual é cortado em 26 trechos e cada um vira um embedding num índice. Quando chega uma pergunta, ela é buscada no índice, os três primeiros trechos entram no prompt com os ids, o modelo responde citando-os, e um verificador confere as citações antes de a resposta aparecer.\"><defs><marker id=\"pl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma vez, antes</text><rect x=\"20\" y=\"34\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">manual</text><text x=\"80.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8 arquivos</text><rect x=\"180\" y=\"34\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trechos</text><text x=\"240.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">26, com ids</text><rect x=\"340\" y=\"34\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">índice</text><text x=\"400.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">26 × 256</text><path d=\"M142 59 L176 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M302 59 L336 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a cada pergunta</text><rect x=\"20\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pergunta</text><rect x=\"160\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">busca</text><text x=\"220.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 primeiros</text><rect x=\"300\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">prompt</text><text x=\"360.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">trechos + pergunta</text><rect x=\"440\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">modelo</text><text x=\"500.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resposta + [ids]</text><rect x=\"580\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">checagem</text><text x=\"640.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">citações</text><path d=\"M142 161 L156 161\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M282 161 L296 161\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M422 161 L436 161\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M562 161 L576 161\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M400 86 L400 110 L220 110 L220 132\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path></svg>", "caption": "A linha de cima roda quando os documentos mudam; a de baixo roda a cada pergunta. A aula 6 constrói cada caixa.", "same": ["prompt"]}
```

## Recuperação ou treino

O outro jeito de dar a um modelo o seu conhecimento é treiná-lo mais com os seus documentos (ajuste
fino, ou fine-tuning). Para fatos que mudam, a recuperação ganha em tudo o que importa aqui:

- **Uma mudança é uma edição.** O prazo de devolução muda num arquivo hoje e já está na próxima
  resposta. Um modelo ajustado sabe o prazo antigo até alguém treiná-lo de novo.
- **A resposta pode citar.** Um trecho tem um id, então a resposta pode dizer de onde veio, e um
  programa pode conferir (aula 6 seção 08). Conhecimento dentro dos parâmetros de um modelo não tem
  endereço.
- **O que não está nos trechos pode ser recusado.** "Os documentos não dizem" é uma frase que um
  modelo consegue escrever quando foi instruído a responder só com o que recebeu.

Ajuste fino serve para mudar como um modelo escreve, o formato ou o tom, não para ensinar fatos que
vão mudar.
