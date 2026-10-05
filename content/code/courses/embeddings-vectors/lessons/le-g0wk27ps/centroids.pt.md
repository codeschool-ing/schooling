---
title: Centroides
version: 1
---

O k-vizinhos guarda os 100 exemplos e pergunta com qual deles um ticket novo se parece. Um
**centroide** guarda um vetor por setor, a média dos exemplos daquele setor, e pergunta com qual
setor o ticket se parece. São cinco comparações em vez de cem, e com os dados desta aula isso não
custa nada.

```schooling-example
{
  "language": "python",
  "file": "centroids.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom tickets import load\n\nXtr, ytr, train = load(\"train\")\nXte, yte, test = load(\"test\")\nlabels = sorted(set(ytr))",
      "note": "Os mesmos dados de antes. `labels` são os cinco setores em ordem alfabética, o que fixa a ordem dos centroides."
    },
    {
      "code": "C = np.array([Xtr[ytr == label].mean(axis=0) for label in labels])\nprint(\"length before:\", np.linalg.norm(C, axis=1).round(3))\nC /= np.linalg.norm(C, axis=1, keepdims=True)",
      "note": "Uma média por setor, sobre os seus 20 vetores de treino. Imprime os comprimentos e depois divide cada um pelo próprio comprimento."
    },
    {
      "code": "pred = np.array(labels)[(Xte @ C.T).argmax(axis=1)]\nprint((pred == yte).sum(), \"of\", len(yte), \"right\")",
      "note": "Compara cada ticket de teste com os cinco centroides e fica com o setor de nota mais alta."
    },
    {
      "code": "for label, c in zip(labels, C):\n    s = Xtr @ c\n    s[ytr != label] = np.nan\n    near, far = np.nanargmax(s), np.nanargmin(s)\n    print(f\"{label:9} {s[near]:.3f} {train[near]['text']}\")\n    print(f\"{'':9} {s[far]:.3f} {train[far]['text']}\")",
      "note": "Para cada setor, compara os próprios tickets de treino com o seu centroide. Os tickets dos outros setores viram `nan`, para que `nanargmax` e `nanargmin` os ignorem."
    }
  ]
}
```

```
ana@lab:~/emb$ python centroids.py
length before: [0.542 0.554 0.526 0.592 0.542]
47 of 50 right
account   0.791 I no longer have access to the email I signed up with.
          0.251 Why do you need my date of birth?
ebooks    0.734 The e-book I bought won't open on my Kindle.
          0.322 Is there a dark mode for reading at night?
payments  0.607 My bank statement shows a charge from you I don't recognise.
          0.408 Can the school pay by bank transfer after the books arrive?
returns   0.745 I'd like to send back a book I bought last week, it's not what I expected.
          0.406 The book I received is a different translation from the one on the website.
shipping  0.693 My order was supposed to arrive on Tuesday and it's now Friday. Where is it?
          0.417 The tracking number you gave me doesn't work on the carrier's site.
```

**47 dos 50 tickets de teste vão para o setor certo**, um a mais que o vizinho mais próximo, com
cinco vetores no lugar de cem. Num teste deste tamanho um ticket vale dois pontos em cem, então a
leitura honesta é *tão bom quanto o k-NN aqui*, e não *melhor*; a seção *Medindo um classificador*
explica por quê.

## Por que a média precisa ser normalizada de novo

Todo vetor de ticket tem comprimento 1. A média deles não: os cinco centroides saíram entre 0,526 e
0,592. Vinte setas apontando mais ou menos na mesma direção somam uma seta mais curta que vinte, e
quanto mais elas discordam, mais curta ela fica. Então o comprimento de um centroide mede o quanto o
setor é variado. Pagamentos, com 0,526, é o mais variado dos cinco; devoluções, com 0,592, o mais
uniforme.

Isso é útil de saber e prejudicial de manter. Sem correção, um setor cujos tickets concordam entre
si ganharia um centroide mais longo, e um vetor mais longo vence produtos escalares pelo comprimento
e não pela direção, a armadilha que a aula 2 mede. Dividir cada centroide pelo próprio comprimento
põe os cinco de volta na esfera, e o produto escalar volta a ser um cosseno.

## Um centroide é um protótipo

A última parte do programa pergunta qual ticket de treino fica mais perto de cada centroide e qual
fica mais longe. O mais perto é a mensagem mais típica do setor: *I'd like to send back a book I
bought last week* ("queria devolver um livro que comprei semana passada") para devoluções, *My order
was supposed to arrive on Tuesday* ("meu pedido devia ter chegado na terça") para entregas. Lidos
juntos, os cinco mais próximos são uma boa descrição do que cada setor atende, escrita pelos
clientes.

Os mais distantes são onde procurar quando algo está errado. **Why do you need my date of birth?**
("por que vocês precisam da minha data de nascimento?") tem 0,251 contra o centroide de contas,
abaixo do ticket menos típico de todos os outros setores. É uma pergunta sobre dados pessoais, que a
equipe arquiva em contas, então o rótulo se defende; mas numa fila real de milhares, os tickets mais
distantes do próprio centroide são uma lista curta de candidatos para uma pessoa conferir.

## Quando um ponto por setor não basta

Um centroide supõe que o setor é uma nuvem de pontos com um meio. Pagamentos é o caso em que isso é
mais fraco: cartões recusados, notas fiscais para empresas, vales-presente e transferências
bancárias são quatro conversas diferentes, e a média delas não fica perto de nenhuma. O ticket mais
típico do setor tem 0,607, o mais baixo dos cinco, e o menos típico tem 0,408.

Quando um setor é na verdade vários grupos, a saída é dar a ele vários centroides, um por grupo, e
deixar o mais próximo deles responder pelo setor. Encontrar esses grupos sem rótulos é
agrupamento, que o curso `machine-learning` ensina; esta aula fica com as cinco médias, que já
bastam aqui.
