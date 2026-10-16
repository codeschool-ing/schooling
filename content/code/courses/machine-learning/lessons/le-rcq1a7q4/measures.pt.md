---
title: Justo por qual medida
version: 1
---

A tabela do `by_age.py` imprimiu três números por faixa, e cada um é uma definição diferente de justo, com
nome na literatura:

| definição | pergunta | a coluna no `by_age.py` |
|---|---|---|
| **paridade demográfica** | todo grupo recebe o benefício na mesma taxa? | `credited` |
| **igualdade de oportunidade** | os membros *que deviam receber* recebem na mesma taxa em todo grupo? | `recall` |
| **paridade preditiva** | um crédito tem a mesma chance de chegar a quem sai em todo grupo? | `precision` |

Há uma quarta que vale conhecer, a **calibração dentro dos grupos**: uma chance de 0,3 quer dizer 30% em
todo grupo, a honestidade da aula 11 verificada faixa por faixa.

Cada uma soa como a definição certa quando lida sozinha, e elas não podem valer todas ao mesmo tempo. O
motivo está na segunda coluna da tabela: **os grupos saem em taxas diferentes**, 5,2% na faixa de 25-34,
7,4% na mais jovem. Quando as taxas de base diferem, um modelo que dá a mesma parte de créditos a todo
grupo tem de alcançar uma parte menor dos jovens que saem ou desperdiçar mais créditos na faixa de 25-34.
Um modelo que alcança a mesma parte de quem sai em todo lugar tem de dar crédito aos jovens com mais
frequência. Precisão igual e recall igual não podem valer juntos com taxas de base diferentes, a não ser
para um modelo perfeito. Isso é um teorema, provado de forma independente por vários pesquisadores por
volta de 2016, e nenhum ajuste contorna.

Então **justiça é a escolha de uma definição, e a escolha não é técnica.** Para o crédito da Feira em
Casa:

- **Igualdade de oportunidade** é a que melhor serve. O crédito é para quem está prestes a sair; a
  pergunta justa é se um jovem que vai sair e um idoso que vai sair têm a mesma chance de recebê-lo.
- **Paridade demográfica** serve a decisões em que o benefício deve ir a todo grupo na proporção,
  quaisquer que sejam as taxas, um programa de bolsas, por exemplo, e serve mal a um crédito de retenção:
  significaria dar crédito a quem fica numa faixa para igualar quem sai em outra.
- **Paridade preditiva** importa mais quando uma previsão positiva é um ônus, um alerta de fraude ou uma
  checagem de segurança, e a pergunta é se ser apontado quer dizer a mesma coisa para todo mundo.

O modelo com a idade teve recalls de 0,267, 0,216, 0,234 e 0,240 nas quatro faixas grandes. Não é igual, e
se a diferença é grande o bastante para agir é um julgamento sobre um número com ruído. O bootstrap da
aula 2, rodado por faixa, diria quanto.
