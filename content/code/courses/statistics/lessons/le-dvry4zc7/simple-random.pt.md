---
title: A amostra aleatória simples
version: 1
---

Uma **amostra aleatória simples** dá a todo membro da população a mesma chance de ser escolhido, e a todo
grupo de mesmo tamanho a mesma chance também. É o padrão contra o qual todo outro método é julgado.

## Como se faz

A receita prática precisa de uma lista da população, chamada **base de amostragem**:

1. Numere todo membro da lista.
2. Sorteie a quantidade necessária de números distintos.
3. Os membros com esses números são a amostra.

Na planilha: ponha `=ALEATÓRIO()` ao lado de cada linha, ordene por essa coluna e pegue as *n* primeiras
linhas. Toda ordenação é igualmente provável, então todo conjunto de *n* linhas também é.

A palavra "aleatória" aqui é técnica. Não significa desordenada ou arbitrária; significa que um
**mecanismo de acaso** decidiu, não uma pessoa. Alguém escolhendo clientes "com cara de aleatórios" numa
lista vai, sem querer, escolher os nomes que chamam a atenção, os que estão perto do topo, os que
reconhece.

## Amostras aleatórias diferem entre si

Trate as 400 cestas como população, com média de R$ 82,78, e tire três amostras aleatórias simples de 40.
As médias saem R$ 89,32, R$ 80,03 e R$ 72,47.

Nada deu errado: **estatísticas amostrais variam**. Tire 1.000 amostras de 40 e as médias delas se
espalham de R$ 61,53 a R$ 116,79, com desvio padrão de R$ 8,69. A aula 11 mostra a forma dessa dispersão, e
a aula 12 transforma a largura dela numa margem de erro.

A propriedade importante está no centro: nas 1.000 amostras, as médias dão em média R$ 82,96, muito perto
dos R$ 82,78 da população. Uma amostra aleatória simples é **não viesada**: ela não pende para nenhum lado.
Amostras individuais erram, por quantias que dá para calcular, mas erram para os dois lados por igual.

## Com e sem reposição

Uma amostra pode ser tirada **sem reposição**, para que ninguém seja escolhido duas vezes, ou **com
reposição**, devolvendo cada membro escolhido antes do próximo sorteio. Pesquisas reais sorteiam sem
reposição: ninguém quer entrevistar a mesma casa duas vezes. A maioria das fórmulas deste curso supõe
reposição, porque isso torna os sorteios independentes. Quando a amostra é uma fração pequena da
população, menos de uns 5%, a diferença é desprezível, e isso cobre quase todo caso prático.

## Do que ela precisa

A receita tem um ingrediente exigente: **a lista**. Uma amostra aleatória simples dos clientes da Horta
precisa da lista de clientes. Uma amostra aleatória simples de todas as casas de Campinas precisa de uma
lista de todas as casas de Campinas, que não existe num lugar só. Quando a lista deixa gente de fora, a
amostra não tem como incluí-la, por mais aleatório que seja o sorteio. A seção sobre viés volta a isso.
