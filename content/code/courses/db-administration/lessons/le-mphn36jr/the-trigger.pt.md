---
title: Quando o autovacuum decide rodar
version: 1
---

Ninguém digita `VACUUM` depois de cada alteração. O **lançador do autovacuum** (autovacuum
launcher), um dos processos que a lição 3 listou sob o postmaster, acorda a cada minuto, olha os
contadores de cada tabela e inicia um worker para cada tabela que passou da sua linha. Estes são os
parâmetros que traçam a linha:

@@1@@

**Uma tabela passa pelo vacuum quando suas versões mortas ultrapassam um número fixo mais uma
fração da tabela**:

@@2@@

`reltuples` é a estimativa do planejador para as linhas da tabela, guardada em `pg_class`. Com os
padrões, 50 e 0.2, uma tabela passa pelo vacuum quando um quinto dela está morto. No máximo três
workers rodam ao mesmo tempo, e o `autovacuum_vacuum_cost_limit` de -1 quer dizer que cada um usa o
orçamento de leituras e escritas do `VACUUM` comum e depois dorme por
`autovacuum_vacuum_cost_delay`, 2 ms. É esse freio que impede o autovacuum de engolir o disco.

Existe um segundo gatilho, para tabelas que só crescem. **O limiar de inserção conta as linhas
inseridas desde o último vacuum**, 1.000 mais um quinto da tabela, para que uma tabela que ninguém
atualiza ainda tenha o mapa de visibilidade marcado e as linhas congeladas. Você já o viu disparar:

@@3@@

`last_analyze` é o `ANALYZE` no fim do `shop.sql`. O autovacuum visitou as duas tabelas menos de um
minuto depois, na rodada seguinte do lançador, embora nada tivesse sido atualizado ou apagado: um
milhão de linhas inseridas estava bem acima de 1.000 mais um quinto de um milhão.

## As contas para orders

@@4@@

**`orders` vai passar pelo vacuum depois de 200.050 versões mortas**, e pelo analyze depois de
100.050 linhas alteradas, que é a mesma fórmula com uma fração própria de 0.1 e o assunto da lição
16. A cópia tem o mesmo milhão de linhas, então os mesmos números valem para ela. Atualize 150.000
delas, o que passa da linha do analyze e fica abaixo da linha do vacuum:

@@5@@

Espere um minuto pela rodada seguinte do lançador e olhe:

@@6@@

O worker veio, analisou a tabela e deixou as 150.000 versões mortas onde estavam. Um segundo
`UPDATE` de 100.000 linhas leva a contagem a 250.000. Um minuto depois:

@@7@@

**`last_autovacuum` tem um horário, `autovacuum_count` é 1 e `n_dead_tup` voltou a 0.** Esse é o
mecanismo inteiro, e numa tabela de um milhão de linhas os padrões são razoáveis.

Numa tabela de um bilhão de linhas não são. Um quinto de um bilhão são 200 milhões de versões
mortas antes do primeiro vacuum, e quando ele vem tem 200 milhões de versões para limpar numa
passada só. **Tabelas grandes pedem uma fração menor, só delas**, definida na tabela e não no
servidor, e a última seção desta lição faz isso com a cópia.
