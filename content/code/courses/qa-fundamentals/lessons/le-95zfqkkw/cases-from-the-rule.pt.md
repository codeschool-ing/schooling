---
title: Casos a partir da regra, uma frase por vez
version: 1
---

**O teste caixa preta sistemático mais simples é pegar o requisito uma frase por vez e perguntar, para
cada uma, que entrada mostraria se ela vale.** Eis a regra da Joana de novo, com cada frase numerada:

> 1. Um ingresso custa R$ 36,00 numa sessão que começa às 17:00 ou depois, e R$ 28,00 numa que começa
>    antes.
> 2. Estudantes, maiores de 60 e crianças com menos de 12 pagam meia.
> 3. Às quartas-feiras todo ingresso é meia.
> 4. Um pedido tem de um a seis ingressos.

A frase 4 é sobre pedidos, que o `tickets.py` não trata; a aula 8 apresenta o programa que trata. As
outras três viram uma tabela.

## A tabela

Para cada frase, a Lia escreveu o que esperava antes de rodar qualquer coisa. Escrever a expectativa
primeiro importa: uma expectativa escrita depois de ver a saída tende a concordar com ela.

| frase | caso | por que este | esperado |
|---|---|---|---|
| 1 | adulto, quinta, 16:59 | o último minuto da matinê | R$ 28,00 |
| 1 | adulto, quinta, 17:00 | o primeiro minuto da noite | R$ 36,00 |
| 2 | estudante de 20, quinta à noite | o desconto de estudante sozinho | R$ 18,00 |
| 2 | criança de 11, quinta à noite | a criança mais velha que ainda paga meia | R$ 18,00 |
| 2 | criança de 12, quinta à noite | a mais nova que já não paga | R$ 36,00 |
| 3 | adulto, quarta à noite | o desconto de quarta sozinho | R$ 18,00 |

Repare nos pares: 16:59 e 17:00, 11 e 12. Cada frase da regra traça uma linha, e uma linha se testa dos dois
lados, no último valor de um e no primeiro do outro. Esse é o hábito que a técnica chamada análise de
valor-limite torna sistemático, e foi assim que a aula 1 achou a pessoa de sessenta anos.

## Rodando

```
lia@lab:~/aurora$ python tickets.py 35 no thu 16:59
R$ 28,00
lia@lab:~/aurora$ python tickets.py 35 no thu 17:00
R$ 36,00
lia@lab:~/aurora$ python tickets.py 20 yes thu 20:00
R$ 18,00
lia@lab:~/aurora$ python tickets.py 11 no thu 20:00
R$ 18,00
lia@lab:~/aurora$ python tickets.py 12 no thu 20:00
R$ 36,00
lia@lab:~/aurora$ python tickets.py 35 no wed 20:00
R$ 18,00
```

Seis de seis. Toda frase da regra, testada pelas bordas, vale.

## O que seis casos aprovados dizem

Exatamente o que a aula 1 disse que quatro casos aprovados diziam: que estas seis entradas dão estas seis
saídas. Dizem que as linhas das 17:00 e dos 12 anos estão onde a regra as põe, o que vale saber; são os
lugares em que uma leitura poderia divergir, como divergiu nos sessenta.

Não dizem nada sobre as **combinações**. Todo caso da tabela exercita uma frase por vez: um estudante numa
quinta, um adulto numa quarta. Clientes reais não chegam uma frase por vez. Um estudante vai ao cinema
numa quarta, porque é quando está mais barato. A tabela não tem linha para isso, e a regra não tem frase
para isso. A próxima seção roda esse caso.
