---
title: Perto quer dizer parecido
version: 1
---

O objetivo de um embedding é a comparação. Dois textos de significado parecido devem produzir
vetores que apontam em direções parecidas, e dois textos sem relação não. Isso pode ser conferido
diretamente: transforme em vetor a pergunta da cliente e seis artigos, e dê uma nota a cada artigo
em relação à pergunta.

```schooling-example
{
  "language": "python",
  "file": "near.py",
  "parts": [
    {
      "code": "import json\nfrom minilm import embed\n\nhelp = {h[\"id\"]: h for h in map(json.loads, open(\"data/help.jsonl\"))}\nquestion = \"how do I get my money back\"\nids = [\"h15\", \"h14\", \"h18\", \"h33\", \"h07\", \"h29\"]",
      "note": "Leia os 40 artigos num dicionário indexado pelo id e escolha seis: quatro sobre receber dinheiro de volta, um sobre entrega e um sobre login."
    },
    {
      "code": "docs = [help[i][\"title\"] + \". \" + help[i][\"body\"] for i in ids]\nq = embed(question)[0]\nD = embed(docs)",
      "note": "Transforme a pergunta em vetor uma vez e os seis artigos juntos. Cada artigo é o título mais o corpo, que é o que uma busca compararia."
    },
    {
      "code": "scores = D @ q\nfor i, s in sorted(zip(ids, scores), key=lambda p: -p[1]):\n    print(f\"{s:6.3f}  {i}  {help[i]['title']}\")",
      "note": "`D @ q` são seis produtos escalares de uma vez, um por artigo. Imprima do maior para o menor."
    }
  ]
}
```

```
ana@lab:~/emb$ python near.py
 0.446  h18  Returning a gift
 0.438  h15  When your refund arrives
 0.392  h14  How to return a book
 0.390  h33  Refunds for e-books
 0.169  h29  Two-step sign-in
-0.016  h07  Delivery times and costs
```

A nota é o **produto escalar** dos dois vetores: multiplique coordenada por coordenada e some os 384
produtos. Como todo vetor deste modelo tem comprimento 1, o produto escalar também é o cosseno do
ângulo entre eles, que vale 1 para a mesma direção e 0 para direções sem relação. A aula 2 monta
essa fórmula à mão; aqui basta ler como *mais alto é mais perto*.

**Os quatro artigos sobre receber dinheiro de volta ficam entre 0,390 e 0,446**, e os dois sem
relação ficam em 0,169 e −0,016. Nenhum dos quatro contém as palavras *money back*, a não ser o
artigo do presente. O modelo colocou *money back* perto de *refund* sem que ninguém dissesse que
eram sinônimos.

Ele também pôs o artigo do presente em primeiro, por 0,008, à frente do artigo que de fato responde à
pergunta. Esse é um resultado real e não um erro do programa, e é típico: um embedding ordena por
proximidade de significado, e *devolver um presente para receber o dinheiro de volta* está de fato
perto de *receber meu dinheiro de volta*. A aula 3 mede com que frequência a melhor resposta fica em
primeiro e com que frequência fica entre as três primeiras, que é o número pelo qual uma busca
costuma ser julgada.

## Um retrato do espaço

Ninguém consegue desenhar 384 dimensões. O que dá para desenhar é uma **projeção**: uma imagem plana
que guarda o máximo do espalhamento entre os pontos que dois eixos conseguem guardar. A figura
abaixo pega os títulos dos artigos de entrega, pagamento e e-book, transforma em vetores e projeta
com análise de componentes principais, o mesmo método que qualquer biblioteca de estatística
oferece.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 430\" role=\"img\" aria-label=\"Um gráfico de dispersão de dezenove títulos de artigos da central de ajuda, transformados em vetores pelo all-MiniLM-L6-v2 e projetados de 384 dimensões para duas. Os artigos de entrega ficam à esquerda e em cima, os de pagamento embaixo e os de e-book à direita. Damaged books on arrival, um artigo de entrega, fica perto dos e-books; Refunds for e-books fica perto dos pagamentos.\"><path d=\"M50 400 L690 400\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M50 400 L50 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"179.8\" cy=\"134\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"189.8\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h07</text><circle cx=\"154.4\" cy=\"79.7\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"164.4\" y=\"79.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h08</text><circle cx=\"135.8\" cy=\"82.4\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"125.8\" y=\"82.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h09</text><circle cx=\"199.3\" cy=\"69.8\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"209.3\" y=\"69.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h10</text><circle cx=\"193.6\" cy=\"167\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"203.6\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h11</text><circle cx=\"423.3\" cy=\"72.5\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"433.3\" y=\"72.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h12</text><text x=\"459.3\" y=\"72.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Damaged books on arrival</text><circle cx=\"124.7\" cy=\"110.9\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"134.7\" y=\"110.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h13</text><rect x=\"322.2\" y=\"358.4\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"338.2\" y=\"364.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h20</text><rect x=\"295.1\" y=\"340.4\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"311.1\" y=\"346.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h21</text><rect x=\"229.3\" y=\"238.4\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"245.3\" y=\"244.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h22</text><rect x=\"293.3\" y=\"226.1\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"289.3\" y=\"232.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h23</text><rect x=\"384.4\" y=\"226.7\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"400.4\" y=\"232.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h24</text><rect x=\"306.7\" y=\"224.6\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"322.7\" y=\"230.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h25</text><circle cx=\"619.8\" cy=\"104\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"629.8\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h32</text><circle cx=\"558.4\" cy=\"183.5\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"568.4\" y=\"183.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h33</text><text x=\"594.4\" y=\"183.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Refunds for e-books</text><circle cx=\"600.2\" cy=\"81.8\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"610.2\" y=\"81.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h34</text><circle cx=\"595.3\" cy=\"215.9\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"605.3\" y=\"215.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h35</text><circle cx=\"580.7\" cy=\"124.4\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"590.7\" y=\"124.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h36</text><circle cx=\"586\" cy=\"153.5\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"596\" y=\"153.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h37</text><circle cx=\"470\" cy=\"40\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"482\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">entrega</text><rect x=\"554\" y=\"34\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"572\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pagamentos</text><circle cx=\"650\" cy=\"40\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"662\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">e-books</text><text x=\"690\" y=\"418\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dois eixos guardam 0,317 da variância</text></svg>", "caption": "Dezenove títulos de artigos de três categorias, transformados em vetores e achatados em dois eixos. As categorias se separam sem que ninguém as informe; os dois artigos que ficam entre grupos são os que tratam de dois assuntos ao mesmo tempo.", "same": ["Damaged books on arrival", "Refunds for e-books", "e-books"]}
```

Os três grupos se separam sozinhos. Nada disse ao modelo a categoria de cada artigo; as categorias
saíram do significado dos títulos. Dois pontos ficam onde não se esperaria, e os dois fazem sentido
quando se lê o título: **Damaged books on arrival** ("livros danificados na chegada") é um artigo de
entrega que fala de livros, então escorrega para os e-books; **Refunds for e-books** ("reembolso de
e-books") é um artigo de e-book que fala de dinheiro, então escorrega para os pagamentos.

Trate a figura como um esboço e não como uma medida. Os dois eixos guardaram 0,317 da variância, um
pouco menos de um terço, então as distâncias na figura são só aproximadamente as distâncias no
espaço. Um ponto pode parecer perto de outro no papel e estar mais longe em 384 dimensões. As notas
de `near.py` são a comparação de verdade; a figura é um jeito de ver que existe uma estrutura.
