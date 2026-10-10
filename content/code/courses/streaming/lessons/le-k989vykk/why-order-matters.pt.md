---
title: Os mesmos eventos, outra ordem, outra resposta
version: 1
---

**Um fold só dá a resposta certa se vir os eventos na ordem em que aconteceram.** Parece óbvio, e
ainda assim a maioria espera que o estrago de uma reordenação seja pequeno e visível: um número
errado por um, ou um erro. O experimento abaixo não dá nenhum dos dois. Dá um número errado com cara
de certo.

Suponha que a contagem do Recife, feita às 08:50, chegue ao log por último em vez de primeiro. Não é
exagero: a contagem foi digitada num tablet no estoque, e o tablet ficou sem sinal até alguém levá-lo
para a frente da loja. Monte esse log movendo a primeira linha para o fim, e faça o fold:

```
ubuntu@stream:~/work$ (tail -n +2 stock.log; head -1 stock.log) > late.log
ubuntu@stream:~/work$ python balance.py late.log
olinda  bk-03    3
recife  bk-03    4
```

`tail -n +2` é toda linha a partir da segunda, e `head -1` é a primeira; os parênteses rodam os dois
e mandam tudo para um arquivo só. Os oito eventos de `late.log` são os mesmos oito, byte a byte, e a
resposta para o Recife é 4 em vez de 6. **Nada falhou e nada avisou.** 4 é um estoque plausível, e é
exatamente o que a contagem disse às 08:50, e esse é o problema: é o estado da prateleira às 08:50,
aplicado no fim da manhã, apagando uma entrega e três vendas.

O trace mostra como se chegou lá:

```
ubuntu@stream:~/work$ python balance.py late.log --trace
 0  olinda  bk-03    2
 1  recife  bk-03   -1
 2  olinda  bk-03    0
 3  recife  bk-03    5
 4  recife  bk-03    3
 5  olinda  bk-03    3
 6  recife  bk-03    2
 7  recife  bk-03    4
olinda  bk-03    3
recife  bk-03    4
```

A segunda linha diz que o Recife tinha **−1** exemplar, coisa que nenhuma prateleira já teve. Um
sistema que reagisse ao estado conforme ele muda teria reagido a isso: um alerta de estoque, um
pedido ao fornecedor, um site marcando o livro como indisponível. Então uma reordenação corrompe a
resposta do fim e toda resposta no caminho até lá, e a segunda é pior, porque outros sistemas já
agiram com base nela.

## Quais eventos se importam com a ordem

Nem todo par se importa. Uma entrega de 6 e uma venda de 2 dão o mesmo total em qualquer ordem,
porque somar e subtrair **comutam**: 4 + 6 − 2 e 4 − 2 + 6 dão 8. Uma contagem não comuta com nada,
porque ela substitui o número em vez de movê-lo.

| aplicado primeiro | depois | resultado | ao contrário |
|---|---|---|---|
| recebeu 6 | vendeu 2 | +4 | +4, o mesmo |
| contou 4 | vendeu 1 | 3 | 4, a venda se perde |
| contou 4 | recebeu 6 | 10 | 4, a entrega se perde |

Dá vontade de concluir que eventos deveriam ser desenhados para comutar, e onde isso sai barato é um
bom instinto: um total de vendas por loja é uma soma, e uma soma não liga para ordem. Mas uma
contagem de estoque é uma coisa real que acontece numa loja real, e ela quer dizer *a prateleira tem
4 agora*. Transformá-la numa soma exigiria que quem conta soubesse o estoque antes de contar, que é
justamente o número que a contagem existe para corrigir. **Alguns fatos são sobre valores absolutos,
e esses precisam de ordem.**

O −1 do meio mostra que nem eventos que comutam estão totalmente a salvo. O total sai certo no fim,
mas um leitor que olha no meio vê um estado que nunca existiu. Um processador de stream está sempre
no meio; ele nunca vê o fim. As lições 9 a 11 voltam a isso pelo outro lado, com eventos que chegam
horas atrasados e resultados que precisam ser corrigidos depois que alguém já os leu.

Então a ordem importa. A próxima seção pergunta quanto dela: se todo evento do log precisa estar em
ordem com todos os outros, ou se algo bem mais fraco basta.
