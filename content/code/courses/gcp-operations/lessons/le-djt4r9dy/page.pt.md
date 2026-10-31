---
title: Em que acionar alguém, e o que a fatura vê primeiro
version: 1
---

**Custo é lento comparado a erros, e acionar alguém a cada movimento é a fadiga da lição 14 de novo.** Um sinal de
custo merece um acionamento só quando esperar até de manhã custaria mais que acordar alguém. Um conjunto que funciona
para um time do tamanho do da loja, com o orçamento da lição 24 e o detector diário da etapa anterior:

| sinal | limite | rota |
|---|---|---|
| pico, um serviço | acima de 5 USD por dia sobre o usual | chamado, lido no mesmo dia |
| pico, qualquer | acima de 25 USD por dia, ou um serviço que ninguém usa | acionamento |
| orçamento, previsão | acima de 100% do mês | chamado |
| orçamento, real | acima de 100% antes do dia 20 | acionamento |
| fluxo do orçamento, ritmo | três vezes o gasto diário usual | acionamento |

A maioria das linhas é chamado. Os logs de debug da etapa anterior eram 20 USD por dia: dinheiro de verdade, que vale
um chamado no dia 9 e um conserto naquela semana, e não vale a noite de ninguém.

## Os dois acionamentos que têm motivo

**Um serviço que ninguém usa aparecendo na fatura** é a marca de uma credencial roubada: máquinas numa região onde o
time nunca implanta, ou um serviço que a loja nunca ativou. O Security Command Center da lição 20 pode levantar a
mesma coisa como achado; a fatura é a segunda testemunha, e a que não pode ser desligada de dentro do projeto. O
detector da etapa anterior pode receber a lista de serviços que a loja usa e relatar qualquer outro na hora, qualquer
que seja o custo.

**Uma fatura crescendo três vezes mais rápido que o usual** é um laço, um vazamento ou um ataque, seja de que lição
for: um laço de novas tentativas chamando uma API paga, um bucket servido para a internet, a carga de trabalho de
outra pessoa. A resposta é a da lição 15, e a primeira mitigação costuma ser aquela que a lição 24 se recusou a
automatizar em produção: parar o que está gastando. Feita por uma pessoa, com o acionamento na mão, é uma decisão em
vez de um acidente.

## Ao que o curso chega

Cada lição deste curso foi sobre perceber antes de um cliente: a esteira que recusa uma imagem ruim, o alerta sobre o
orçamento de erro, o achado que nomeia um bucket público. **A fatura é o último desses sinais e o mais lento, e para
alguns incidentes o único.** Um time que a lê toda manhã, com um chamado para os movimentos pequenos e um acionamento
para os dois que importam, fica sabendo desses incidentes no mesmo dia em vez de no dia 1º.
