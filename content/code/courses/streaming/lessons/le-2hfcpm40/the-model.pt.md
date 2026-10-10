---
title: Uma tabela que nunca para de crescer
version: 1
---

Os programas das lições 9 a 11 faziam tudo à mão: liam os eventos um a um, guardavam um dicionário
de janelas abertas, moviam um watermark e decidiam quando uma janela estava terminada. **O Spark
Structured Streaming deixa você escrever a mesma contagem como uma consulta comum sobre uma tabela,
e assume o resto**: ler o tópico, guardar as janelas abertas, lembrar onde parou e recomeçar dali
depois de uma queda.

A imagem errada mais comum é que o Spark trata cada venda no instante em que ela chega, como o seu
próprio consumidor fazia. **Por padrão, não é assim.** Ele espera, junta o que chegou desde a última
vez e processa essa fatia como um pequeno job batch. Depois faz tudo de novo. Cada fatia é um
**micro-batch**, e o intervalo entre elas, de algumas centenas de milissegundos a minutos, é a
latência que você paga por tudo o mais que o Spark oferece.

## A tabela sem fim

O modelo do Spark é uma tabela à qual se acrescentam linhas e da qual nada é removido. Cada venda
que chega ao tópico é mais uma linha no fim dela. Você escreve uma consulta sobre essa tabela como
se ela estivesse completa, com `select`, `where`, `groupBy` e o resto, e o Spark nunca a roda sobre
a tabela inteira. **Ele roda a consulta de forma incremental**: cada micro-batch lê só as linhas
novas e as combina com o que guardou dos batches anteriores.

O que ele guarda se chama **estado**. Uma consulta que só escolhe colunas e filtra linhas não
precisa de estado: entra uma linha, sai uma linha. Uma consulta que conta vendas por janela de
cinco minutos precisa da contagem parcial de toda janela que ainda pode receber uma venda, e esse
estado cresce até que alguma coisa diga que a janela terminou. Essa coisa é o watermark da lição 11,
que o Spark implementa por você e que a seção 05 desta lição põe para trabalhar.

@@fig:l12-micro-batch@@

## Três perguntas que toda consulta responde

Uma consulta de streaming no Spark é uma consulta mais três decisões, e cada uma tem a sua seção
aqui:

| decisão | a pergunta | onde |
|---|---|---|
| **modo de saída** | depois de um batch, quais linhas do resultado saem: as novas, as alteradas ou todas | seção 05 |
| **checkpoint** | onde o Spark anota o que leu e o que terminou, para um reinício saber de onde partir | seção 06 |
| **trigger** | quando começa o próximo batch: num relógio, o quanto antes, uma vez sobre o que existe, ou continuamente | seção 07 |

A quarta peça é o **sink**, o lugar para onde vão os resultados: o console na maior parte desta
lição, e depois o Kafka e arquivos na seção 08. Se um sink aguenta receber o mesmo batch duas vezes
sem estrago é o que decide se a consulta inteira é exactly-once, a palavra da lição 7 chegando a um
motor de verdade.

## Duas APIs de streaming no Spark, e qual é esta

O Spark já teve duas APIs de streaming. A primeira, o **Spark Streaming**, com os objetos `DStream`,
trabalhava com batches de objetos Java e não sabia nada de tempo do evento. Ela foi marcada como
obsoleta no Spark 3.4 e este curso não a usa. O **Structured Streaming**, a segunda, é construído
sobre DataFrames e SQL, então as mesmas funções que servem para uma tabela com as vendas do ano
passado servem para o stream. Uma busca por ajuda encontra as duas, e o jeito de distinguir é a
palavra `readStream`: a API nova tem, a antiga não.

O Spark não é o único motor que faz esse trabalho. A lição 13 mostra o Flink, que trata um registro
de cada vez em vez de fatias, e o Kafka Streams, que é uma biblioteca dentro do seu próprio programa
em vez de um motor ao lado dele. Esta lição fica com o Spark, porque o micro-batch é o mais fácil
dos três de observar: cada batch é impresso, numerado, e pode ser lido como uma tabela.
