---
title: O desvio
version: 1
---

Dois servidores montados a partir das mesmas instruções são idênticos no dia em que são montados,
e em nenhum dia depois. O **desvio** (*drift*) é a distância entre eles, e ela cresce uma mudança
razoável de cada vez: uma noite lenta resolvida com `ALTER SYSTEM`, um arquivo editado numa máquina
com a outra deixada para amanhã, um cluster criado de novo a partir de outro shell. Cada mudança
estava certa quando alguém a fez. Nenhuma foi anotada em lugar nenhum além do servidor que ela
mudou.

A crença comum é que os arquivos de configuração são o registro, e que comparar dois servidores é
comparar os arquivos deles. **Eles são um entre vários lugares de onde vem um valor.** A lição 5
deu os nomes: o `postgresql.conf`, os arquivos em `conf.d` e o `postgresql.auto.conf`, onde o
`ALTER SYSTEM` escreve. Há mais um, que não mora em arquivo nenhum: um ajuste preso a um banco ou a
um papel, guardado no catálogo. Comparar arquivos não o enxerga.

O que todos esses lugares têm em comum é que o servidor em execução conhece o resultado. Então
pergunte ao servidor, com uma consulta guardada num arquivo:

```sql
-- settings.sql: every parameter this server was told, and what it was told
SELECT name, current_setting(name) AS value
FROM pg_settings
WHERE source NOT IN ('default', 'override', 'client')
  AND name NOT IN ('cluster_name', 'port', 'external_pid_file')
ORDER BY name;
```

O `WHERE` deixa de fora três tipos de ruído. `default` é um parâmetro que ninguém definiu.
`override` é o que o `pg_ctlcluster` passa na linha de comando — os caminhos do diretório de dados
e dos arquivos de configuração — e `client` é o que o `psql` define para a própria conexão. Os três
nomes excluídos no fim são os que **precisam** ser diferentes entre dois clusters, então uma
diferença ali não é desvio. O `current_setting(name)` imprime o valor com a unidade, `64MB` em vez
de `65536`.

## Um segundo servidor para comparar

A sua máquina tem um cluster. Um segundo ao lado dele, criado com `pg_createcluster`, faz o papel
do segundo servidor; a lição 20 cria um do mesmo jeito para ensaiar um upgrade.

```
ana@db:~$ sudo pg_createcluster --start 16 staging >/dev/null
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory                 Log file
16  main    5432 online postgres /var/lib/postgresql/16/main    /var/log/postgresql/postgresql-16-main.log
16  staging 5433 online postgres /var/lib/postgresql/16/staging /var/log/postgresql/postgresql-16-staging.log
```

Depois faça o `main` se desviar do jeito que um servidor se desvia. Uma mudança é a correção de um
incidente que ficou; a outra é um ajuste que alguém fez para o banco `shop` sem contar para
ninguém:

```
shop=# ALTER SYSTEM SET work_mem = '64MB';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

shop=# ALTER DATABASE shop SET random_page_cost = 1.1;
ALTER DATABASE
```

## A comparação

Rode a consulta nos dois e compare o que sai. O `-XAt -F ' = '` faz o `psql` imprimir linhas
`nome = valor` cruas, sem cabeçalho e sem `.psqlrc`, que é o que o `diff` quer. O cluster de
staging não tem um papel chamado `ana`, então esse lado roda como `postgres`:

```
ana@db:~$ psql -XAt -F ' = ' -f settings.sql > main.txt
ana@db:~$ sudo -u postgres psql -p 5433 -XAt -F ' = ' < settings.sql > staging.txt
ana@db:~$ diff main.txt staging.txt
5,8c5,8
< lc_messages = C.UTF-8
< lc_monetary = C.UTF-8
< lc_numeric = C.UTF-8
< lc_time = C.UTF-8
---
> lc_messages = C
> lc_monetary = C
> lc_numeric = C
> lc_time = C
19d18
< work_mem = 64MB
```

Uma linha que começa com `<` está só no `main.txt`, e uma com `>` está só no `staging.txt`. O
`work_mem = 64MB` é a mudança que você acabou de fazer. **As quatro linhas de locale são um desvio
que ninguém digitou.** O `pg_createcluster` tira o locale do cluster do ambiente do comando que o
roda, e os dois clusters foram criados por comandos diferentes em ambientes diferentes: o `main`
pelo instalador do pacote, o `staging` pelo `sudo` a partir do seu shell. Todo banco criado no
`staging` também herda `C`, então o texto dele ordena por byte, e não pelas regras de um idioma.
Das duas diferenças, essa é a que preocupa, porque ninguém nunca vai lembrar de tê-la causado.

**Falta uma mudança.** O `random_page_cost` não aparece no diff, porque o `psql -f settings.sql`
conectou ao banco `ana`, e um ajuste preso ao `shop` só vale para conexões ao `shop`. O
`pg_settings` diz de onde veio cada valor, e o `\drds` lista os ajustes presos a bancos e papéis:

```
shop=# SELECT name, setting, unit, sourcefile, sourceline FROM pg_settings WHERE name = 'work_mem';
   name   | setting | unit |                    sourcefile                    | sourceline 
----------+---------+------+--------------------------------------------------+------------
 work_mem | 65536   | kB   | /var/lib/postgresql/16/main/postgresql.auto.conf |          3
(1 row)

shop=# \drds
            List of settings
 Role | Database |       Settings       
------+----------+----------------------
      | shop     | random_page_cost=1.1
(1 row)
```

**`sourcefile` e `sourceline` transformam uma diferença num endereço.** O valor está na linha 3 do
`postgresql.auto.conf`, dentro do diretório de dados, que não é onde ninguém procura um arquivo de
configuração no Ubuntu. Uma comparação confiável roda o `settings.sql` uma vez por banco e
acrescenta o `\drds`, porque o catálogo também faz parte da configuração.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 186\" role=\"img\" aria-label=\"Cinco lugares de onde vem um valor em uso, da esquerda para a direita na ordem em que o servidor os aplica, e o mais tarde vence: postgresql.conf, que o pacote do Ubuntu fez e você deixa intocado; conf.d/50-shop.conf, seus ajustes num arquivo, guardado no repositório; postgresql.auto.conf, onde o ALTER SYSTEM escreve; ALTER DATABASE ou ALTER ROLE com SET, guardados no catálogo e em nenhum arquivo; e SET numa conexão, que some quando ela fecha. O terceiro e o quarto só existem no servidor.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><line x1=\"8\" y1=\"26\" x2=\"750\" y2=\"26\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><rect x=\"260\" y=\"16\" width=\"260\" height=\"20\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--ink)\" stroke-width=\"0\"></rect><text x=\"390\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lidos nesta ordem, e o valor mais tarde vence</text><rect x=\"8\" y=\"48\" width=\"142\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"79.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">postgresql.conf</text><text x=\"79.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">do Ubuntu, intocado</text><rect x=\"159\" y=\"48\" width=\"142\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"230.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">conf.d/50-shop.conf</text><text x=\"230.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">seus ajustes, um arquivo</text><rect x=\"310\" y=\"48\" width=\"142\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"381.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">postgresql.auto.conf</text><text x=\"381.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o do ALTER SYSTEM</text><rect x=\"461\" y=\"48\" width=\"142\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"532.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ALTER DATABASE</text><text x=\"532.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ALTER ROLE … SET</text><text x=\"532.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no catálogo, sem arquivo</text><rect x=\"612\" y=\"48\" width=\"142\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"683.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SET</text><text x=\"683.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma conexão</text><rect x=\"8\" y=\"144\" width=\"142\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"79.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">feito pelo pacote</text><rect x=\"159\" y=\"144\" width=\"142\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"230.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">guardado no repositório</text><rect x=\"310\" y=\"144\" width=\"293\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"456\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">só neste servidor</text><rect x=\"612\" y=\"144\" width=\"142\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"683.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">some quando ela fecha</text></svg>", "caption": "De onde vem um valor em uso, na ordem em que o servidor aplica. Só o segundo está no repositório, e os dois depois dele passam por cima."}
```

## Desfazendo

Desfaça as duas mudanças e remova o segundo cluster. O resto do curso espera o `main` como a lição
5 o deixou, e um só cluster na máquina:

```
shop=# ALTER SYSTEM RESET work_mem;
ALTER SYSTEM

shop=# ALTER DATABASE shop RESET random_page_cost;
ALTER DATABASE

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

Depois, de volta ao shell:

```
ana@db:~$ sudo pg_dropcluster --stop 16 staging
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```
