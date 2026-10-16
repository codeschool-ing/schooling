---
title: Anote as consultas primeiro
version: 1
---

Modelar por padrão de acesso começa com uma tabela que não tem dado nenhum: **a lista de toda
pergunta que a aplicação vai fazer, antes de existir qualquer coleção, chave ou tabela.** Parece de
trás para a frente, e é o passo que decide tudo o que vem depois.

## Os padrões de acesso da loja

Um padrão de acesso é uma pergunta na forma em que a aplicação a faz: o que ela já sabe quando
pergunta, o que quer de volta, em que ordem e com que frequência. Estes são os da loja, com as taxas
que a equipe espera nos primeiros meses. **As taxas são estimativas**, que é tudo o que alguém tem
antes do lançamento, e bastam para ordenar as linhas:

| # | a pergunta | a aplicação já sabe | ela quer de volta | taxa esperada |
|---|---|---|---|---|
| 1 | mostrar a página de um produto | o código do produto | nome, preço, estoque, fotos | 2.000 por minuto |
| 2 | mostrar e mudar a cesta | quem é o cliente | os produtos nela, com quantidades | 300 por minuto |
| 3 | mostrar um pedido | o número do pedido | o pedido inteiro, com as linhas | 200 por minuto |
| 4 | "meus pedidos" | quem é o cliente | os pedidos dele, **do mais novo**, dez por vez | 50 por minuto |
| 5 | mais vendidos da semana | nada | os dez produtos com mais unidades vendidas | uma vez por minuto, por um job |
| 6 | pedidos acima de 500 para revisar fraude | nada | os pedidos acima do valor, do mais antigo | algumas vezes por dia |

## O que cada coluna decide

**"Já sabe" é a chave.** As linhas 1 a 4 partem de um valor que a aplicação tem em mãos: um código de
produto da URL, um cliente da sessão, um número de pedido de um link. Cada uma pode ser uma busca por
chave, no que os três produtos são rápidos, se os dados estiverem guardados sob essa chave.

**"Quer de volta" é a unidade.** A linha 3 quer o pedido e suas linhas juntos, o que pede guardá-los
juntos. A linha 1 quer um produto sem as avaliações, o que pede não pôr milhares de avaliações dentro
do produto.

**"Do mais novo" é uma ordem que o armazenamento pode manter.** Se as linhas estão guardadas na ordem
em que a linha 4 as lê, a consulta é "as dez primeiras", e nada é ordenado na leitura.

**A taxa é quanto pagar por ela.** Uma pergunta feita 2.000 vezes por minuto merece uma estrutura só
sua, mesmo duplicada. Uma pergunta feita algumas vezes por dia pode se dar ao luxo de ser lenta.

## As linhas sem ponto de partida

As linhas 5 e 6 não sabem nada quando começam. Num banco relacional são consultas comuns; num
armazenamento que responde por chave, **uma pergunta que parte do nada é uma varredura**, ou uma
estrutura montada de antemão para guardar a resposta. Os mais vendidos podem ser um sorted set que
toda venda incrementa, ou um resultado que um job grava uma vez por minuto. A revisão de fraude,
algumas vezes por dia, pode ser um pipeline sobre os pedidos, aula 8, ou uma consulta a uma cópia dos
dados num data warehouse feito para perguntas que ninguém listou.

## A lista é um contrato

O projeto que sai daqui responde bem estas seis perguntas e mal as outras. Uma sétima pergunta no
ano que vem é uma tabela nova, uma chave nova ou um índice novo, **mais preenchê-lo com todo registro
gravado antes de ele existir**, que é o assunto da aula 4. Esse é o preço da abordagem, e o motivo
para gastar uma tarde nesta tabela antes de escrever qualquer outra coisa: mudá-la no papel não
custa nada.

As próximas três seções levam as linhas 3, 4 e 2 para o MongoDB, o Cassandra e o Redis.
