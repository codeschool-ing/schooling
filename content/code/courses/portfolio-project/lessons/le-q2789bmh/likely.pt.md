---
title: As perguntas que o loanbook deve esperar
version: 1
---

As perguntas sobre um projeto são previsíveis, porque vêm sempre dos mesmos lugares: as escolhas incomuns,
os limites visíveis e a parte que você disse que foi difícil. Aqui estão as do loanbook, com a resposta que
ele daria, cada uma no formato da primeira seção:

```localised
Por que sem framework?
  Duas rotas e uma página não precisavam de um, e eu queria ver a camada HTTP. O custo são
  umas quinze linhas de roteamento à mão. Com mais rotas, ou autenticação, eu usaria um.

O que acontece com mil usuários?
  Um processo e um arquivo SQLite dão conta de uma sala dos professores com folga; não medi
  além disso. Os primeiros limites seriam escritas concorrentes no SQLite e um servidor só.
  Eu passaria para um servidor de banco antes de tudo, e o índice único vai junto.

Como você acrescentaria login?
  Contas, sessões e uma verificação em toda rota, e é por isso que foi cortado. O campo de
  quem pega emprestado viraria o usuário logado, e a regra do empréstimo não mudaria.

Qual foi a parte mais difícil?
  Duas pessoas emprestando o mesmo item ao mesmo tempo. Uma verificação em Python lê
  "disponível" duas vezes, então o banco recusa, e provei que o teste falha sem o índice.

O que você faria diferente?
  Responder a erros inesperados com um 500 em vez de fechar a conexão, e acrescentar um
  estado de carregamento. Os dois estão na retrospectiva.
```

Duas coisas sobre preparar uma lista assim. **Escreva as respostas**, como aqui, e depois diga em voz alta
até saírem com as suas palavras; um parágrafo decorado soa decorado. E **confira cada resposta contra o
projeto**: *não medi além disso* está na segunda resposta porque nada foi medido. Quem entrevista e pergunta
*como você sabe?* deve receber evidência ou um *não sei* honesto, nunca um número que você inventou.
