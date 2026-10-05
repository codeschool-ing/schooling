---
title: Trocar de modelo
version: 1
---

Cedo ou tarde aparece um modelo melhor ou mais barato, e os vetores guardados foram feitos pelo
antigo. O plano tentador é transformar os documentos novos em vetores com o modelo novo e deixar
os vetores antigos onde estão, já que os dois são listas de números e as dimensões podem até
coincidir. **Esse plano devolve lixo, e quando as dimensões coincidem ele faz isso sem erro
nenhum.** Vetores de dois modelos não podem ser comparados, e trocar de modelo significa calcular
de novo cada vetor guardado.

A aula 1 afirmou isso. `switch.py` mede, com um truque que deixa os dois modelos tão parecidos
quanto dois modelos podem ser. O modelo B é o modelo A com todos os vetores girados pela mesma
rotação aleatória em 384 dimensões. A aula 2 mostra que uma rotação não muda nenhum produto escalar
entre dois vetores girados, então B é um modelo exatamente tão bom quanto A. Só que as coordenadas
dele não são as de A.

```schooling-example
{
  "language": "python",
  "file": "switch.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nhelp = [json.loads(l) for l in open(\"data/help.jsonl\")]\nqueries = [json.loads(l) for l in open(\"data/queries.jsonl\")]\nids = [h[\"id\"] for h in help]\nD = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])\nQ = embed([q[\"text\"] for q in queries])",
      "note": "O modelo A é o all-MiniLM-L6-v2: os 40 artigos e as 24 perguntas, em vetores."
    },
    {
      "code": "rng = np.random.default_rng(0)\nR, _ = np.linalg.qr(rng.normal(size=(384, 384)))\nD2, Q2 = D @ R, Q @ R",
      "note": "O modelo B é o A girado por uma rotação aleatória do espaço de 384 dimensões, a mesma para todos os vetores. A decomposição QR de uma matriz aleatória dá uma rotação."
    },
    {
      "code": "def top1(Q, D):\n    best = (Q @ D.T).argmax(axis=1)\n    return sum(ids[b] in q[\"relevant\"] for b, q in zip(best, queries))\n\nprint(\"A queries, A articles:\", top1(Q, D), \"/ 24\")\nprint(\"B queries, B articles:\", top1(Q2, D2), \"/ 24\")\nprint(\"B queries, A articles:\", top1(Q2, D), \"/ 24\")",
      "note": "Conte as perguntas cujo melhor artigo é um certo, para cada modelo sozinho e para as perguntas de B contra os artigos de A."
    },
    {
      "code": "for name, X in ((\"A against A\", Q @ D.T), (\"B against A\", Q2 @ D.T)):\n    print(f\"{name}: scores from {X.min():.3f} to {X.max():.3f}\")",
      "note": "A menor e a maior nota entre todos os pares de pergunta e artigo, do mesmo modelo e misturados."
    },
    {
      "code": "wl = WordLlama.load()\ntry:\n    wl.embed([\"how do I get my money back\"], norm=True) @ D.T\nexcept ValueError as e:\n    print(\"ValueError:\", e)",
      "note": "Um segundo modelo de verdade, com outra dimensão, multiplicado contra os artigos do MiniLM."
    }
  ]
}
```

```
ana@lab:~/emb$ python switch.py
A queries, A articles: 19 / 24
B queries, B articles: 19 / 24
B queries, A articles: 1 / 24
A against A: scores from -0.175 to 0.686
B against A: scores from -0.151 to 0.210
ValueError: matmul: Input operand 1 has a mismatch in its core dimension 0, with gufunc signature (n?,k),(k,m?)->(n?,m?) (size 384 is different from 256)
```

**Cada modelo sozinho acha o artigo certo em primeiro para 19 das 24 perguntas.** Misturados, as
perguntas de B contra os artigos de A, ele acha 1, mais ou menos o que daria escolher um dos 40
artigos ao acaso. As notas dizem por quê. A contra A vai até 0,686, com o artigo certo bem destacado
do resto. B contra A fica entre −0,151 e 0,210 para todos os pares, uma faixa de ruído sem nada se
destacando.

Dois modelos de verdade ficam mais longe um do outro que uma rotação: foram
treinados com dados diferentes, e nada amarra um sistema de coordenadas ao outro. A rotação é o
caso mais favorável, e mesmo assim falha.

**A última linha é a falha com sorte.** Os 256 números do WordLlama não podem ser multiplicados
pelos 384 do MiniLM, então o NumPy recusa com um `ValueError`. Dois modelos com a mesma dimensão
não dão essa recusa. Uma troca de um modelo de 1536 dimensões por outro, com vetores antigos e
novos numa coleção só, devolve resultados, uma nota para cada um e um ranking com cara de qualquer
outro ranking. Só uma medição contra julgamentos de relevância, como os da aula 3, mostraria que
está errado.

## Guarde o modelo ao lado do vetor

A defesa é um fato guardado junto com os dados: **qual modelo, e qual versão dele, produziu cada
vetor.** Uma coleção guarda os vetores de um modelo, você anota o nome dele onde o código de busca
lê, e transforma a consulta em vetor com esse mesmo modelo. A aula 11 constrói um armazenamento
pequeno que guarda exatamente isso.

## Uma migração que nunca mistura os dois

Levar uma busca em produção para um modelo novo leva quatro passos, e é a ordem que garante que
cada consulta seja respondida por um modelo de cada vez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 740 300\" role=\"img\" aria-label=\"Uma grade de quatro passos no tempo, da esquerda para a direita, para duas coleções. Passo 1, escrita dupla: a coleção antiga, modelo A, recebe escritas e atende leituras; a coleção nova, modelo B, recebe escritas. Passo 2, preenchimento: o mesmo, e a coleção nova também recebe todos os documentos antigos transformados de novo em vetor. Passo 3, troca das leituras: a coleção nova atende as leituras; as duas ainda recebem escritas. Passo 4, apagar a antiga: a coleção antiga some e a nova recebe escritas e atende leituras.\"><defs><marker id=\"migpt-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M170 22 L728 22\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#migpt-ah0)\"></path><text x=\"728\" y=\"10\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text><text x=\"236\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">1  escrita dupla</text><text x=\"378\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">2  preenchimento</text><text x=\"520\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">3  troca das leituras</text><text x=\"662\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">4  apagar a antiga</text><text x=\"16\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">coleção antiga</text><text x=\"16\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">modelo A</text><text x=\"16\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">coleção nova</text><text x=\"16\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">modelo B</text><rect x=\"170\" y=\"80\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"236\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">escritas + leituras</text><rect x=\"312\" y=\"80\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"378\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">escritas + leituras</text><rect x=\"454\" y=\"80\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">escritas</text><rect x=\"596\" y=\"80\" width=\"132\" height=\"66\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"662\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">apagada</text><rect x=\"170\" y=\"170\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"236\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">escritas</text><rect x=\"312\" y=\"170\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"378\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">escritas</text><text x=\"378\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">+ preenchimento</text><rect x=\"454\" y=\"170\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"520\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">escritas + leituras</text><rect x=\"596\" y=\"170\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"662\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">escritas + leituras</text><text x=\"370\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cada leitura é respondida por uma coleção, e portanto por um modelo</text></svg>", "caption": "Os quatro passos de uma migração de modelo. A célula destacada em cada passo é a coleção que responde às buscas: a antiga até o passo 3, a nova a partir dele, nunca as duas."}
```

1. Escrita dupla. Crie uma segunda coleção para o modelo novo. A partir de agora, todo
   documento novo ou editado é transformado em vetor com os dois modelos e escrito nas duas
   coleções. As leituras continuam indo para a antiga.
2. Preenchimento. Transforme de novo em vetor cada documento existente com o modelo novo, na
   coleção nova, em lotes, no ritmo que o limite de requisições do fornecedor e o orçamento
   permitirem. A aula 18 põe preço neste passo, e costuma ser o caro.
3. Troca das leituras. Primeiro meça a coleção nova com os mesmos julgamentos de relevância da
   antiga, depois aponte a busca para ela: perguntas transformadas em vetor com o modelo novo,
   buscadas na coleção nova. Continue escrevendo nas duas por um tempo, para que voltar atrás seja
   uma mudança só.
4. Apague a coleção antiga quando ninguém mais precisar voltar atrás.

As duas coleções existem lado a lado do passo 1 ao passo 4, então o armazenamento dobra durante
esse tempo, o que a aula 18 também conta. Uma consulta nunca encontra um vetor do outro modelo,
porque o caminho de leitura indica uma coleção e essa coleção guarda um modelo.
