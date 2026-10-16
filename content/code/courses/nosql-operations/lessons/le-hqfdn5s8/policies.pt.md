---
title: As políticas de despejo, sob a mesma carga
version: 1
---

Uma política que não seja `noeviction` faz o Redis apagar chaves para abrir espaço, e a política diz
quais. Os nomes são duas escolhas ligadas por um hífen: **quais chaves podem ser despejadas, e como uma
é escolhida entre elas.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Uma grade das políticas de despejo. As colunas são como uma chave é escolhida: usada há mais tempo, usada com menos frequência, mais perto de expirar, e ao acaso. As linhas são quais chaves podem ser despejadas: todas, ou só as que têm expiração. A linha de todas as chaves tem allkeys-lru, allkeys-lfu e allkeys-random, sem política para a mais perto de expirar. A linha das chaves com expiração tem volatile-lru, volatile-lfu, volatile-ttl e volatile-random. Abaixo da grade, separada dela, noeviction: não despejar nada e recusar escritas.\"><text x=\"230.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">usada há mais tempo</text><text x=\"360.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">usada com menos frequência</text><text x=\"490.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais perto de expirar</text><text x=\"620.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ao acaso</text><text x=\"170\" y=\"8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">como uma é escolhida →</text><text x=\"158\" y=\"65\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">qualquer chave</text><rect x=\"170\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">allkeys-lru</text><rect x=\"300\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">allkeys-lfu</text><rect x=\"430\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"490.0\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não existe</text><rect x=\"560\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">allkeys-random</text><text x=\"158\" y=\"127\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">só chaves com expiração</text><rect x=\"170\" y=\"102\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">volatile-lru</text><rect x=\"300\" y=\"102\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">volatile-lfu</text><rect x=\"430\" y=\"102\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"490.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">volatile-ttl</text><rect x=\"560\" y=\"102\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">volatile-random</text><text x=\"158\" y=\"24\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">quais chaves podem sair ↓</text><rect x=\"170\" y=\"186\" width=\"250\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"295.0\" y=\"203.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">noeviction</text><text x=\"295.0\" y=\"218.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não despeja, recusa escritas</text></svg>", "caption": "Oito políticas são duas escolhas: quais chaves podem sair, e como uma é escolhida entre elas. O noeviction fica fora da grade, porque não escolhe nada."}
```

`allkeys-` quer dizer que qualquer chave pode sair; `volatile-`, que só chaves com expiração podem sair,
e as sem expiração nunca são tocadas. `lru` escolhe a chave usada há mais tempo, `lfu` a usada com menos
frequência, `ttl` a mais perto de expirar, `random` qualquer uma. O Redis não mantém uma ordem perfeita
de milhões de chaves: ele amostra um punhado, cinco por padrão (`maxmemory-samples`), e despeja a melhor
candidata entre elas, o que chega perto do ideal e não custa quase nada.

## Uma carga, três políticas

Para comparar de forma justa, toda política recebe a mesma carga. A loja tem quatro produtos que toda
página lê, e uma enxurrada de páginas que são gravadas uma vez e nunca mais lidas. Este arquivo define a
política, grava os quatro produtos, depois 40.000 páginas, lendo os quatro produtos a cada 100 páginas,
e informa o que sobrou:

```sh
# fill.sh POLICY [TTL]: an empty Redis with that eviction policy, four products,
# then 40,000 pages of 100 bytes, reading the four products every 100 pages.
# With TTL, every page is written with that lifetime in seconds.
policy=$1
r() { docker exec redis redis-cli "$@"; }
r FLUSHALL > /dev/null
r CONFIG RESETSTAT > /dev/null
r CONFIG SET maxmemory-policy "$policy" > /dev/null
r MSET product:KB-101 34990 product:MS-204 18900 product:MN-330 149900 product:CB-012 3990 > /dev/null
refused=$(seq 1 40000 |
  awk -v ttl="$2" '{ printf "SET page:%d %0100d%s\n", $1, 0, (ttl ? " EX " ttl : "") }
    $1 % 100 == 0 { print "MGET product:KB-101 product:MS-204 product:MN-330 product:CB-012" }' |
  docker exec -i redis redis-cli | grep -c OOM)
echo "$policy${2:+ (pages with TTL)}: refused $refused, $(r INFO stats | grep ^evicted_keys | tr -d '\r'), keys left $(r DBSIZE), products left $(r EXISTS product:KB-101 product:MS-204 product:MN-330 product:CB-012) of 4"
```

Salve-o como `fill.sh` no seu diretório e rode-o sob as três políticas `allkeys-`, conferindo depois da
primeira quais páginas ela manteve:

```
ana@vm:~$ sh fill.sh allkeys-lru
allkeys-lru: refused 0, evicted_keys:22426, keys left 17432, products left 4 of 4
ana@vm:~$ docker exec redis redis-cli EXISTS page:1
0
ana@vm:~$ docker exec redis redis-cli EXISTS page:40000
1
ana@vm:~$ sh fill.sh allkeys-lfu
allkeys-lfu: refused 0, evicted_keys:22426, keys left 17432, products left 4 of 4
ana@vm:~$ sh fill.sh allkeys-random
allkeys-random: refused 0, evicted_keys:22427, keys left 17430, products left 2 of 4
```

**As três abriram espaço, então nada foi recusado**, e cada uma despejou mais ou menos o mesmo número
de chaves: o bastante para manter o total abaixo de 4 MB. A diferença está em quais chaves. O
`allkeys-lru` e o `allkeys-lfu` mantiveram os quatro produtos, porque os produtos eram lidos a cada 100
páginas e as páginas nunca eram lidas. **O `allkeys-random` despejou dois dos quatro
produtos**, porque, para uma escolha ao acaso, um produto lido milhares de vezes vale exatamente o mesmo
que uma página que ninguém vai ler.

Sob `allkeys-lru` a primeira página tinha sumido e a última estava lá: as páginas mais antigas, nunca
lidas desde que foram gravadas, eram as usadas há mais tempo, então saíram primeiro.

## LRU ou LFU

Os dois mantiveram os produtos aqui, e diferem num padrão que esta carga não tinha. O LRU lembra só **quando** uma chave foi usada pela última vez. Então uma única passada por muitas chaves, um relatório
noturno que lê cada página uma vez, torna todas recentes e empurra para fora as chaves que a loja lê o
dia inteiro. O LFU guarda um pequeno contador de **com que frequência** uma chave é usada, que uma
única passada quase não move:

```
ana@vm:~$ sh fill.sh allkeys-lfu
allkeys-lfu: refused 0, evicted_keys:22426, keys left 17432, products left 4 of 4
ana@vm:~$ docker exec redis redis-cli OBJECT FREQ product:KB-101
11
ana@vm:~$ docker exec redis redis-cli OBJECT FREQ page:39999
5
```

O `OBJECT FREQ` é esse contador. O produto, lido a cada 100 páginas, está em 11; uma página
gravada uma vez e nunca lida está em 5, o valor com que toda chave nova começa para não ser
despejada assim que chega. O contador cresce de forma logarítmica e decai com o tempo, então mede a
popularidade recente, e não um total de toda a vida; as duas configurações que o ajustam,
`lfu-log-factor` e `lfu-decay-time`, ficam nos padrões aqui. Para um cache cujas chaves quentes são
estáveis, um catálogo, o `allkeys-lfu` é o melhor padrão; para um em que o que está quente muda a cada
minuto, o `allkeys-lru` acompanha mais rápido.
