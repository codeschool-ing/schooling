---
title: Perceber, e ajustar uma tabela
version: 1
---

O autovacuum trabalha em silêncio, e no PostgreSQL 16 também relata em silêncio. Três lugares
dizem o que ele fez, e **o primeiro é uma consulta que vale guardar**:

@@1@@

Uma tabela perto do topo com um `n_dead_tup` grande e um `last_autovacuum` antigo ou vazio é uma
que o autovacuum não alcançou ou não consegue limpar. As seções anteriores dão os dois motivos de
costume: a linha dela é alta demais para o tamanho que tem, ou alguma coisa segura o horizonte.
`orders_copy` também tem um `last_vacuum`, do `VACUUM` digitado à mão na seção sobre a transação
aberta; as colunas `auto` são as que dizem se o servidor está dando conta sozinho.

**O segundo é o log**, e por padrão ele quase não diz nada:

@@2@@

Só entra no log um autovacuum que leve dez minutos ou mais. Isso pega a execução que importa numa
tabela grande e nenhuma das que mostrariam o ritmo dela. A lição 19 configura o log do servidor
inteiro. Aqui o parâmetro vai numa tabela só, junto com a correção que a seção sobre o gatilho
prometeu para tabelas grandes: uma fração de 1% em vez de 20%.

@@3@@

`reloptions` é onde moram os parâmetros por tabela, e `\d+ orders_copy` também os mostra, em
`Options:`. A linha desta tabela agora é 50 mais 1% de um milhão, 10.050 versões mortas, então
20.000 passa dela. Na rodada seguinte do lançador:

@@4@@

Cada linha é uma que você viu no `VACUUM VERBOSE`, escrita pelo worker no log do servidor com um
horário. **`20000 removed` e `0 are dead but not yet removable` é o formato saudável.** `index scan
bypassed` é uma economia que chegou na versão 14: quando menos de 2% das páginas da tabela têm
entradas mortas, o worker deixa os índices para uma passada futura em vez de ler todos eles por tão
pouco.

O terceiro lugar é o `pg_stat_progress_vacuum`, que tem uma linha para cada VACUUM rodando naquele
momento, com a fase em que está e quantas páginas já leu. É a view para abrir quando alguma coisa
está no vacuum há uma hora e você quer saber se falta pouco.

**Parâmetros por tabela são como o autovacuum é ajustado na prática.** Os padrões do servidor
servem para a maioria das tabelas; as poucas grandes e movimentadas ganham fração ou limiar
próprios. Nunca responda a um problema com `autovacuum_enabled = false` numa tabela. Isso acaba com
as visitas comuns e deixa só a agressiva, a da seção sobre wraparound, que chega mais tarde e
maior.

## Devolvendo o shop

A cópia e as duas extensões eram para esta lição. Remova-as, e o `shop` fica como a lição 4 o
deixou:

@@5@@
