---
title: Nomeando os pontos fracos primeiro
version: 1
---

Todo projeto tem fraquezas, e quem entrevista vai achar algumas. A única escolha que você tem é se ela acha ou
se você conta, e contar é quase sempre melhor.

As do loanbook são conhecidas e estão escritas: um erro inesperado fecha a conexão em vez de responder; não há
estado de carregamento; qualquer pessoa que abra a página pode emprestar; o SQLite o limita a um servidor. Cada
uma está no README, aula 16, ou na retrospectiva, aula 21, e cada uma tem uma frase pronta.

Nomear uma fraqueza primeiro faz três coisas. **Mostra que você viu**, que é o *você explica* da aula 1 inteiro.
**Define os termos**: você a descreve com precisão, com o custo e a correção, em vez de responder a uma versão
mais afiada dela feita por outra pessoa. E **libera o resto da conversa**: quem entrevista e ouviu você listar
as falhas para de procurá-las e começa a perguntar o que você faria em seguida.

Dois cuidados. **Nomeie as reais, não as lisonjeiras.** *A minha fraqueza é que me importo demais com testes* é
uma não resposta conhecida, e é lida como tal. E **nomeie com a correção**, não como confissão: *a página não tem
estado de carregamento; num celular lento mostraria uma tabela vazia por um instante, e uma linha Carregando é a
correção* é uma fraqueza e um plano num fôlego só.
