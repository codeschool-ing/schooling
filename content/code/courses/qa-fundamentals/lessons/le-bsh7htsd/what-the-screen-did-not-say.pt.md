---
title: O que a tela não disse
version: 1
---

**A quarta frase da regra diz que um pedido tem de um a seis ingressos.** De fora, a Lia testou isso do
jeito caixa preta, nas duas bordas: sete ingressos, um a mais, e nenhum ingresso, um a menos.

```
lia@lab:~/aurora$ python orders.py sat 15:00 35 35 35 35 35 35 35
refused: an order holds 1 to 6 tickets
lia@lab:~/aurora$ python orders.py sat 15:00
refused: an order holds 1 to 6 tickets
```

Os dois recusados, com uma mensagem clara. Pela tela, a regra vale. Quem testa como caixa preta marcaria os
dois casos como aprovados e seguiria em frente.

## Olhando por dentro

```
lia@lab:~/aurora$ python -m sqlite3 aurora.db "SELECT * FROM orders"
(1, 'thu 20:00', 3, 9000)
(2, 'sat 15:00', 2, 5600)
(3, 'sat 15:00', 7, 0)
(4, 'sat 15:00', 0, 0)
```

**Duas linhas a mais do que há pedidos.** O pedido 3 é o pedido recusado de sete ingressos, e o pedido 4 é
o recusado vazio, os dois guardados com total zero. A tela disse *recusado*; o banco diz que existe um
pedido de sete ingressos.

Agora leia o `place` do `orders.py` de novo, sabendo o que procurar. A primeira coisa que ele faz é gravar a
linha. Só depois disso confere o número de ingressos, e quando a conferência falha ele devolve a mensagem
sem apagar o que gravou. Como todo comando é salvo na hora, a linha fica.

## Por que isso importa a alguém de fora

Uma linha com total zero parece inofensiva. Se é ou não depende de quem lê a tabela, e isso é conhecimento
de arquitetura, não de código. No Cine Aurora, o relatório da noite que diz à Célia quantos assentos sobram
em cada sessão soma a coluna `tickets`:

```
lia@lab:~/aurora$ python -m sqlite3 aurora.db "SELECT session, sum(tickets) FROM orders GROUP BY session"
('sat 15:00', 9)
('thu 20:00', 3)
```

**A matinê de sábado mostra nove assentos vendidos.** Foram vendidos dois. Os outros sete pertencem a um
pedido que foi recusado. Num dia cheio a loja pararia de oferecer assentos que estão livres, e num dia vazio
a Célia escalaria gente para uma multidão que nunca comprou nada. A pergunta da aula 2 sobre o que impede
uma sala de ser vendida além da capacidade tem aqui uma imagem espelhada: algo que faz uma sala parecer mais
cheia do que está.

## O que o achou

Não foi a caixa preta: a tela estava certa as duas vezes. Nem a caixa branca sozinha: ler o `place` mostra a
ordem dos dois passos, mas não que um relatório em algum lugar soma a coluna. **O que o achou foi agir como
cliente e depois conferir onde as consequências caem**, o que exigiu exatamente dois fatos sobre a
arquitetura: que os pedidos ficam guardados numa tabela, e que um relatório a lê.

O relato de defeito que a Lia escreveu tinha o formato de caixa cinza, e vale copiá-lo:

> Pedidos recusados ficam guardados. `python orders.py sat 15:00` seguido de sete idades imprime
> *refused*, e `SELECT * FROM orders` depois mostra um pedido de 7 ingressos com total 0. O relatório de
> assentos os conta: a matinê de sábado mostra 9 assentos vendidos onde foram 2. Esperado: um pedido recusado
> não deixa linha.

Três comandos, um resultado esperado, e a consequência para uma pessoa que lê o relatório. Esse é o caso
inteiro.
