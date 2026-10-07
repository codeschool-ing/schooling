---
title: Testes unilaterais e bilaterais
version: 1
---

A hipótese alternativa pode apontar para uma direção ou para as duas.

Um teste **unilateral** tem uma alternativa como μ < 40: só conta uma diferença numa direção. A pergunta do
sistema de rotas da Horta é unilateral, porque a afirmação é que as entregas ficaram **mais rápidas**;
entregas mais lentas não apoiariam o fornecedor.

Um teste **bilateral** tem uma alternativa como μ ≠ 1000: conta uma diferença em qualquer direção. A
envasadora é bilateral, porque uma máquina que enche demais desperdiça arroz e uma que enche de menos
descumpre a lei, e as duas significam que ela está fora do alvo.

## Por que a escolha importa

O nível de significância, quase sempre 5%, é a fração de resultados que vai contar como evidência contra a
nula. Um teste unilateral põe os 5% inteiros numa cauda. Um bilateral os divide, 2,5% em cada cauda, então o
limite de cada cauda fica mais longe.

Para as 25 entregas da Horta, com 24 graus de liberdade, os limites são:

| teste | rejeitar a nula quando a estatística estiver |
|---|---|
| unilateral, μ < 40 | abaixo de −1,71 |
| bilateral, μ ≠ 40 | abaixo de −2,06 ou acima de 2,06 |

Um teste unilateral é mais fácil de passar na direção para onde olha, e cego na outra.

## Escolha antes dos dados

A direção precisa ser decidida **antes** de ver os dados, a partir da pergunta que se faz. Escolhê-la
depois — olhar a amostra, ver que ela caiu e então rodar um teste unilateral para "caiu" — corta o limite
pela metade a seu favor sem justificativa nenhuma, e transforma um teste de 5% num teste de 10% na prática.

Na dúvida, use o **bilateral**. É o padrão na maioria dos softwares e relatórios, e é a escolha honesta
sempre que uma diferença na direção inesperada também valeria a pena saber. Um sistema de rotas novo que
deixasse as entregas mais lentas é algo que a Horta gostaria muito de ouvir, e isso é um argumento para
testá-lo também de forma bilateral. Esta aula mantém a versão unilateral, porque essa é a afirmação que o
fornecedor fez, e aponta onde as duas diferem.
