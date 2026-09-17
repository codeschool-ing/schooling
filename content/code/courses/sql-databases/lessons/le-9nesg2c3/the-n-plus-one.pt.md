---
title: N+1, o erro que parece código comum
version: 1
---

Aqui está uma página que lista cinquenta clientes com seus pedidos, escrita do jeito que todo
tutorial escreve:

```
customers = Customer.order('id').limit(50)
for customer in customers:
    for order in customer.orders:
        print(customer.name, order.total)
```

Quatro linhas, e nada nelas parece um problema de banco. A primeira linha roda uma consulta.
`customer.orders` na terceira linha roda uma consulta **por cliente**, porque os pedidos não foram
carregados junto com os clientes — o ORM os busca na primeira vez em que são pedidos, que é dentro
do laço. Cinquenta clientes, cinquenta consultas, mais a que buscou os clientes: **N+1**.

A seção anterior capturou isso do lado do servidor:

```
shop=# SELECT calls, left(query, 60) AS query FROM pg_stat_statements WHERE query LIKE 'SELECT id,%' ORDER BY calls DESC;
 calls |                            query                             
-------+--------------------------------------------------------------
    50 | SELECT id, placed_at, total FROM orders WHERE customer_id = 
     1 | SELECT id, name FROM customers ORDER BY id LIMIT $1
(2 rows)
```

Uma instrução rodou cinquenta vezes. A aula 7 encontrou essa forma como subconsulta correlacionada
e disse que as duas são o mesmo erro em altitudes diferentes. Esta é a mais alta, e é pior, porque
cada uma dessas cinquenta é uma ida e volta pela rede em vez de uma busca dentro do banco.

## Por que é invisível

Três razões, e cada uma é uma razão de a revisão de código não pegar.

**Cada consulta é rápida.** Cinquenta buscas por índice a uma fração de milissegundo cada parecem
bem no `pg_stat_statements` ordenado pela média, e no log são cinquenta linhas sem nada de
especial. O custo é a contagem, e a aula 10 disse qual coluna mostra a contagem.

**Ele escala com o dado, não com o código.** Cinquenta clientes na máquina de quem desenvolve são
cinquenta e uma consultas e uma página que aparece num instante. Cinco mil em produção são cinco
mil e uma, e as mesmas quatro linhas levam segundos. Nada mudou além de N.

**É o ORM fazendo o que disse que faria.** Carregamento preguiçoso — buscar uma relação quando ela
é tocada pela primeira vez — é o padrão em quase todo mapeador porque é o comportamento certo para
o caso comum de não tocar em nada. O laço é o caso incomum, e o padrão não sabe que está dentro de
um.

## Onde ele se esconde

O laço literal acima é a forma de livro, e é a que as pessoas aprendem a ver. As outras são a
mesma coisa vestida de template ou de serializador:

- **Um template** que escreve `{{ order.customer.name }}` em cada linha de uma lista de pedidos. O
  laço está no motor de templates, e a consulta por linha está no acesso à propriedade.
- **Um serializador** que transforma uma lista de objetos em JSON, e cada objeto tem uma relação
  que o serializador percorre.
- **Um método no modelo** — `customer.total_spent()` — que roda uma consulta, chamado uma vez por
  linha de um relatório.
- **Relações aninhadas**: clientes, cada um com pedidos, cada um com linhas. N+1 dentro de N+1,
  que é N + N·M + 1, e o produto é o que faz uma página estourar o tempo.

Nenhum destes tem um `for` no código que o revisor lê, e é por isso que a contagem no
`pg_stat_statements` os acha e a leitura acha menos.

## A correção tem uma de duas formas

Pedir os pedidos **junto** com os clientes, numa instrução só, ou numa instrução por nível em vez
de por linha. As duas formas vêm embutidas em todo ORM sob um nome próprio, e a próxima seção é as
duas formas, o SQL delas, e quando cada uma é a certa.

O que a correção nunca é: desnormalizar, cachear, ou um servidor maior. A aula 2 disse isso do
outro lado: o N+1 é a causa mais comum de "o banco está lento" e nenhuma dessas coisas o toca. E
a aula 10 disse por que um servidor maior não ajuda um problema cujo custo é ida e volta.
