---
title: Medindo um classificador
version: 1
---

Toda nota desta aula até aqui foi um número só: acertos em 50. Esse número esconde onde estão os
erros e, num teste deste tamanho, esconde o quão pouco separa os métodos. Esta seção abre o número,
usando o classificador treinado de duas seções atrás.

```schooling-example
{
  "language": "python",
  "file": "measure.py",
  "parts": [
    {
      "code": "from sklearn.linear_model import LogisticRegression\nfrom sklearn.metrics import classification_report, confusion_matrix\nfrom tickets import load\n\nXtr, ytr, train = load(\"train\")\nXte, yte, test = load(\"test\")\nmodel = LogisticRegression(max_iter=1000).fit(Xtr, ytr)\npred = model.predict(Xte)",
      "note": "O mesmo classificador de `trained.py`, treinado do mesmo jeito, então as previsões são as mesmas."
    },
    {
      "code": "labels = list(model.classes_)\nprint(\"          \" + \" \".join(f\"{l[:8]:>8}\" for l in labels))\nfor label, row in zip(labels, confusion_matrix(yte, pred, labels=labels)):\n    print(f\"{label:9} \" + \" \".join(f\"{n:>8}\" for n in row))",
      "note": "`confusion_matrix` conta cada par de setor real e setor previsto. O laço imprime a matriz com os nomes dos setores nas duas bordas."
    },
    {
      "code": "print(classification_report(yte, pred, digits=3))",
      "note": "`classification_report` imprime a precisão, a revocação e a combinação das duas para cada setor, com três casas decimais."
    },
    {
      "code": "for t, p in zip(test, pred):\n    if p != t[\"label\"]:\n        print(f\"{t['id']}  {t['label']} -> {p}: {t['text']}\")",
      "note": "Os tickets em que a previsão e o rótulo discordam, com os dois."
    }
  ]
}
```

```
ana@lab:~/emb$ python measure.py
           account   ebooks payments  returns shipping
account         10        0        0        0        0
ebooks           0       10        0        0        0
payments         0        0       10        0        0
returns          0        0        0        9        1
shipping         0        0        1        1        8
              precision    recall  f1-score   support

     account      1.000     1.000     1.000        10
      ebooks      1.000     1.000     1.000        10
    payments      0.909     1.000     0.952        10
     returns      0.900     0.900     0.900        10
    shipping      0.889     0.800     0.842        10

    accuracy                          0.940        50
   macro avg      0.940     0.940     0.939        50
weighted avg      0.940     0.940     0.939        50

t024  shipping -> returns: My copy came with a big dent in the spine from the box being squashed.
t027  shipping -> payments: I was charged for delivery twice on one order that came in two boxes.
t058  returns -> shipping: Is the 30-day limit from when I ordered or from when it arrived?
```

## A matriz de confusão

Cada linha é o setor a que o ticket pertence de verdade; cada coluna é o setor que o classificador
escolheu. A diagonal são os acertos, e tudo fora dela é um erro com direção. Três tickets estão fora
da diagonal aqui, e **os três envolvem entregas**: um ticket de entrega foi para pagamentos, um foi
para devoluções, e um ticket de devolução fez o caminho contrário.

Contas e e-books foram perfeitos, dez em dez cada, e isso também é útil: o problema não está
espalhado por igual, e uma equipe decidindo onde uma pessoa deve conferir começaria pelo setor de
entregas.

## Precisão e revocação

O relatório põe dois números em cada setor, e eles respondem a perguntas diferentes.

**Revocação** (*recall*) é quantos tickets de um setor o classificador encontrou. A de entregas é
0,800: oito dos seus dez tickets foram para entregas, e dois foram para outro lugar. **Precisão**
(*precision*) é quantos dos tickets mandados para um setor pertencem a ele. A de pagamentos é 0,909:
o setor recebeu onze tickets, e um deles era o ticket de entrega sobre uma cobrança de frete em
dobro.

Os dois puxam em direções opostas, e qual importa é uma decisão de negócio, não de estatística. Um
setor que devolve dinheiro quer precisão alta, para que nada chegue lá por engano; um setor que
cuida de contas invadidas quer revocação alta, para que nada escape dele. `f1-score` é os dois
combinados num número só, o que é cômodo numa tabela e esconde essa escolha.

## Leia os erros

A última parte do programa imprime os três tickets errados, e vale ler cada um como uma pessoa
leria.

- `t024`, uma lombada amassada porque a caixa foi esmagada, foi para devoluções. Um livro danificado
  é algo que o cliente bem pode querer devolver, e os tickets de devolução falam de livros que
  chegaram errados. O rótulo diz entrega porque o dano aconteceu no transporte.
- `t027`, um frete cobrado duas vezes, foi para pagamentos. A seção anterior viu o modelo quase
  dividido ao meio nele. Uma cobrança em dobro é um problema de pagamento por qualquer leitura; a
  equipe arquivou em entregas porque a cobrança era do frete.
- `t058`, se o prazo de 30 dias conta a partir do pedido ou da chegada, foi para entregas. É sobre a
  política de devolução, e quase toda palavra dele é sobre entrega.

**Dois dos três são discussões sobre o rótulo, não falhas do modelo.** Um classificador só aprende
as fronteiras que os rótulos traçam, e quando um ticket pertence honestamente a dois setores, uma
segunda pessoa separando à mão também discordaria da primeira de vez em quando. Antes de tentar
consertar um classificador, leia os erros dele: alguns são o esquema de rótulos pedindo para ser
esclarecido.

## Cinquenta tickets é um teste pequeno

Todos os métodos desta aula, medidos nos mesmos 50 tickets com o MiniLM e os 100 tickets de treino:

| método | aprende com os rótulos | um ticket novo é comparado com | acertos em 50 |
|---|---|---|---|
| vizinho mais próximo, `k=1` | não, guarda os exemplos | 100 tickets | 46 |
| vizinhos mais próximos, `k=5` | não, guarda os exemplos | 100 tickets | 45 |
| centroides | uma média por setor | 5 médias | 47 |
| regressão logística | 1.925 pesos | 5 somas ponderadas | 47 |
| zero-shot, descrições | nenhum rótulo | 5 descrições | 43 |

**Um ticket são dois pontos percentuais.** Os quatro métodos que usam rótulos ficam entre 45 e 47,
uma diferença de dois tickets. Em outros 50 tickets tirados do mesmo jeito, a ordem desses quatro
poderia mudar, e nada nesta tabela diz qual deles é o melhor na fila real da Marginalia. O que a
tabela sustenta é a diferença grande: todo método que usa rótulos vence a melhor redação zero-shot
por pelo menos dois tickets, e a pior por dez.

Então, quando a escolha importa, meça com mais dados. Junte algumas centenas de tickets rotulados e
separe uma parte; ou faça um rodízio de quais tickets ficam de fora e tire a média dos rodízios, o
que se chama validação cruzada e pertence ao curso `machine-learning`. E seja o que for medido, a
regra que esta aula manteve desde a primeira seção continua valendo: **os tickets de teste nunca são
algo com que um método aprendeu**, nem pelos dados de treino, nem por alguém ajustando o método até a
nota parecer boa.
