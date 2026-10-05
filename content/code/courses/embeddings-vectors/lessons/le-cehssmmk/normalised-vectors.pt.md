---
title: Vetores que não estão normalizados
version: 1
---

O all-MiniLM-L6-v2 divide cada vetor pelo próprio comprimento antes de devolvê-lo, então os vetores
dele estão **normalizados**: comprimento 1, todos eles. Isso é uma escolha, não uma lei, e um modelo
que pula essa etapa traz a armadilha de *O produto escalar, à mão* de volta para uma busca de
verdade.

O WordLlama pula por padrão. A aula 1 passou `norm=True` ao WordLlama de propósito; `lengths.py`
deixa de fora:

```schooling-example
{
  "language": "python",
  "file": "lengths.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom wordllama import WordLlama\n\nwl = WordLlama.load()\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nids = [h[\"id\"] for h in help]\nW = wl.embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])",
      "note": "Transforme os 40 artigos em vetores com o WordLlama, sem `norm=True`, para que cada vetor fique com o comprimento que o modelo deu."
    },
    {
      "code": "for text in [\"refund\", \"When your refund arrives\"]:\n    print(f\"{np.linalg.norm(wl.embed(text)[0]):.3f}  {text!r}\")\nn = np.linalg.norm(W, axis=1)\nprint(f\"articles: shortest {n.min():.3f}, longest {n.max():.3f}\")",
      "note": "O comprimento do vetor de uma palavra, o de um título e a faixa entre os artigos."
    },
    {
      "code": "q = wl.embed(\"discount for a classroom set\")[0]\nraw = W @ q\ncos = raw / (n * np.linalg.norm(q))\nfor i in [ids.index(\"h37\"), ids.index(\"h05\")]:\n    print(f\"{ids[i]}  raw {raw[i]:.3f}  length {n[i]:.3f}  cosine {cos[i]:.3f}  {help[i]['title']}\")",
      "note": "Uma pergunta avaliada de dois jeitos contra dois artigos: o produto escalar puro e o cosseno, que divide os dois comprimentos."
    },
    {
      "code": "Wn = W / n[:, None]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nfor query in queries:\n    q = wl.embed(query[\"text\"])[0]\n    by_raw, by_cos = ids[np.argmax(W @ q)], ids[np.argmax(Wn @ q)]\n    if by_raw != by_cos:\n        print(f\"{query['id']}  raw {by_raw}  cosine {by_cos}  relevant {' '.join(query['relevant'])}\")",
      "note": "Para cada uma das 24 perguntas, o artigo em primeiro pelo produto escalar puro e pelo cosseno. Imprima as perguntas em que eles diferem, com o artigo que o curso marcou como resposta."
    }
  ]
}
```

```
ana@lab:~/emb$ python lengths.py
9.104  'refund'
3.945  'When your refund arrives'
articles: shortest 1.212, longest 2.280
h37  raw 1.707  length 1.905  cosine 0.212  Audiobooks
h05  raw 1.554  length 1.490  cosine 0.247  Orders for schools and libraries
q08  raw h12  cosine h10  relevant h10
q12  raw h10  cosine h07  relevant h07
q15  raw h32  cosine h36  relevant h36
q16  raw h20  cosine h21  relevant h21
q21  raw h37  cosine h05  relevant h05
```

## Comprimento não é significado

**A palavra *refund* ("reembolso") sozinha tem um vetor de comprimento 9,104; o título *When your
refund arrives* ("quando o seu reembolso chega") tem 3,945, e os 40 artigos vão de 1,212 a
2,280.** O WordLlama tira a média dos vetores fixos dos tokens de um texto, e a média de setas que
apontam para muitos lados é mais curta que as próprias setas. Uma palavra sozinha não entra em média
com nada, então continua comprida. O comprimento registra o quanto os tokens de um texto discordam
entre si, e não é isso que uma busca quer saber.

O produto escalar conta isso mesmo assim. Diante de *discount for a classroom set* ("desconto para
um lote de livros para a turma"), o produto escalar puro põe **Audiobooks** ("audiolivros") em
primeiro, 1,707 contra 1,554 de **Orders for schools and libraries** ("pedidos para escolas e
bibliotecas"), o artigo que de fato oferece 15% de desconto às escolas. Audiobooks ganha no
comprimento, 1,905 contra 1,490. Tire os comprimentos e a ordem se inverte: cosseno 0,212 para
Audiobooks e 0,247 para o artigo das escolas.

Nas 24 perguntas, o artigo em primeiro mudou em cinco, e **nas cinco a escolha do cosseno é o artigo
que o curso marcou como resposta**. O comprimento não dizia
nada sobre a pergunta, só o quanto os tokens de cada texto discordam entre si.

## Normalize uma vez, na hora de gravar

A correção é uma linha, e o lugar onde ela entra importa mais do que a linha:

`V = V / np.linalg.norm(V, axis=1, keepdims=True)`

Faça isso **quando os vetores forem guardados**, e faça o mesmo com cada consulta antes de comparar.
Daí em diante todo vetor guardado tem comprimento 1, o produto escalar simples é o cosseno e toda
ferramenta adiante pode usar a comparação mais barata que existe. Esquecer não dá erro: a busca
continua devolvendo cinco artigos, só que ordenados em parte por um acaso da média. A aula 7
encontra a mesma regra pelo outro lado, quando o vetor de um provedor é cortado e o comprimento
dele deixa de ser 1.

Guarde os vetores sem normalizar só quando a documentação do modelo disser que o comprimento carrega
alguma coisa, o que acontece em alguns modelos treinados com o produto escalar. Para um modelo que
não diz nada, ou que manda usar cosseno, normalize.
