---
title: O que dizem o p-valor e o intervalo
version: 1
---

## O p-valor

A aula 14 de `statistics` o define, e vale repetir a definição porque quase todo mundo a lê ao
contrário. **O p-valor é a probabilidade de ver uma diferença pelo menos deste tamanho se as duas
páginas de fato convertessem na mesma taxa.** Para o teste da Panela, 0,032: se o checkout novo não
fizesse diferença nenhuma, uma distância de 0,40 ponto ou mais apareceria em cerca de três testes em
cem.

O que ele não é:

- **não é a probabilidade de a página nova não ser melhor.** Isso precisaria de uma crença prévia
  sobre com que frequência checkouts novos funcionam, que o teste não tem;
- **não é o tamanho do efeito.** Um efeito minúsculo num teste enorme tem p-valor minúsculo; um efeito
  grande num teste pequeno pode ter um p-valor grande;
- **não é uma medida de importância.** A aula 22 de `statistics` é exatamente sobre essa distância.

Abaixo de 0,05, o plano da aula 7 chama o resultado de significativo. É uma regra de decisão, útil
porque foi fixada antes. Não é uma descrição de quão seguro alguém deveria estar.

## O intervalo

**O intervalo de confiança de 95% da diferença é a faixa de efeitos verdadeiros com que o dado é
compatível.** O da Panela vai de +0,03 a +0,76 ponto. Ele diz três coisas que o p-valor não diz:

- **o zero está fora dele**, que é o mesmo achado de p abaixo de 0,05, visto do outro lado;
- **o efeito pode ser bem pequeno**: 0,03 ponto é uma alta que ninguém pagaria para construir;
- **o efeito pode ser maior que o mínimo do plano**: 0,6 ponto está dentro da faixa.

Então o resumo honesto das três semanas não é "o checkout novo vence" mas **"o checkout novo
provavelmente é melhor, por algo entre quase nada e três quartos de ponto"**. O intervalo carrega a
incerteza que a palavra "significativo" joga fora, e é ele que deveria estar no slide.
