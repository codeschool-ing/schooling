---
title: O espelho, aplicado à bilheteria
version: 1
---

**Os quatro níveis de teste valem a pena conhecer seja qual for o processo do time**, porque descrevem o
que está sendo conferido, não quando. Aplicados ao Cine Aurora, cada nível tem um assunto diferente, uma
base diferente e, em geral, uma pessoa diferente rodando.

## Um teste em cada nível

| nível | o assunto | um exemplo | sua base | em geral rodado por |
|---|---|---|---|---|
| **unidade** | um pedaço, sozinho | `price(60, False, "thu", "20:00")` deveria dar 1800 | o projeto do módulo: `price` devolve centavos | quem o escreveu |
| **integração** | dois pedaços juntos | um pedido de um adulto e uma criança numa noite de quinta guarda um total igual à soma dos dois preços | a arquitetura: o `orders.py` pede cada preço ao `tickets.py` | desenvolvedores, ou quem testa com conhecimento de caixa cinza |
| **sistema** | a loja inteira | um cliente escolhe uma sessão no site, marca três assentos, paga e recebe um recibo de R$ 90,00 | a especificação do sistema | quem testa |
| **aceitação** | a loja como a Célia e os clientes precisam | num domingo de manhã, uma família compra para a sessão das 9:30 pelo mesmo preço que a bilheteria cobra | as necessidades dos usuários | a dona do produto, usuários, ou quem testa em nome deles |

Repare onde os defeitos deste curso teriam sido achados. A pessoa de sessenta anos no nível de unidade, se
alguém tivesse escolhido sessenta. Os pedidos recusados guardados no nível de integração, onde o pedido e o
banco se encontram. A sessão das 9:30 só no nível de aceitação, porque só ali um horário de sessão real
digitado por uma pessoa real chega à regra de preço. **Cada nível pega defeitos que os níveis abaixo não
enxergam**, e é por isso que pular um nunca sai de graça.

## A matriz de rastreabilidade

Um projeto no modelo V mantém uma tabela que liga cada requisito aos testes que o conferem, e cada teste ao
requisito de onde vem. Ela se chama **matriz de rastreabilidade**, e em trabalho regulado costuma ser o
primeiro documento que um auditor pede. Um trecho para a regra de preço:

| requisito | testes de unidade | testes de sistema | testes de aceitação |
|---|---|---|---|
| R1: noite R$ 36,00 a partir das 17:00, matinê R$ 28,00 antes | 16:59 e 17:00 | uma sessão às 16:30 e uma às 19:00 compradas no site | a sessão das 9:30 de domingo |
| R2: estudantes, maiores de 60 e menores de 12 pagam meia | 11, 12, 59, 60, 61; um estudante | uma família com uma criança no site | um aposentado compra online |
| R3: quarta-feira meia | um adulto na quarta | uma compra numa quarta | — |
| R4: de um a seis ingressos por pedido | — | 0, 1, 6 e 7 ingressos | — |
| R5: meia é o maior desconto de qualquer ingresso | um estudante na quarta | uma família numa quarta | — |

Leia nos dois sentidos. **Ao longo de uma linha**, ela mostra quão bem um requisito está coberto: o R4 não tem
teste de unidade nem de aceitação, o que pode estar bem ou ser uma lacuna. **Descendo uma coluna**, todo
teste tem um motivo: um teste que não leva a requisito nenhum está testando algo que ninguém pediu ou um
requisito que ninguém escreveu, e os dois merecem uma pergunta.

A matriz também mostra o que a aula 6 achou de fora: o R5 não existia até a pergunta da Lia criá-lo. Uma
matriz montada a partir das quatro primeiras frases pareceria completa e não teria nada a dizer sobre
estudantes às quartas.

## Além do V

Os níveis e a matriz sobrevivem ao modelo em que foram desenhados. Um time ágil ainda tem testes de unidade,
integração, sistema e aceitação; roda todos toda semana em vez de uma vez por ano. O curso `testing-cicd`
trata os quatro níveis a fundo como aparecem num pipeline, e a aula 13 de `manual-testing` dá uma visão geral
de teste de unidade e de integração do lado de quem testa. O que cabe aqui é o espelho em si: **para cada
descrição do sistema, pergunte que teste vai conferir o sistema contra ela, e quem vai rodar esse teste.**
