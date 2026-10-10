---
title: Sorted sets, um ranking que o servidor mantém
version: 1
---

A loja quer uma caixa de mais vendidos: os três produtos que mais venderam no mês. A resposta
relacional é um `GROUP BY` sobre os itens de pedido do mês, executado a cada visualização de página ou
guardado em cache e executado de novo mais tarde. **Um sorted set mantém o ranking atualizado a cada
venda**: cada membro é um membro de set com um número ao lado, o score, e o Redis mantém os membros
ordenados pelo score o tempo todo.

## Um ranking, uma venda de cada vez

Cada venda soma a quantidade vendida ao score do produto com `ZINCRBY`. O mês está na chave, então o
ranking de outubro é uma chave própria e novembro começa do zero:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> ZINCRBY bestsellers:2026-10 2 KB-101
"2"
127.0.0.1:6379> ZINCRBY bestsellers:2026-10 5 CB-012
"5"
127.0.0.1:6379> ZINCRBY bestsellers:2026-10 1 MN-330
"1"
127.0.0.1:6379> ZINCRBY bestsellers:2026-10 3 MS-204
"3"
127.0.0.1:6379> ZINCRBY bestsellers:2026-10 3 KB-101
"5"
```

O `ZINCRBY` cria o membro na primeira vez e soma a ele depois: o teclado vendeu 2 e depois 3, e o seu
score é 5. Não há tabela a percorrer nem consulta a executar; o ranking já existe quando a página
pede por ele:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> ZREVRANGE bestsellers:2026-10 0 2 WITHSCORES
1) "KB-101"
2) "5"
3) "CB-012"
4) "5"
5) "MS-204"
6) "3"
127.0.0.1:6379> ZREVRANK bestsellers:2026-10 MS-204
(integer) 2
127.0.0.1:6379> ZRANGE bestsellers:2026-10 3 +inf BYSCORE WITHSCORES
1) "MS-204"
2) "3"
3) "CB-012"
4) "5"
5) "KB-101"
6) "5"
```

`ZREVRANGE … 0 2 WITHSCORES` leu os três primeiros, do maior score para o menor. Três detalhes dessa
resposta merecem ser conhecidos antes que uma página dependa deles:

- **Um empate é desfeito pelo nome do membro**, byte a byte. `KB-101` e `CB-012` fizeram 5 cada um, e
  em ordem inversa `K` vem antes de `C`. Se a loja quiser desempatar por outra coisa, como o produto
  que chegou primeiro ao score, isso tem de ser embutido no próprio score.
- **As posições contam a partir de zero.** O `ZREVRANK` respondeu `2` para o mouse, que a página
  mostra como terceiro.
- **Um intervalo pode ser por score além de por posição.** `ZRANGE … 3 +inf BYSCORE` devolveu todos
  os produtos que venderam pelo menos três, do menor para o maior.

Os scores voltaram entre aspas porque um score é um número de ponto flutuante, guardado como um
double de 64 bits. Números inteiros são exatos até 2⁵³, cerca de nove quatrilhões, então contar
unidades vendidas é seguro.

## A mesma forma, outras perguntas

Um sorted set é um ranking por qualquer número que a loja consiga associar a um membro, e alguns dos
usos comuns não se parecem nada com um ranking:

| pergunta | membro | score |
| --- | --- | --- |
| mais vendidos do mês | código do produto | unidades vendidas, somadas com `ZINCRBY` |
| "vistos recentemente", sem as repetições para as quais a lista precisou do `LREM` | código do produto | a hora da visualização; uma segunda visualização só move o score |
| pedidos a cancelar se não forem pagos em 30 minutos | número do pedido | o prazo como tempo Unix; `ZRANGE … BYSCORE` com `-inf` e o agora acha os vencidos |
| requisições por cliente no último minuto | um id de requisição | a hora da requisição; `ZREMRANGEBYSCORE` descarta os antigos |

O custo é o mesmo em todos os casos. Um sorted set mantém duas estruturas para cada membro, uma para
achá-lo pelo nome e outra para manter a ordem. Por isso usa mais memória por membro que um set ou uma
lista, e acrescentar um membro custa O(log N) em vez de O(1). Para um ranking lido a cada página, esse
é quase sempre o lado mais barato da troca.
