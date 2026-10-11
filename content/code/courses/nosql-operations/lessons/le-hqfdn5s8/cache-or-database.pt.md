---
title: Um cache, um banco, e a instância que é os dois
version: 1
---

No papel, as políticas são fáceis de distinguir. O problema começa com um Redis que guarda dois tipos de
chave: cópias que a aplicação consegue refazer, como páginas renderizadas, e registros que ela não
consegue, como o contador de estoque ou as chaves de idempotência da aula 12. **Toda política é errada
para um dos dois tipos**, e a tentativa mais popular de atender os dois é a que falha do jeito mais
confuso.

## `volatile-lru`, quando ninguém definiu TTL

A ideia do `volatile-` é boa: dar expiração a toda chave de cache, deixar os registros sem, e só as
chaves de cache podem ser despejadas. A carga da seção anterior, sob `volatile-lru`:

```
ana@vm:~$ sh fill.sh volatile-lru
volatile-lru: refused 22334, evicted_keys:0, keys left 17670, products left 4 of 4
```

**22.334 escritas recusadas e nada despejado, sob uma política cujo nome diz que despeja.**
Nenhuma página tinha expiração, então nenhuma chave era candidata, e o Redis passou a recusar escritas
exatamente como o `noeviction` faria. A equipe que escolheu essa política acredita que roda um cache; a
aplicação vê erros `OOM` numa instância cheia que nunca despejou uma chave. Isso acontece no dia em que um caminho do código grava uma chave de cache com um `SET` simples e sem
`EX`. A aula 12 mostrou que um `SET` comum também tira a expiração de uma chave que tinha uma.

A mesma carga com toda página gravada com uma hora de expiração:

```
ana@vm:~$ sh fill.sh volatile-lru 3600
volatile-lru (pages with TTL): refused 0, evicted_keys:25306, keys left 14586, products left 4 of 4
ana@vm:~$ sh fill.sh volatile-ttl 3600
volatile-ttl (pages with TTL): refused 0, evicted_keys:25305, keys left 14570, products left 4 of 4
```

Agora a política funciona como planejado. Páginas foram despejadas, nada foi recusado e **os quatro
produtos ficaram, tanto sob `volatile-lru` quanto sob `volatile-ttl`**, porque uma chave sem expiração
nunca é candidata. É o arranjo funcionando, e ele depende de toda escrita de cache, em todo serviço,
durante toda a vida do sistema, lembrar do seu `EX`.

## Os outros dois jeitos de errar

```
ana@vm:~$ sh fill.sh allkeys-lru 3600
allkeys-lru (pages with TTL): refused 0, evicted_keys:25306, keys left 14570, products left 4 of 4
ana@vm:~$ sh fill.sh noeviction
noeviction: refused 22334, evicted_keys:0, keys left 17670, products left 4 of 4
```

O `allkeys-lru` com as mesmas páginas: nada recusado, mas os produtos são candidatos como todo o resto.
Eles sobreviveram nesta execução porque eram lidos o tempo todo; um produto que ninguém olhou por uma
hora é um registro que a loja perdeu, em silêncio, sem erro em lugar nenhum. O `noeviction` mantém todo
registro, e recusa 22.334 escritas de páginas de cache que deveriam só ter empurrado as mais
antigas para fora.

## Duas instâncias

O arranjo que não depende de ninguém lembrar de nada são dois servidores Redis:

| | um cache | um banco de dados |
| --- | --- | --- |
| o que guarda | cópias que a aplicação consegue refazer a partir de outro lugar | registros que não existem em mais lugar nenhum |
| `maxmemory-policy` | `allkeys-lru` ou `allkeys-lfu` | `noeviction` |
| quando enche | despeja, e a aplicação refaz o que faltar | recusa escritas, e alguém é acionado |
| persistência (aula 13) | nenhuma: `--save ""`, sem arquivo append-only | snapshots e arquivo append-only |
| um reinício | começa vazio, e tudo bem | precisa voltar com tudo |
| `maxmemory` | a memória que pode usar | a memória que pode usar, com um alerta bem antes |

Dois servidores Redis pequenos custam pouco mais que um grande, já que cada um usa só a memória do que
guarda. **Uma instância com `volatile-*` é um banco de dados que também faz cache**, e só é segura
enquanto toda escrita nela for disciplinada; vale escolhê-la só quando uma segunda instância de fato não
está disponível.
