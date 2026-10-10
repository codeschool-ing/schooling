---
title: Dois tipos de memória
version: 1
---

A ideia que a maioria das pessoas traz de outros programas é um número só: dê 2 GB ao programa e
ele usa 2 GB. **O PostgreSQL tem dois tipos de memória, e só um deles tem tamanho fixo.** Um é
compartilhado por todos os processos e alocado uma vez, quando o servidor sobe. O outro é tomado
por cada processo para uma operação de cada vez, um sort, um hash ou a criação de um índice, e
devolvido quando a operação termina. O primeiro é fácil de dimensionar. O segundo é o que deixa
uma máquina sem memória, porque o total dele depende do que todo mundo está fazendo ao mesmo
tempo.

## A máquina de onde vieram os números

A conta de memória depende da máquina, então comece pela máquina em que estas transcrições foram
gravadas:

```
ana@db:~$ nproc
4
ana@db:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       1.8Gi       1.3Gi       477Mi        13Gi        13Gi
Swap:             0B          0B          0B
```

**4 processadores e 15 GB de memória.** A máquina virtual que a lição 3 recomenda tem 2
processadores e 4 GB, então o `free -h` na sua imprime números menores, e sempre que uma resposta
desta lição depender do tamanho da máquina, ela é calculada para as duas. `buff/cache` é o cache
de páginas do sistema operacional, ao qual esta lição volta: memória que guarda arquivos lidos há
pouco e é cedida no momento em que um programa pede, e é por isso que `available` é bem maior que
`free`.

## Os parâmetros, separados por tipo

```
ana@db:~$ psql shop
shop=# SELECT name, setting, unit, context
shop-#   FROM pg_settings
shop-#  WHERE name IN ('shared_buffers', 'shared_memory_size', 'work_mem',
shop(#                 'hash_mem_multiplier', 'maintenance_work_mem',
shop(#                 'autovacuum_work_mem', 'temp_buffers', 'effective_cache_size')
shop-#  ORDER BY name;
         name         | setting | unit |  context   
----------------------+---------+------+------------
 autovacuum_work_mem  | -1      | kB   | sighup
 effective_cache_size | 524288  | 8kB  | user
 hash_mem_multiplier  | 2       |      | user
 maintenance_work_mem | 65536   | kB   | user
 shared_buffers       | 16384   | 8kB  | postmaster
 shared_memory_size   | 143     | MB   | internal
 temp_buffers         | 1024    | 8kB  | user
 work_mem             | 4096    | kB   | user
(8 rows)

shop=# \q
```

A coluna `context`, da lição 5, já os separa.

**Compartilhado, dimensionado na partida.** O `shared_buffers` é um parâmetro `postmaster`: 16384
páginas de 8 kB, 128 MB, alocados quando o servidor sobe e mantidos até ele parar. O
`shared_memory_size` é `internal`, um valor que o servidor calcula e não um que você define: o
segmento compartilhado inteiro, 143 MB, dos quais os buffers são a maior parte e o resto são
tabelas de lock, os buffers do log de escrita antecipada e outros controles.

**Privado, por operação.** O `work_mem`, 4 MB, é o máximo que um sort ou um hash pode usar antes
de passar a escrever em arquivos temporários. O `hash_mem_multiplier` deixa um hash usar o dobro.
O `maintenance_work_mem`, 64 MB, é a mesma ideia para o trabalho de manutenção: criar um índice,
fazer vacuum. O `autovacuum_work_mem` em `-1` quer dizer que os workers do autovacuum também usam
o `maintenance_work_mem`. O `temp_buffers`, 8 MB, é o cache de uma sessão para as próprias tabelas
temporárias. Todos são `user` ou `sighup`, mudáveis sem restart, porque nenhum é alocado antes que
uma operação peça.

**Nenhum dos dois.** O `effective_cache_size`, 4 GB, não aloca nada. Ele diz ao planner quanto do
banco ele pode supor que está em cache em algum lugar, e a última seção desta lição mostra o
pouco que o servidor confere isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"A memória de uma máquina desenhada como uma caixa. No alto, a memória compartilhada que o servidor aloca uma vez na partida, quase toda shared_buffers, uma cópia das páginas de tabelas e índices usada por todos os processos. Abaixo, quatro processos com memória privada: a conexão 1 com um sort de até work_mem, a conexão 2 com um hash de até o dobro de work_mem e um sort de até work_mem, a conexão 3 ociosa, sem nada, e um worker do autovacuum usando maintenance_work_mem. Embaixo, o cache de páginas do sistema operacional ocupa o que sobra, e abaixo da máquina fica o disco.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"330\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a memória da máquina</text><text x=\"30\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">memória compartilhada, alocada uma vez na partida</text><rect x=\"30\" y=\"66\" width=\"660\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"46\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">shared_buffers</text><text x=\"46\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">páginas de tabelas e índices, uma cópia para todos os processos</text><text x=\"30\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">memória privada, tomada por operação e devolvida quando ela termina</text><rect x=\"30\" y=\"152\" width=\"150\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conexão 1</text><rect x=\"38\" y=\"180\" width=\"134\" height=\"30\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"46\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sort</text><text x=\"46\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">work_mem</text><rect x=\"205\" y=\"152\" width=\"150\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"215\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conexão 2</text><rect x=\"213\" y=\"180\" width=\"134\" height=\"30\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"221\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">hash</text><text x=\"221\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">work_mem × 2</text><rect x=\"213\" y=\"216\" width=\"134\" height=\"30\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"221\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sort</text><text x=\"221\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">work_mem</text><rect x=\"375\" y=\"152\" width=\"150\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"385\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conexão 3</text><text x=\"385\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ociosa</text><rect x=\"545\" y=\"152\" width=\"150\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"555\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">worker do autovacuum</text><rect x=\"553\" y=\"180\" width=\"134\" height=\"30\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"561\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vacuum</text><text x=\"561\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">maintenance_work_mem</text><rect x=\"30\" y=\"272\" width=\"660\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"298\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o cache de páginas do sistema operacional: a memória que sobra, com blocos de arquivo lidos há pouco</text><rect x=\"300\" y=\"356\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"372\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">disco</text><line x1=\"360\" y1=\"324\" x2=\"360\" y2=\"354\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line></svg>", "caption": "Dois tipos de memória. A caixa de cima é dimensionada uma vez, por um restart, e compartilhada; as caixas dentro de cada processo aparecem para uma operação e contam por operação, então o total muda com o que as conexões estão fazendo.", "same": ["sort", "hash", "vacuum"]}
```

Cada processo do desenho é uma conexão, e as próximas seções medem os dois tipos no banco `shop`:
o que o `shared_buffers` guarda e o que guardar mais muda, depois um sort e uma criação de índice
que cabem e não cabem na sua cota privada. A lição 10 trata de por que cada conexão é um processo
inteiro; aqui isso importa porque **cada uma delas pode tomar o seu próprio `work_mem`, uma vez
por operação**.
