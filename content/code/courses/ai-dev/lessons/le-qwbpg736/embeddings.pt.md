---
title: Significado como posição
version: 2
---

Antes de um modelo fazer qualquer coisa com um token, ele o transforma numa lista de números, um
**vetor**. Esses vetores são aprendidos no treino de modo que tokens usados de jeitos parecidos
terminem perto uns dos outros, e essa proximidade é o que um modelo tem de mais parecido com
significado. A mesma ideia, aplicada a uma frase inteira em vez de a um token, dá um
**embedding**: um vetor por texto, feito por um modelo treinado exatamente para isso, de modo que
textos sobre a mesma coisa caiam perto uns dos outros.

Você vai usar embeddings diretamente, sem geração nenhuma, para buscar documentos pelo que dizem e
não pelas palavras que têm em comum. A aula 6 constrói isso. Esta seção é sobre o que são os
números e o que eles não conseguem fazer.

## Um texto vira 256 números

O modelo de embeddings que você instalou com as bibliotecas é o **WordLlama**, um modelo pequeno
que roda no processador de um notebook em milissegundos. Na primeira vez que é carregado, ele
baixa um arquivo pequeno, as configurações do seu tokenizador, e o guarda. Ele transforma
qualquer texto em 256 números:

```
ana@dev:~/shop$ python -c 'from wordllama import WordLlama; v = WordLlama.load().embed(["the cart total is wrong"]); print(v.shape, v.dtype); print(v[0][:6].round(3))'
(1, 256) float32
[-0.189 -0.251 -0.139  0.108  0.091 -0.229]
```

Nenhum número sozinho quer dizer nada. O que quer dizer alguma coisa é **a direção para onde o
vetor inteiro aponta**, comparada com a de outro. A comparação de costume é a **similaridade de
cosseno**: 1 quando dois vetores apontam para o mesmo lado, 0 quando não têm relação, e abaixo de
0 quando apontam para lados opostos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três embeddings desenhados como setas a partir de um ponto. A consulta, the cart total is wrong, aponta para a direita. The cart page loads slowly aponta 58 graus para longe, cosseno 0,529. Our office opens at nine aponta 92 graus para longe, cosseno menos 0,028.\"><defs><marker id=\"an-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M150 260 L380.0 260.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#an-ah)\"></path><path d=\"M150 260 L271.7 64.8\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#an-ah)\"></path><path d=\"M150 260 L143.6 30.1\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#an-ah)\"></path><circle cx=\"150\" cy=\"260\" r=\"3\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"388.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">consulta</text><text x=\"388.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">the cart total is wrong</text><text x=\"281.7\" y=\"58.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">the cart page loads slowly</text><text x=\"281.7\" y=\"74.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">perto: cosseno 0,529</text><text x=\"153.6\" y=\"24.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">our office opens at nine</text><text x=\"153.6\" y=\"40.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem relação: cosseno −0,028</text><path d=\"M210 260 A60 60 0 0 0 181.7 209.1\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M190 260 A40 40 0 0 0 148.9 220.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "A similaridade é o ângulo entre dois vetores. Estes ângulos são os cossenos reais da captura abaixo, desenhados em duas dimensões; os vetores do WordLlama têm 256."}
```

## Perguntando que frases estão perto

O `~/shop/scratch/similar.py` gera o embedding de uma consulta e de alguns textos candidatos, e
lista os candidatos pela similaridade de cosseno com a consulta:

```python
import sys

import numpy as np
from wordllama import WordLlama

wl = WordLlama.load()
query, *texts = [line.strip() for line in sys.stdin if line.strip()]
vectors = wl.embed([query] + texts, norm=True)
scores = vectors[1:] @ vectors[0]
print(f"query: {query}")
for i in np.argsort(-scores):
    print(f"  {scores[i]:+.3f}  {texts[i]}")
```

Aqui está uma pergunta de suporte contra quatro frases, duas das quais são a mesma reclamação com
outras palavras:

```
ana@dev:~/shop$ printf "%s\n" "the cart total is wrong" "checkout adds up the order incorrectly" "the sum shown at checkout is too high" "the cart page loads slowly" "our office opens at nine" | python scratch/similar.py
query: the cart total is wrong
  +0.529  the cart page loads slowly
  +0.347  checkout adds up the order incorrectly
  +0.178  the sum shown at checkout is too high
  -0.028  our office opens at nine
```

A frase sem relação vem por último, como devia. **Mas o vencedor está errado.** Uma página lenta é
um problema diferente de um total errado, e ela fica em primeiro porque divide as palavras
`the cart` com a consulta. O WordLlama é pequeno e se apoia muito nas próprias palavras; as duas
reformulações quase não dividem palavras com a consulta e perdem para uma frase que divide.
Modelos de embedding maiores, os que os provedores vendem, são muito melhores com paráfrase.
Ainda cometem esse tipo de erro, com menos frequência, e nenhuma nota avisa quando cometeram.

O segundo limite aparece até em modelos bons:

```
ana@dev:~/shop$ printf "%s\n" "the coupon was accepted" "the coupon was not accepted" "the coupon was refused" "the voucher was accepted" | python scratch/similar.py
query: the coupon was accepted
  +0.964  the coupon was not accepted
  +0.664  the coupon was refused
  +0.271  the voucher was accepted
```

**A afirmação oposta é a mais próxima, com 0,964.** Um embedding situa um texto pelo assunto, e
*was accepted* e *was not accepted* falam do mesmo assunto. Embeddings respondem "isto é sobre a
mesma coisa?", não "isto diz a mesma coisa?". Uma busca construída sobre eles acha o trecho sobre
reembolso. Ler o trecho para ver se reembolso é permitido é trabalho do modelo gerador, ou seu.

## O que tirar desses números

- **Uma nota de similaridade é uma ordenação, não um veredito.** 0,529 aqui não quer dizer "53%
  igual"; notas de modelos diferentes nem estão na mesma escala. Compare notas só com outras notas
  do mesmo modelo.
- **Teste um modelo de embeddings no seu próprio material** antes de confiar nele, com um punhado
  de consultas cujas respostas certas você conhece. A aula 6 faz isso e transforma em um número.
- **Identificadores exatos são um ponto fraco.** Um código de erro ou uma referência de produto é
  uma sequência a casar, não um significado a aproximar; a aula 6 acrescenta busca por palavra
  exatamente para esse caso.
