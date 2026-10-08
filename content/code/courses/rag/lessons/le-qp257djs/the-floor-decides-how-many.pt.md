---
title: O piso decide quantas
version: 2
---

Olhe de novo a última coluna da varredura:

```
ana@vm:~/rag$ python sweep.py
  k  found  tokens  alike  above floor
  1  20/26      60      0          1.0
  2  26/26     116      3          1.8
  3  26/26     171      3          2.6
  5  26/26     279      7          3.4
  8  26/26     441     12          4.1
 12  26/26     660     16          4.7
```

Pedindo doze fontes, **em média 4,7 passam do piso da aula 6**; pedindo três, 2,6. O piso, escolhido
na aula 6 para decidir quando recusar, vinha decidindo o tamanho do contexto o tempo todo: uma pergunta
com um bom casamento recebe uma fonte, e uma pergunta cuja resposta está espalhada por quatro seções
recebe quatro.

É uma regra melhor que um `k` fixo, pelo motivo que a varredura mostra. Um `k` fixo manda o mesmo
número de fontes para uma pergunta que precisa de uma e para uma que precisa de cinco, então é demais
para a primeira e de menos para a segunda. Um piso manda o que é parecido o bastante para valer a
leitura, e um teto no `k` só protege o orçamento da pergunta rara que casa com uma dúzia de pedaços.

Então o pipeline desta aula pede dez à busca e deixa o piso escolher, como faz o `candidates` do
`context.py`. Dez é um teto, nunca uma meta; uma pergunta da próxima seção, sobre reembolso de
audiolivros, chega a ele, com as dez acima do piso. O piso continua com a fraqueza que a aula 6 mediu,
de algumas respostas certas ficarem abaixo dele e algumas erradas acima, e as próximas seções o
mantêm em vez de substituí-lo.
