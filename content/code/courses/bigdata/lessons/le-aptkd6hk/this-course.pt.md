---
title: O que é este curso, e o que uma máquina consegue mostrar
version: 1
---

**Este curso é sobre o momento em que um computador deixa de bastar, e sobre o que fazer então.** Os
dados que ele usa são o clickstream do site da Ponto Final: cada página que um visitante abriu,
cada busca, cada livro posto no carrinho e cada compra, durante todo o ano de 2025. Quem veio pela
trilha de dados já conhece a loja. Os caixas alimentam um banco PostgreSQL, um warehouse responde
aos gerentes, e um pipeline leva um ao outro toda noite. O site escreve muito mais do que os caixas
jamais escreveram, e as ferramentas que davam conta dos pedidos deixam de dar conta disto.

O curso roda em **Apache Spark**, o motor que a maioria das empresas usa quando os dados passam do
tamanho de uma máquina, comandado a partir do Python. Ele passa também pelo que sustenta o Spark,
porque só afina um job quem sabe no que ele se transformou: o cluster e o seu agendador (aula 2),
um sistema de arquivos espalhado por muitos discos (aula 3) e o MapReduce, o modelo que o Spark
substituiu (aula 4). Depois vem o próprio Spark, da API ao plano que ele monta a partir do seu
código (aulas 5 e 6), o que acontece quando um job roda em muitos workers ao mesmo tempo (aulas 7
a 9) e como os arquivos por baixo são organizados (aulas 10 e 11). As três últimas aulas tratam
dos sistemas em volta e da conta.

## O que uma máquina consegue mostrar, e o que não consegue

Fique claro desde o começo o que neste laboratório é encenado. **O assunto inteiro de um cluster é
o que acontece quando o trabalho se espalha por várias máquinas**, e o seu laboratório é uma
máquina fingindo ser quatro. Isso é menos grave do que parece, e vale saber exatamente onde o
fingimento termina.

O que é real: o master, os workers e os processos que eles iniciam são programas Java separados, e
cada um tem a sua própria memória. Quando um job passa dados de um worker para outro, os dados são
cortados em blocos, serializados, gravados em disco e lidos de volta pelo outro processo,
exatamente como num cluster de cem máquinas. Os planos que o Spark monta, os estágios em que ele
corta um job, os bytes que cada estágio move, a memória que uma tarefa despeja em disco e a nova
tentativa depois que um worker morre são todos de verdade, e as aulas os medem.

O que não é: a rede entre os workers é a memória da sua máquina, então mover um gigabyte leva uma
fração do que levaria entre dois racks. **Os dados são pequenos**: 24 milhões de eventos, um quarto
de gigabyte compactado, que um notebook processa em cerca de um minuto. Um clickstream de verdade é
milhares de vezes maior. Onde isso muda a conclusão, a aula diz e faz a conta para o tamanho que
doeria, em vez de deixar que uma execução rápida em dados pequenos ensine a lição errada.

Então o curso ensina o raciocínio com medidas que você mesmo tira, e as escala no papel onde só um
cluster de verdade faria sentir. Essa é a versão honesta do que um laboratório numa máquina só
consegue fazer.
