---
title: A consulta que não cabe mais
version: 1
---

Num banco só, "os três produtos mais vendidos" é um `GROUP BY` com um `ORDER BY` e um `LIMIT 3`. Em dois
shards, cada shard só responde pelos próprios clientes, então o roteador tem de perguntar aos dois e
juntar as respostas. O jeito óbvio é mandar a cada shard a mesma consulta, `LIMIT 3` incluído, e juntar
os dois top três. O `--naive` faz exatamente isso; sem ele, cada shard manda os totais de todo produto e
o roteador os soma:

```
ana@vm:~/lab/shards$ $R top --naive
beans    961
sugar    804
flour    614
ana@vm:~/lab/shards$ $R top
flour    990
beans    961
sugar    804
```

**A resposta ingênua está errada**, e não parece errada. A farinha é a mais vendida no total, com 990
unidades; a versão ingênua a põe em terceiro, com 614. No shard 1, a farinha era a quarta, com 376
unidades, logo fora do top três daquele shard, então essas 376 unidades nunca chegaram ao roteador. Cada
shard respondeu certo a própria pergunta, e a soma de duas respostas parciais certas não era a resposta
da pergunta inteira.

Esse é o formato geral do problema. **Uma consulta que era um plano dentro de um banco vira um pequeno
programa distribuído**, escrito por você, e toda operação nele tem de ser repensada:

| num banco só | entre shards |
| --- | --- |
| `ORDER BY … LIMIT 3` | cada shard tem de mandar o bastante para ter certeza, muitas vezes tudo; a junção é sua |
| `avg(units)` | média de médias está errada a não ser que os grupos tenham o mesmo tamanho; mande somas e contagens |
| um `JOIN` pela chave de shard | continua local, se as duas tabelas forem divididas pela mesma chave |
| um `JOIN` por qualquer outra coisa | linhas de um shard encontram linhas de todos os outros, no roteador |
| `UNIQUE (email)` | cada shard só vê as próprias linhas; dois shards podem aceitar o mesmo e-mail |
| uma transação | uma mudança em dois shards são duas transações, e uma pode falhar; aula 14 |
| a página 50 de uma lista ordenada | cada shard devolve 50 páginas para o roteador achar a 50ª |

## O que se faz em vez disso

O sharding funciona quando **as perguntas têm o formato da chave**, e o resto do projeto é sobre tornar
isso verdade:

- **Escolher a chave pela consulta mais frequente**, e aceitar que as outras fiquem mais lentas. Pedidos
  por cliente deixa as páginas do cliente rápidas e a lista diária do armazém lenta, e muitas vezes isso
  está bem.
- **Guardar os dados duas vezes, com chaves diferentes.** Uma tabela pequena de id do pedido para
  cliente, dividida por id do pedido, transforma "achar o pedido 1234" em duas consultas de um shard só
  em vez de quarenta. É o que um banco chama de **índice secundário global**, e mantê-lo em dia com os
  pedidos é mais uma cópia eventualmente consistente, como a aula 9 descreveu.
- **Mandar as perguntas sobre todo mundo para outro lugar.** Os mais vendidos, o relatório do mês e a
  caixa de busca raramente precisam ser respondidos pelos shards. Uma cópia feita para leitura,
  alimentada por eventos, os responde: os modelos de leitura da aula 13, o índice de busca da aula 17, ou
  um data warehouse carregado toda noite.

Nada disso é preciso num banco só, o que é o argumento mais forte para ficar num banco só enquanto ele
for grande o bastante.
