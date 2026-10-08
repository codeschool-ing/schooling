---
title: O que testar, e quando roda
version: 1
---

Dez testes é uma bateria pequena, e ela já cobre as coisas com mais chance de dar errado neste
pipeline. Uma regra prática para quais testes escrever sai do que cada um achou:

- **Um teste de unidade para cada decisão que recebe uma entrada de fora**: cada regra do validador,
  cada regra de um modelo de staging sobre datas, dinheiro e status. É por aí que chegam entradas que
  ninguém viu ainda, e um teste de unidade é o único que consegue experimentá-las antes que cheguem.
- **Um teste de integração para cada caminho da fonte ao relatório**, rodado sobre um recorte real,
  com respostas calculadas de forma independente. Poucos, porque cada um é lento e cobre muito.
- **Um teste para cada propriedade que o pipeline promete**: idempotência, totais que batem, um mart
  que concorda com a sua tabela fato. São baratos de enunciar e pegam famílias inteiras de bug.
- **Um teste para cada bug, depois que ele é achado**, para que continue corrigido: o preço com ponto
  decimal está na bateria agora, e vai estar depois que a próxima pessoa mexer no validador.

O que não testar importa tanto quanto. Um teste que repete o código — que confere que `quantity *
price` é igual a `quantity * price` — passa faça o código o que fizer. Um teste contra os dados de
produção de hoje muda a resposta toda noite e ensina as pessoas a ignorá-lo.

E os testes rodam **antes** da mudança, não depois. Os testes de dados da lição 12 rodam no build
noturno, porque os dados mudam toda noite. Estes testes rodam quando o código muda, na máquina de quem
está mudando e de novo antes de a mudança entrar — que é onde a lição 18 começa.
