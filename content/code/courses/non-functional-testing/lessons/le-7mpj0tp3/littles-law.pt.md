---
title: A lei de Little
version: 1
---

Uma relação liga os três números de que todo teste de carga fala: quantas requisições estão no
sistema ao mesmo tempo, com que rapidez elas chegam e quanto tempo cada uma fica. Ela foi provada
por John Little em 1961. Ela não precisa de nenhuma suposição sobre a forma das chegadas nem sobre a
ordem de atendimento, e vale para qualquer sistema que esteja estável no período medido:

> **L = λ × W**: o número médio lá dentro é igual à taxa de chegada vezes o tempo médio que cada um
> passa lá dentro.

Em teste de carga ela costuma ser escrita com a vazão, `X`, no lugar da taxa de chegada, o que dá no
mesmo para um sistema que acompanha: o que entra por segundo sai por segundo. **As médias são médias
aritméticas, e aqui a média é a estatística certa**: a lei é uma identidade sobre totais, e os
avisos da aula 8 sobre médias não se aplicam a ela.

## Conferindo na bilheteria

O `users.py` mede os dois lados separadamente. Ele conta as requisições em voo diretamente, dez
vezes por segundo, e calcula `X × R` a partir da vazão e do tempo médio de resposta. Aqui estão as
duas linhas de cada uma das rodadas de "Usuários virtuais, tempo de pensamento e rampa":

| rodada | em voo, contadas | X × R |
|---|---|---|
| 10 usuários, pensamento de 0,5 s | 0,2 | 0,3 |
| 100 usuários, sem pensamento | 99,9 | 98,7 |
| 240 usuários, pensamento de 4 s | 0,9 | 1,1 |

Elas concordam dentro do arredondamento de uma rodada curta numa máquina compartilhada, e a linha do
meio concorda perto de cem. Nada no `users.py` força essa concordância: a contagem e o produto são
calculados a partir de dados diferentes.

## A lei aplicada ao laço inteiro

Trace a fronteira mais larga, em volta do laço inteiro de um usuário virtual, e o tempo lá dentro
passa a ser o tempo de resposta mais o tempo de pensamento. Todo mundo está sempre em algum ponto do
laço, então o número lá dentro é o número de usuários:

> **N = X × (R + Z)**: os usuários são iguais à vazão vezes o tempo de resposta mais o tempo de
> pensamento.

É a linha `X × (R + think)` da saída, e ela deu 10,0, 98,7 e 240,5 em rodadas de 10, 100 e 240
usuários. Onde fica um pouco abaixo, a diferença é tempo que um usuário passou sem esperar nem
pensar: dentro do próprio gerador, entre uma requisição e a seguinte.

**Rearranjada, ela transforma uma taxa num número de usuários**, que é a conta de que todo teste
fechado precisa:

- Para oferecer 50 requisições por segundo, a taxa do requisito da aula 1, com um tempo de
  pensamento de 2 s e respostas de uns 20 ms, você precisa de cerca de 50 × 2,02 = 101 usuários
  virtuais.
- Cinquenta usuários que pensam 1,9 s contra um servidor que responde em 100 ms vão enviar no máximo
  50 / 2,0 = 25 requisições por segundo, por mais potente que seja o gerador.
- Se o servidor passar de 20 ms para 2 s, os mesmos 101 usuários caem de 50 requisições por segundo
  para 101 / 4,0, uns 25: o modelo fechado recuando, escrito como aritmética.

A última linha é o motivo de um teste fechado dimensionado assim só estar certo enquanto o servidor
acompanha. Quando `R` cresce, a taxa que ele oferece cai, e o teste deixa de fazer a pergunta para a
qual foi dimensionado.
