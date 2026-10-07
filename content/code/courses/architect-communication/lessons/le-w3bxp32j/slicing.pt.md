---
title: Trocar escopo fatiando
version: 1
---

**A alavanca mais barata é quase sempre o escopo, e a habilidade está em cortar a funcionalidade de
modo que a primeira fatia seja útil sozinha.** Uma fatia que é "a parte do banco de dados" ou "o
back-end, sem as telas" não entrega nada na data. Uma fatia que deixa um tipo de cliente fazer uma
coisa de ponta a ponta entrega algo real, e o resto vem depois.

## As fatias

O time e Renata passaram uma hora num quadro branco com a funcionalidade quebrada em partes, cada
uma marcada conforme a Boa Praça precisasse dela ou não em 1º de dezembro:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas fileiras de blocos em escala de semanas. A fileira de dezembro: máquina de estados, 3 semanas; pedido antecipado até 7 dias, 3 semanas; a tela dos separadores, 1 semana; e uma semana de folga, dentro das 8 semanas disponíveis. A fileira de janeiro, tracejada: 30 dias de antecedência, meia semana; pedidos recorrentes, 2 semanas; editar depois de confirmar, 1 semana.\"><defs><marker id=\"slices-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"236\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"28\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">máquina de estados</text><rect x=\"260\" y=\"60\" width=\"236\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"268\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pedido antecipado, 7 dias</text><rect x=\"500\" y=\"60\" width=\"76\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"508\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tela dos</text><text x=\"508\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">separadores</text><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">1º de dezembro: 7 de 8 semanas</text><rect x=\"580\" y=\"60\" width=\"76\" height=\"46\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"586\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">folga</text><path d=\"M660 30 L660 52\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M660 114 L660 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"656\" y=\"22\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">8 semanas disponíveis</text><text x=\"20\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">janeiro: 3,5 semanas</text><rect x=\"20\" y=\"170\" width=\"156\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"28\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">30 dias</text><rect x=\"180\" y=\"170\" width=\"156\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"188\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pedidos recorrentes</text><rect x=\"340\" y=\"170\" width=\"156\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"348\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">editar depois de confirmar</text><text x=\"20\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma semana de desenho = uma semana de trabalho; a qualidade está dentro de cada bloco, não num bloco à parte</text></svg>", "caption": "A funcionalidade, fatiada. A fileira de cima é útil sozinha em 1º de dezembro; a de baixo tem data, não foi abandonada."}
```

| parte | semanas | precisa estar pronta em 1º de dezembro? |
|---|---|---|
| desembaraçar a máquina de estados do pedido | 3 | sim, todo o resto depende dela |
| pedido antecipado, até 7 dias, num horário escolhido | 3 | sim, é a funcionalidade |
| mostrar os pedidos agendados aos separadores da loja | 1 | sim, ou as lojas não conseguem prepará-los |
| pedido antecipado até 30 dias | 0,5 | não |
| pedidos recorrentes ("toda quinta") | 2 | não |
| editar um pedido depois da confirmação | 1 | não; cancelar e pedir de novo resolve por enquanto |

As três primeiras linhas somam **sete semanas**: dentro das oito disponíveis, com uma semana de
folga para o teste de carga e o que ele encontrar. As outras três linhas, três semanas e meia, vão
para janeiro.

## Regras para uma fatia

- **Ela funciona de ponta a ponta**, para algum cliente, sozinha. Pedido antecipado sem que a loja
  consiga ver o pedido não é uma fatia; é um bug com data de lançamento.
- **É a menor coisa que atende ao interesse encontrado antes**, não a menor coisa que dá para
  construir.
- **O que fica de fora é registrado e ganha data**, para que seja um plano e não um abandono.
  "Pedidos recorrentes, janeiro, duas semanas" é um compromisso; "depois" é uma esperança.
- **Qualidade não se fatia.** As sete semanas incluem testes, o teste de carga e um plano de
  rollback. Uma fatia é menos funcionalidade, nunca menos cuidado.

## Por que costuma funcionar

A maioria das funcionalidades segue o padrão que Lívia encontrou aqui: **a maior parte do valor está
numa minoria das partes, e a maior parte do custo está no resto.** Pedidos recorrentes eram duas
semanas de trabalho para um uso que, na opinião de Renata, talvez um cliente em vinte quisesse antes
da Páscoa. Quebrar a funcionalidade e pôr preço em cada parte (a aula 8 fez o mesmo com as ofertas
relâmpago) é o que torna isso visível, e basta ficar visível para que quem é dono do escopo faça o
corte por conta própria.
