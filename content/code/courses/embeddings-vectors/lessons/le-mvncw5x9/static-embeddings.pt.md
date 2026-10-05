---
title: Embeddings estáticos
version: 1
---

Todos os modelos desta aula até aqui rodam uma rede sobre cada texto: as palavras entram, uma pilha
de camadas trabalha sobre elas e sai um vetor. É fácil concluir que é isso que um modelo de
embedding *é*. **Um modelo estático não tem camada nenhuma para rodar.** Ele é uma tabela com uma
linha por token, e o vetor de um texto é a média das linhas dos tokens dele. A aula 1 apresentou o
WordLlama como um desses; esta seção abre o modelo e mede o que a falta das camadas compra e o que
ela custa.

```schooling-example
{
  "language": "python",
  "file": "static.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom wordllama import WordLlama\n\nwl = WordLlama.load()\nprint(wl.embedding.shape, wl.embedding.dtype)",
      "note": "`wl.embedding` é o modelo: um array do NumPy com uma linha por token do vocabulário."
    },
    {
      "code": "text = \"Is there a cheaper postage option for a single paperback?\"\nids = wl.tokenizer.encode(text, add_special_tokens=False).ids\nv = wl.embedding[ids].mean(axis=0)\nv /= np.linalg.norm(v)",
      "note": "Faça à mão o que `embed()` faz: divida a frase em ids de token, pegue as linhas deles, tire a média e divida pelo comprimento."
    },
    {
      "code": "print(len(ids), \"tokens\")\nprint(\"same as embed():\", np.allclose(v, wl.embed(text, norm=True)[0], atol=1e-6))",
      "note": "Compare o vetor feito à mão com o da biblioteca, admitindo arredondamento nos últimos dígitos."
    }
  ]
}
```

```
ana@lab:~/emb$ python static.py
(32000, 256) float32
14 tokens
same as embed(): True
ana@lab:~/emb$ ls -l /opt/emb/lib/python3.11/site-packages/wordllama/weights/ /opt/emb/share/all-MiniLM-L6-v2/model.onnx
-rw-r--r-- 1 root root 90387606 Oct  5 13:23 /opt/emb/share/all-MiniLM-L6-v2/model.onnx

/opt/emb/lib/python3.11/site-packages/wordllama/weights/:
total 16004
-rw-r--r-- 1 root root 16384096 Oct  5 13:21 l2_supercat_256.safetensors
```

**A tabela tem 32.000 linhas de 256 números**, uma linha para cada token do vocabulário do
WordLlama. Buscar os 14 tokens da frase, tirar a média das linhas deles e dividir pelo comprimento
dá exatamente o que `embed()` devolve: `same as embed(): True`. O modelo é só isso. O arquivo em
disco tem 16.384.096 bytes, que são 32.000 × 256 × 2 bytes mais um cabeçalho pequeno: ele guarda
cada número em dois bytes, e o carregador os amplia para o `float32` que a primeira linha imprimiu.
O `model.onnx` do all-MiniLM-L6-v2 tem 90.387.606 bytes, umas cinco vezes e meia maior, e quase
tudo isso são os pesos das seis camadas que o WordLlama não tem.

O README do WordLlama, dentro do pacote que o laboratório instalou, diz de onde veio a tabela: ela
partiu da tabela de tokens de um grande modelo de linguagem e depois foi treinada, numa única GPU,
como um modelo sem contexto. A aula 1 mostrou o preço de não ter contexto: *the dog bit the man*
("o cachorro mordeu o homem") e *the man bit the dog* ("o homem mordeu o cachorro") recebem o mesmo
vetor, porque uma média não sabe nada de ordem.

## O que ele compra: velocidade

`speed.py` transforma em vetores as 150 mensagens de clientes de `tickets.jsonl` com os dois
modelos, cinco vezes cada um, e fica com a rodada mais rápida, para que um momento em que a máquina
estava ocupada não conte.

```schooling-example
{
  "language": "python",
  "file": "speed.py",
  "parts": [
    {
      "code": "import json\nimport time\nfrom minilm import embed\nfrom wordllama import WordLlama\n\ntexts = [t[\"text\"] for t in map(json.loads, open(\"data/tickets.jsonl\"))]\nwl = WordLlama.load()",
      "note": "Os 150 textos dos tickets, e o WordLlama carregado uma vez, fora da medição."
    },
    {
      "code": "def best(f, runs=5):\n    times = []\n    for _ in range(runs):\n        t = time.perf_counter()\n        f()\n        times.append(time.perf_counter() - t)\n    return min(times)",
      "note": "Rode uma função cinco vezes e fique com a mais rápida, para que um momento em que a máquina estava ocupada não conte contra um modelo."
    },
    {
      "code": "m = best(lambda: embed(texts))\nw = best(lambda: wl.embed(texts, norm=True))\nprint(f\"{len(texts)} texts\")\nprint(f\"minilm     {m * 1000:7.1f} ms {len(texts) / m:8.0f} texts/s\")\nprint(f\"wordllama  {w * 1000:7.1f} ms {len(texts) / w:8.0f} texts/s\")\nprint(f\"wordllama is {m / w:.0f} times faster\")",
      "note": "Meça os dois modelos nos mesmos textos e imprima milissegundos, textos por segundo e a razão."
    }
  ]
}
```

```
ana@lab:~/emb$ nproc; grep -m1 "model name" /proc/cpuinfo
4
model name	: Intel(R) Xeon(R) Processor @ 2.10GHz
ana@lab:~/emb$ python speed.py
150 texts
minilm       723.6 ms      207 texts/s
wordllama      5.7 ms    26489 texts/s
wordllama is 128 times faster
```

**O WordLlama transformou as 150 mensagens 128 vezes mais rápido**: 5,7 ms contra 723,6 ms, ou
26.489 textos por segundo contra 207. O `minilm.py` roda o modelo numa thread só, e esta máquina tem
quatro núcleos. Mesmo um ganho perfeito de quatro vezes usando todos eles deixaria o MiniLM umas 32
vezes mais lento, então a diferença é uma propriedade dos dois modelos, e não da configuração.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Três pares de barras comparando o all-MiniLM-L6-v2 com o WordLlama nesta máquina. Textos transformados em vetor por segundo: MiniLM 207, WordLlama 26489. Perguntas da central de ajuda com um artigo certo entre os três primeiros, de 24: MiniLM 22, WordLlama 24. Tickets de teste rotulados certo pelo ticket de treino mais próximo, de 50: MiniLM 46, WordLlama 40.\"><rect x=\"470\" y=\"18\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"25\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">all-MiniLM-L6-v2</text><rect x=\"620\" y=\"18\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"640\" y=\"25\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WordLlama</text><text x=\"30\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">textos transformados em vetor por segundo</text><rect x=\"30\" y=\"74\" width=\"4.4\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"42.4\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">207</text><rect x=\"30\" y=\"98\" width=\"560\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"598\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">26489</text><text x=\"30\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">perguntas com um artigo certo entre os 3 primeiros, de 24</text><rect x=\"30\" y=\"160\" width=\"513.3\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"551.3\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">22</text><rect x=\"30\" y=\"184\" width=\"560\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"598\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">24</text><text x=\"30\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">tickets de teste rotulados certo, de 50</text><rect x=\"30\" y=\"246\" width=\"560\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"598\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">46</text><rect x=\"30\" y=\"270\" width=\"487\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"525\" y=\"279\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">40</text><text x=\"690\" y=\"316\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cada linha está na escala do seu maior valor</text></svg>", "caption": "Medido nesta máquina com os dados do curso. O WordLlama é duas ordens de grandeza mais rápido e se sai bem nas perguntas curtas da central de ajuda; nos tickets de frases inteiras ele acerta seis a menos."}
```

Uma busca numa tabela e uma média não custam quase nada perto de seis camadas em que cada pedaço
olha para todos os outros. É isso que faz os modelos estáticos caberem onde um transformer não
cabe: uma primeira passada sobre milhões de documentos, a remoção de quase-duplicatas, um celular,
ou um servidor sem GPU e com orçamento apertado.

## O que ele custa: medido nos dados do curso

Velocidade só vale alguma coisa se os vetores continuam fazendo o trabalho. `quality.py` mede dois
trabalhos com os dois modelos. O primeiro é a busca da aula 3: para cada uma das 24 perguntas de
`queries.jsonl`, um artigo certo vem em primeiro, ou entre os três primeiros? O segundo é um
classificador simples para os 50 tickets de teste, que dá a cada um o rótulo do mais parecido
entre os 100 tickets de treino. A
aula 4 constrói esse classificador e outros melhores; este basta para comparar dois modelos.

```schooling-example
{
  "language": "python",
  "file": "quality.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nwl = WordLlama.load()\nmodels = {\"minilm\": embed, \"wordllama\": lambda t: wl.embed(t, norm=True)}\nrows = lambda f: [json.loads(l) for l in open(f)]\nhelp, queries, tickets = rows(\"data/help.jsonl\"), rows(\"data/queries.jsonl\"), rows(\"data/tickets.jsonl\")\ntrain = [t for t in tickets if t[\"split\"] == \"train\"]\ntest = [t for t in tickets if t[\"split\"] == \"test\"]\nids = [h[\"id\"] for h in help]",
      "note": "Os dois modelos atrás de uma função cada, para que a medição seja escrita uma vez só. Os artigos, as 24 perguntas e os tickets divididos nos 100 de aprendizado e nos 50 de teste."
    },
    {
      "code": "for name, f in models.items():\n    D = f([h[\"title\"] + \". \" + h[\"body\"] for h in help])\n    Q = f([q[\"text\"] for q in queries])\n    top = np.argsort(-(Q @ D.T), axis=1)[:, :3]\n    r1 = sum(ids[t[0]] in q[\"relevant\"] for t, q in zip(top, queries))\n    r3 = sum(any(ids[i] in q[\"relevant\"] for i in t) for t, q in zip(top, queries))",
      "note": "A busca: cada pergunta contra cada artigo, os três melhores de cada uma, e quantas perguntas tiveram um artigo certo em primeiro e entre os três primeiros."
    },
    {
      "code": "    A, B = f([t[\"text\"] for t in train]), f([t[\"text\"] for t in test])\n    near = (B @ A.T).argmax(axis=1)\n    ok = sum(train[j][\"label\"] == t[\"label\"] for j, t in zip(near, test))\n    print(f\"{name:10} top-1 {r1}/24  top-3 {r3}/24  tickets {ok}/50\")",
      "note": "O classificador: cada ticket de teste recebe o rótulo do ticket de treino mais parecido. Conte quantos receberam o próprio rótulo."
    }
  ]
}
```

```
ana@lab:~/emb$ python quality.py
minilm     top-1 19/24  top-3 22/24  tickets 46/50
wordllama  top-1 20/24  top-3 24/24  tickets 40/50
```

**Na busca, o WordLlama foi tão bem quanto o MiniLM ou melhor**: 20 contra 19 em primeiro, 24
contra 22 entre os três primeiros. **Nos tickets ele acertou 6 a menos**, 40 de 50 contra 46. Dois
resultados em direções opostas, com dados escritos para este curso, e os dois pequenos o bastante
para uma pergunta ou um ticket mudá-los. Por isso, olhe os próprios tickets:

```schooling-example
{
  "language": "python",
  "file": "misses.py",
  "parts": [
    {
      "code": "import json\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nwl = WordLlama.load()\ntickets = [json.loads(l) for l in open(\"data/tickets.jsonl\")]\ntrain = [t for t in tickets if t[\"split\"] == \"train\"]\nA = {\"minilm\": embed([t[\"text\"] for t in train]),\n     \"wordllama\": wl.embed([t[\"text\"] for t in train], norm=True)}\nfor t in tickets:\n    if t[\"id\"] not in (\"t026\", \"t120\"):\n        continue\n    print(f\"{t['id']} [{t['label']}] {t['text']}\")\n    for name, f in ((\"minilm\", embed), (\"wordllama\", lambda x: wl.embed(x, norm=True))):\n        n = train[int((A[name] @ f([t[\"text\"]])[0]).argmax())]\n        print(f\"  {name:10} [{n['label']}] {n['text']}\")",
      "note": "Dois tickets de teste que o WordLlama rotulou errado e o MiniLM rotulou certo. Para cada um, imprima o ticket de treino mais próximo segundo cada modelo, com o rótulo dele."
    }
  ]
}
```

```
ana@lab:~/emb$ python misses.py
t026 [shipping] Is there a cheaper postage option for a single paperback?
  minilm     [shipping] Is free postage still over 40 or did that change?
  wordllama  [returns] Can I swap the paperback for the hardcover?
t120 [account] My wishlist is empty after I signed in on my laptop.
  minilm     [account] My reading lists disappeared from my profile.
  wordllama  [ebooks] My e-book library is empty on my new tablet.
```

**O WordLlama casou por uma palavra em comum e errou o sentido.** Uma pergunta sobre frete mais
barato para um livro de bolso (*paperback*) foi parar num ticket sobre trocar um *paperback* por
capa dura. Uma lista de desejos vazia (*empty*) depois do login foi parar numa biblioteca de e-books
vazia num tablet. As palavras *paperback* e *empty* dominam uma média de uma dúzia de tokens. O
MiniLM, cujas camadas combinam as palavras antes da média, achou tickets que compartilham a
situação: frete, e listas que sumiram de um perfil.

As perguntas da central de ajuda são curtas, e as palavras-chave delas dão nome ao assunto, que é
o caso em que uma média se sai bem. Os tickets são frases inteiras cujo sentido está em como as
palavras se combinam, e é aí que as camadas pagam o que custam.

## Model2Vec, descrito e não executado

O WordLlama é um jeito de fazer um modelo estático. O **Model2Vec** é outro: ele pega um sentence
transformer que já existe, passa cada token do vocabulário por ele uma vez e guarda as saídas como a
tabela, encolhida com análise de componentes principais. O resultado herda parte do que o
transformer sabia, e há versões multilíngues. Segundo o próprio README, o WordLlama 0.4 consegue
carregá-los com `WordLlama.load_m2v(...)`. Os modelos ficam no Hugging Face, fora de alcance desta
máquina, então nenhum foi carregado nem medido aqui.
