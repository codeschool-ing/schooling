---
title: Decidir o que conta como certo
version: 1
---

Uma resposta e uma saída esperada precisam ser comparadas de algum jeito, e a escolha da comparação
muda a nota mais do que as pessoas imaginam. Não é um detalhe do harness. É **uma decisão sobre o que
o seu programa consegue aceitar**, e ela deve ser anotada junto com os casos.

## Estrito e tolerante

Para a tarefa de classificação, o `lab/evalkit.py` julga cada resposta duas vezes:

- **estrito** (*strict*): a resposta é exatamente o rótulo, caractere por caractere;
- **tolerante** (*loose*): a resposta bate depois de tirar espaços nas pontas, passar para
  minúsculas e remover um ponto final.

Quatro respostas a um caso cujo rótulo é `refund`:

```
ana@desk:~/desk$ python -c "from lab.evalkit import score_triage as s; c = {'label': 'refund'}; print(s('refund', c), s('Refund', c), s('refund.', c), s('order-status', c))"
(True, True) (False, True) (False, True) (False, False)
```

Cada par é (estrito, tolerante). `refund` passa nos dois. `Refund` e `refund.` falham no estrito e
passam no tolerante: o modelo escolheu certo e escreveu de um jeito desarrumado. `order-status` falha
nos dois: o modelo escolheu errado.

**Os dois números importam, por motivos diferentes.** O tolerante mede se o modelo entendeu a tarefa.
O estrito mede se o programa consegue usar a resposta como ela vem. Uma distância entre eles é um
problema com conserto. Um conserto é uma etapa de arrumação no programa, que então *é* a regra
tolerante, então escreva uma vez e use nos dois lugares. O outro é uma instrução ou um recurso de
saída estruturada (a coluna `S` da aula 4) que faça o modelo escrever exatamente o rótulo.

## Na extração: interpreta ou não

A tarefa de extração pede JSON. O `score_extract` trata como estrito **a resposta inteira ser JSON
válido e o pedido estar certo**, e como tolerante **algum `{...}` dentro da resposta ser JSON válido
e o pedido estar certo**:

```
ana@desk:~/desk$ python -c "from lab.evalkit import score_extract as s; c = {'order': 'LB-20452'}; print(s('{\"order\": \"LB-20452\"}', c), s('Here is the JSON: {\"order\": \"LB-20452\"}', c))"
(True, True) (False, True)
```

A segunda resposta tem o número de pedido certo dentro de uma frase. Uma pessoa diria que está certa.
Um programa que chama `json.loads` nela quebra. Qual dos dois números decide depende do programa, e o
programa da ana chama `json.loads`.

## Com o que não pontuar

**Com outro modelo**, nestas duas tarefas. Um modelo perguntado "este rótulo está certo?" é mais
lento, custa dinheiro e pode errar de jeitos que se correlacionam com o modelo avaliado. Quando a
resposta pode ser conferida por um programa, um programa confere. Julgar com um modelo se justifica
para saídas abertas como os rascunhos da ana, em que não há uma resposta certa única, e mesmo ali os
veredictos dele são conferidos contra os de uma pessoa numa amostra antes de alguém confiar neles.
Esse é o assunto do `prompt-reliability`; esta aula fica no que um programa consegue decidir.
