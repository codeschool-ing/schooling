---
title: O meio-termo
version: 1
---

**O teste caixa cinza testa por fora com algum conhecimento de dentro.** Quem testa não lê cada linha do
código, como na aula 7, mas também não finge não saber nada, como na aula 6. Sabe como o sistema é
montado: que partes ele tem, onde guarda seus dados, o que escreve nos logs, como uma parte chama a outra.
Usa esse conhecimento para escolher testes e, sobretudo, para **conferir resultados em lugares que o
usuário nunca vê**.

É a abordagem que a maioria de quem testa de fato usa, a maior parte do tempo. Quem nunca abriu o código
ainda sabe que a loja tem um banco de dados, ainda sabe que o preço vem de um módulo e o pedido de outro, e
ainda olha o banco depois de fazer um pedido. Isso é caixa cinza, chame-se assim ou não.

## O que conta como conhecimento parcial

O conhecimento que a caixa cinza usa é o tipo que se acha num desenho no quadro, não no código-fonte:

- **a arquitetura**: que programas, serviços ou módulos existem, e quem chama quem;
- **os dados**: que tabelas existem, o que cada coluna quer dizer, que valores ela aceita;
- **as interfaces entre as partes**: o que uma parte manda para a outra, em que formato;
- **os efeitos colaterais**: o que um sistema escreve além da resposta, como uma linha de log, um arquivo
  ou um e-mail.

Nada disso exige saber programar. Um modelo de dados, uma tabela do que cada coluna quer dizer, ou dez
minutos com um desenvolvedor desenhando caixas dão a quem testa a maior parte do que a caixa cinza precisa.

## Por que o meio

Cada uma das outras duas abordagens tem um ponto cego que a do meio cobre em parte.

**A caixa preta só vê a resposta.** Se o programa imprime a coisa certa e grava a coisa errada em outro
lugar em silêncio, quem testa como caixa preta fica satisfeito. Quem testa como caixa cinza confere o banco
também, e vê a coisa errada.

**A caixa branca vê o código, mas não o sistema.** Ler o `orders.py` linha por linha diz o que cada linha
faz. Não diz que o relatório da noite conta assentos somando uma coluna da tabela `orders`, que é o fato que
transforma uma linha de aparência inofensiva num defeito.

A caixa cinza combina as duas do jeito mais barato: **agir como cliente, conferir como quem conhece o
sistema.** As duas próximas seções fazem exatamente isso com o programa que faz pedidos.

## O que ela não é

Caixa cinza não é licença para testar a implementação em vez do comportamento. Um teste que confere se o
banco tem exatamente uma linha com exatamente estas colunas vai quebrar quando um desenvolvedor renomear uma
coluna, mesmo que a loja funcione perfeitamente. As conferências que valem a pena por dentro são as que
importam a alguém de fora: um assento vendido que não foi pago, um total que não bate com o recibo, um
registro que o relatório da noite vai ler. **Olhe por dentro para ver consequências, não para fixar
detalhes.**
