---
title: O que não deve ser guardado
version: 1
---

**Um cache que guarda a coisa errada é pior que nenhum cache**: ele é rápido e errado, e quem está olhando
não consegue perceber. Três casos decidem quase tudo.

## Páginas com os dados de alguém

**Uma página que mostra os dados de uma pessoa nunca deve chegar a um cache compartilhado.** Se uma CDN
guardasse a página de um aluno conectado, a próxima pessoa a pedir aquele endereço a veria, o que é um
vazamento, não um problema de desempenho. Uma página dessas vai `private`, para só o navegador daquela pessoa
poder guardá-la, ou `no-store` quando nem o navegador dela deve guardar, como numa página com dados de
pagamento. O padrão seguro para qualquer coisa que dependa de um cookie é `private, no-cache`.

As páginas do planner são as mesmas para todo mundo, então `no-cache` sem `private` é o certo para ele, e a
próxima seção deixa um cache compartilhado guardá-las por alguns segundos.

## Coisas que mudam no mesmo endereço

**Um tempo de vida longo num arquivo que pode mudar é uma promessa que o próximo deploy quebra.** O caso
clássico é um script chamado `app.js`, mandado com `max-age=31536000`: o próximo build escreve um `app.js`
novo, e todo visitante que volta continua rodando o velho por até um ano, contra uma API que já mudou. A
correção não é um tempo menor e sim um nome com hash, para a versão nova ser um endereço novo. Um tempo de
vida é seguro exatamente quando o nome muda com o conteúdo.

## Respostas que não são leituras

**Na prática só `GET` e `HEAD` vão para o cache.** O `POST /vitals` do planner nunca é guardado por ninguém,
e um `GET` que muda algo, como um link que apaga, é um bug por muitos motivos, um deles que um cache pode
respondê-lo sem o servidor nem ficar sabendo.

## E um cabeçalho na frente de tudo isso

O `Vary` de novo: uma resposta que depende de um cabeçalho de requisição e não diz isso vai ser entregue a
alguém cuja requisição era diferente. A compressão é o caso comum e o planner a nomeia; uma página que muda
por língua, escolhida pelo `Accept-Language`, precisa nomeá-lo também, senão uma língua é servida a todo
mundo.
