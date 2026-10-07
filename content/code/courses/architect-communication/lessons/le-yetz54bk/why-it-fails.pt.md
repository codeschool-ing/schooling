---
title: Por que "é dívida técnica" perde a discussão
version: 1
---

**Uma engenheira que diz "isso é arriscado" e um diretor que ouve "essa engenheira quer reescrever
alguma coisa" estão tendo duas conversas diferentes, e quem costuma perder é a engenheira.** Não
porque o diretor enxerga pouco, mas porque nada na frase está numa forma que um diretor consiga
comparar com as outras coisas que disputam o mesmo dinheiro.

Toda semana Otávio ouve que algo é urgente. Vendas diz que um cliente vai embora sem uma
funcionalidade. Marketing diz que uma campanha precisa de uma landing page até sexta. Engenharia diz
que o banco de dados está frágil. Os dois primeiros chegam com um número junto, o contrato anual de
um cliente ou os pedidos esperados de uma campanha. O terceiro chega com um adjetivo. **Um risco
descrito só com adjetivos concorre com riscos descritos em reais, e perde na comparação, não no
mérito.**

## As palavras que perdem

| o que a engenharia diz | o que o diretor ouve |
|---|---|
| "o banco está frágil" | engenheiros gostam de tudo arrumadinho |
| "temos muita dívida técnica" | a engenharia quer um trimestre sem funcionalidades |
| "isso não escala" | hoje funciona |
| "é uma bomba-relógio" | uma metáfora, então provavelmente exagero |
| "precisamos refatorar antes que seja tarde" | um projeto sem fim e sem resultado mensurável |

Nenhuma dessas frases é falsa. **Cada uma descreve o sistema, e o diretor decide sobre o
negócio.** A escada da aula 3 se aplica direto: quem fala está no degrau de baixo, e a decisão mora
no de cima.

## Um risco descrito corretamente, tarde demais

Em 1º de agosto de 2012, a Knight Capital, então uma das maiores negociadoras de ações dos Estados
Unidos, implantou um software novo nos seus servidores de roteamento de ordens. Um técnico copiou o
código novo para sete dos oito servidores. No oitavo, uma flag reaproveitada pelo código novo ligou
uma função antiga, parada havia anos, e esse servidor começou a enviar ordens que ninguém tinha
pedido. Segundo o relato da SEC, a comissão de valores mobiliários americana, a Knight perdeu mais
de 460 milhões de dólares em cerca de 45 minutos. Em poucos meses, tinha aceitado ser comprada.

Descrito no degrau de baixo, o risco era "código morto ainda implantado, e uma implantação manual
sem verificar se todo servidor recebeu a versão". Descrito no degrau de cima, era "um erro de
implantação pode custar mais do que a empresa vale em menos de uma hora". A primeira frase é do
tipo que fica parada num backlog. A segunda é do tipo que ganha orçamento.

## O que o resto da aula faz

As seções seguintes transformam um risco técnico no segundo tipo de frase, passo a passo:

1. **probabilidade e impacto**, os dois números com que todo risco precisa ser descrito;
2. **pôr números neles**, para o problema de sexta da Marola, com a conta à mostra;
3. **opções em vez de alarmes**, para que quem decide escolha em vez de se assustar;
4. **incerteza dita com honestidade**, porque uma estimativa de risco nunca é uma medição.

A aula 11 de `process-management` trata o risco como um gerente de projeto o vê, com registros e
planos de resposta. Esta aula é sobre um passo que esse processo deixa para quem entende o sistema:
**colocar o risco técnico no registro numa unidade que o registro consiga comparar.**
