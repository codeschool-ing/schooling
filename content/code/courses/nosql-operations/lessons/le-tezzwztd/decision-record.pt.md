---
title: Escreva a escolha
version: 1
---

Uma escolha de banco dura mais que as pessoas que a fizeram. Três anos depois alguém pergunta por que
a loja roda Redis ao lado do Postgres, e **a resposta é uma página que alguém escreveu na época, ou
um palpite**. Um registro de decisão é essa página: curto, datado, escrito antes de a escolha ser
posta em prática, e guardado junto do código. A aula 20 de `architecture` e a aula 17 de
`tech-strategy` ensinam o formato em geral; esta seção lhe dá as perguntas que este curso vem
fazendo.

## O modelo

Copie para um arquivo ao lado do código e preencha uma linha por operação que importa, não por
tabela. As três primeiras colunas são a tabela por operação da aula 1; o resto é o que as aulas
seguintes acrescentaram:

| pergunta | de onde veio |
|---|---|
| a operação, nas palavras do negócio | aula 1 |
| o que acontece se duas cópias discordarem por um instante | aula 1 |
| o que acontece se a operação for recusada | aula 1 |
| então: consistência ou disponibilidade, e quanta latência ela aguenta pagar | aulas 1 e 5 |
| o padrão de acesso: por chave, por intervalo, agregado inteiro, ad hoc | aula 3 e esta aula |
| o volume hoje, e o volume que mudaria a resposta | aula 16 |
| a família, depois o produto, a versão e a licença | aulas 2 e 21 |
| auto-hospedado ou gerenciado, e por quem | aula 21 |
| como é feito o backup, e quando a restauração foi testada pela última vez | aulas 11 e 13 |
| os sinais que acionam alguém | aula 20 |
| quanto custaria sair | aula 21 |

Abaixo da tabela, quatro parágrafos curtos: **a decisão**, **as alternativas consideradas** e por que
perderam, **as consequências** que você aceita, e **o que faria você revê-la**, como um número ou um
evento, e não uma sensação.

## O da loja, preenchido

| operação | discordar por um instante | recusada | então | padrão | decisão |
|---|---|---|---|---|---|
| tirar do estoque o último monitor | vendido duas vezes | erro, tentar de novo | consistência | várias linhas numa transação | Postgres |
| cobrar o cartão de um pedido | cobrado duas vezes | o pedido espera | consistência | uma transação junto com o pedido | Postgres |
| guardar o pedido com seus itens | um pedido perdido | erro, tentar de novo | consistência | agregado inteiro, ligado a estoque e pagamentos | Postgres, itens como linhas; uma coluna `jsonb` para as opções de presente |
| contar uma visualização de página | algumas visualizações atrás | uma visualização perdida | disponibilidade, e latência baixa | uma chave quente, milhares de incrementos | Redis, ao lado do Postgres |
| manter uma sessão logada | deslogado uma vez | deslogado | disponibilidade | por chave, com expiração | Redis, ao lado do Postgres |

**Decisão.** O Postgres guarda pedidos, estoque, pagamentos e clientes. O Redis guarda contadores de
página e sessões, dados que a loja pode perder ao custo de um login e de uma lacuna num gráfico. O
estoque mostrado nas páginas de produto é copiado para o Redis por um outbox, nunca por uma escrita
dupla.

**Alternativas consideradas.** MongoDB para os pedidos: o pedido é um agregado, mas é alterado na
mesma transação que o estoque e o pagamento, e os relatórios da loja o ligam a tudo. Cassandra: o
volume de escrita é de milhares por dia, não milhares por segundo, e as perguntas ainda estão
mudando.

**Consequências aceitas.** Dois bancos para fazer backup, testar e observar; duas habilidades de
plantão; uma tabela de outbox e um relay para operar.

**Rever quando** as escritas passarem do maior primário que dá para comprar, a loja abrir uma segunda
região que precise aceitar pedidos enquanto isolada da primeira, ou o Redis deixar de ser mais barato
que a tabela `UNLOGGED` das seções anteriores. Não antes.

Essa última linha é a resposta honesta que o curso vinha construindo: **para a maior parte da loja,
ela deve continuar relacional**, e o resto do que este curso ensinou é como reconhecer o dia em que
não deve, e como operar bem o outro banco quando esse dia chegar.
