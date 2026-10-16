---
title: O mesmo nome de coluna, significando duas coisas
version: 1
---

Duas tabelas da Lantern têm uma coluna chamada `channel`, com os mesmos quatro valores:

```
lantern=# SELECT channel, count(*) AS customers FROM customers GROUP BY 1 ORDER BY 1;
 channel  | customers 
----------+-----------
 email    |       361
 referral |       493
 search   |       951
 social   |       845
(4 rows)

lantern=# SELECT channel, count(*) AS sessions FROM web_sessions GROUP BY 1 ORDER BY 1;
 channel  | sessions 
----------+----------
 email    |     9278
 referral |    10183
 search   |    18887
 social   |    21652
(4 rows)
```

Não são a mesma dimensão. Em `customers`, `channel` é como o cliente **chegou pela primeira
vez**, gravado uma vez no cadastro e nunca mudado: os 845 clientes com valor `social` chegaram à
loja pelas redes sociais na primeira vez. Em `web_sessions`, `channel` é de onde **esta visita**
veio, e a mesma pessoa pode chegar pela busca na segunda e por um e-mail na sexta.

Um painel que põe "pedidos por canal" ao lado de "visitas por canal" convida o leitor a dividir um
pelo outro e calcular uma conversão por canal. O resultado não significa nada: o numerador está
agrupado por onde os clientes chegaram pela primeira vez e o denominador por onde as visitas
vieram, e nada liga os dois. **Uma dimensão é definida pelo que ela descreve e por quando foi
gravada, não pelo nome da coluna.** O marketing chama a primeira de *canal de aquisição* e a
segunda de *origem da sessão*, e essa é exatamente a distinção que uma definição compartilhada
precisa fazer antes de alguém construir um gráfico em cima.

A regra geral tem nome na modelagem de dados: uma **dimensão conformada** é uma que significa a
mesma coisa em toda tabela que a carrega, de modo que duas medidas agrupadas por ela possam ser
postas lado a lado. `state` seria conformada se duas tabelas a carregassem com o mesmo
significado. `channel`, aqui, não é, e a correção é o nome: duas colunas, dois nomes.
