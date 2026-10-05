---
title: Classificação sem exemplos
version: 1
---

Todos os métodos até aqui precisaram de tickets que alguém já tinha separado. No dia em que uma fila
nova abre, não há nenhum. A classificação **zero-shot**, sem exemplos, troca os exemplos por algumas
palavras por setor: transforme em vetor um texto curto que descreve cada setor e dê a cada ticket o
rótulo da descrição mais próxima. É o método dos centroides com os centroides escritos à mão em vez
de calculados como média dos dados.

Como essas poucas palavras são escolhidas faz muita diferença, então o programa testa três redações
dos mesmos cinco setores:

```schooling-example
{
  "language": "python",
  "file": "zeroshot.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom minilm import embed\nfrom tickets import load\n\nXte, yte, test = load(\"test\")\nlabels = [\"account\", \"ebooks\", \"payments\", \"returns\", \"shipping\"]",
      "note": "Só os tickets de teste são carregados. Nenhum ticket de treino e nenhum rótulo de treino é lido neste programa."
    },
    {
      "code": "wordings = {\n    \"names\": [\"account\", \"ebooks\", \"payments\", \"returns\", \"shipping\"],\n    \"descriptions\": [\n        \"a question about signing in, passwords and personal data\",\n        \"a question about e-books, audiobooks and the reading app\",\n        \"a question about paying, cards, charges and invoices\",\n        \"a question about sending a book back for a refund or exchange\",\n        \"a question about delivery and parcels\",\n    ],\n    \"examples\": [\n        \"I can't log in to my account.\",\n        \"My e-book won't open in the app.\",\n        \"My card was charged twice at checkout.\",\n        \"I want to return this book and get a refund.\",\n        \"Where is my parcel? It has not been delivered yet.\",\n    ],\n}",
      "note": "Três jeitos de descrever os mesmos cinco setores, cada lista na ordem de `labels`: o nome puro, uma frase dizendo o que o setor atende e um exemplo de mensagem."
    },
    {
      "code": "for name, texts in wordings.items():\n    D = embed(texts)\n    pred = np.array(labels)[(Xte @ D.T).argmax(axis=1)]\n    print(f\"{name:13} {(pred == yte).sum()} of {len(yte)} right\")",
      "note": "Para cada redação, transforma os cinco textos em vetores e dá a cada ticket o rótulo do mais próximo."
    }
  ]
}
```

```
ana@lab:~/emb$ python zeroshot.py
names         39 of 50 right
descriptions  43 of 50 right
examples      35 of 50 right
```

**Sem nenhum ticket rotulado, a melhor redação acerta 43 dos 50.** São quatro tickets atrás dos
centroides, e não foi preciso mais nada: cinco frases e o modelo que já estava ali.

## A redação é o modelo

O mesmo modelo de embedding, os mesmos tickets, e a nota vai de 35 a 43 dependendo só das frases.
Cada redação falha de um jeito.

**Os nomes puros** acertam 39. Uma palavra como `returns` ou `account` é um texto muito curto, e o
vetor dela carrega o que essa palavra significa para o modelo, que não é bem o que a Marginalia quer
dizer com ela.

**Uma frase de exemplo por setor** acerta 35, a pior das três. *My card was charged twice at
checkout* ("meu cartão foi cobrado duas vezes no pagamento") é um ticket de pagamentos, mas é um
ticket de pagamentos em particular, e uma pergunta sobre nota fiscal fica longe dele. Isso é o
vizinho mais próximo com um exemplo por setor, e a seção anterior mediu esse caso em 37 com tickets
de verdade.

**Uma descrição que lista o que o setor atende** acerta 43. *A question about paying, cards, charges
and invoices* ("uma pergunta sobre pagar, cartões, cobranças e notas fiscais") não é nenhum ticket de
pagamento em particular: ela nomeia várias das coisas de que eles tratam, e essa redação acertou
oito tickets a mais que as frases de exemplo.

## Ajustar uma redação no conjunto de teste é treinar com ele

O parágrafo acima tem uma armadilha. As três redações foram comparadas nos 50 tickets de teste. Se
o próximo passo for continuar mexendo nas descrições até a nota parar de subir, o conjunto de
teste deixa de ser um teste: as descrições aprenderam com ele, por meio de você. Com 50 tickets, uma
redação que vence por dois ou três pode só estar bem ajustada a estes 50.

A saída é a mesma de qualquer outro método. Ajuste a redação contra tickets separados para isso, e
guarde o conjunto de teste para uma última olhada no fim.

## Onde a classificação sem exemplos se encaixa

A classificação zero-shot é como uma fila nova começa, não onde ela fica. Ela separa as primeiras
mensagens bem o bastante para ser útil; uma pessoa corrige as que ela erra; e depois de algumas
semanas há tickets rotulados suficientes para centroides ou para um classificador treinado, que aqui
a vencem por quatro tickets.

O outro uso é para rótulos que mudam. Acrescentar um sexto setor a um classificador zero-shot é uma
frase a mais. Acrescentar a um treinado significa juntar exemplos e treinar de novo. A aula 6 chega
exatamente a esse momento, quando uma assinatura nova traz um tipo de mensagem que nenhum dos cinco
setores espera.
