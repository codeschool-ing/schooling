---
title: Para que serve o particionamento, e para que não serve
version: 1
---

A crença a substituir primeiro: **particionar deixa uma tabela grande rápida.** Parece certo: uma
consulta sobre um mês deveria ser mais rápida numa tabela que guarda um mês do que numa que guarda
três. É o motivo pelo qual a maioria das pessoas recorre a ele. E está errado vezes suficientes para
custar um projeto. Uma tabela particionada são várias tabelas atrás de um nome só, e isso compra
duas coisas: **descartar ou mover uma fatia inteira sai barato**, e **uma consulta que diz qual
fatia quer pode pular as outras**. Todo o resto custa alguma coisa, e algumas consultas ficam mais
lentas.

## O que ele faz melhor: livrar-se de linhas antigas

`events` guarda noventa dias de cliques. Uma de verdade guardaria mais a cada dia, e os dias mais
antigos teriam de sair: a política de privacidade diz por quanto tempo um clique pode ser guardado,
ou o disco diz por você. Numa tabela que é uma tabela só, remover um mês é um `DELETE`. Experimente
dentro de uma transação, para poder desfazer, e meça quanto WAL ele grava — o registro que o
servidor faz de cada mudança, que `db-administration` cobre e que toda réplica e todo backup têm de
receber:

```
market=# BEGIN;
BEGIN
Time: 0.501 ms

market=*# SELECT pg_current_wal_lsn() AS before \gset
Time: 0.716 ms

market=*# DELETE FROM events WHERE at < '2025-11-01';
DELETE 1611210
Time: 2968.929 ms (00:02.969)

market=*# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before')) AS wal_written;
 wal_written 
-------------
 251 MB
(1 row)

Time: 1.116 ms

market=*# ROLLBACK;
ROLLBACK
Time: 0.734 ms
```

**1611210 linhas, três segundos, 251 MB de WAL**, e o `ROLLBACK` devolveu todas. Se tivesse havido
commit, os três segundos e os 251 MB seriam só o começo. Cada linha apagada é uma versão morta que o
`VACUUM` tem de visitar e remover, o assunto da aula 15. Os índices continuam apontando para cada uma
delas até ele passar. E o arquivo da tabela não encolhe: o espaço é reaproveitado por linhas futuras,
não devolvido. Numa tabela que cresce todo dia, esse `DELETE` roda todo dia.

Numa tabela particionada por mês, outubro é uma tabela própria, e removê-lo é remover uma tabela. A
seção 05 desta aula faz isso e mede contra estes números.

## O outro trabalho: não ler o que a pergunta não precisa

Quando o `WHERE` de uma consulta diz qual fatia quer, o planejador pode deixar as outras partições
fora do plano. Isso é a **poda de partições** (partition pruning), e é o assunto inteiro da aula 18,
inclusive as consultas que não conseguem podar. Aqui basta saber que é o segundo motivo, e que só
ajuda uma consulta cuja condição está na coluna pela qual a tabela é particionada.

## O que ele custa

Uma tabela particionada não tem armazenamento próprio. Cada linha mora em exatamente uma partição,
escolhida pela **chave de partição**, e toda consulta é planejada contra as partições que pode tocar.
Daí vêm três custos, e esta aula encontra cada um:

- **Uma consulta que não menciona a chave lê todas as partições.** Buscar um evento pelo `id` é uma
  sondagem de índice em `events`; numa tabela cortada por mês é uma sondagem por mês, porque nada no
  `id` diz a que mês ele pertence. A seção 03 mede isso.
- **A unicidade só funciona através da chave.** Uma chave primária numa tabela particionada tem de
  incluir a chave de partição, então um `id` que é único sozinho não pode mais ser declarado assim. A
  seção 06 mostra o erro.
- **Mais partições, mais planejamento.** O planejador descobre de quais partições uma consulta
  precisa antes de rodá-la, e esse trabalho cresce com a quantidade. A aula 18 mede quatro contra
  trezentas e sessenta e cinco.

## Quando vale a pena

O particionamento paga os seus custos quando uma tabela tem **uma fatia natural que é também o jeito
como ela envelhece**: eventos, logs, leituras, pedidos por mês — linhas que chegam em ordem de tempo
e saem em ordem de tempo, e sobre as quais a maioria das perguntas é sobre uma janela recente.
Raramente paga numa tabela como `customers`, cujas linhas não envelhecem e cujas perguntas são sobre
um cliente por vez; um índice responde melhor a essas.

O tamanho que se costuma citar, "particione acima de tantos gigabytes", é um substituto da mesma
pergunta. A versão útil é concreta: **qual é o `DELETE` que você roda toda noite, e quanto tempo ele
leva?** Se a resposta for "nenhum" ou "alguns segundos", particionar é um custo sem o benefício para o
qual existe. Se for "uma hora, e ele briga com todo o resto", a próxima seção é como a tabela deveria
ter sido construída.
