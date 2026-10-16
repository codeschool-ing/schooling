---
title: Acrescentando um shard, e as chaves que se mudam
version: 1
---

O roteador da seção 09 escolhia um shard com `event_id % len(SHARDS)`, o resto da divisão do id do
show pelo número de shards. É simples, espalha as chaves por igual, e tem uma propriedade que só
aparece no dia em que existe um terceiro shard: **com três shards, o resto de quase todo id muda**.

Mover uma linha de um shard para outro é trabalho de verdade: copiá-la, garantir que nenhuma
escrita chegue no meio, trocar as leituras, apagar o original. Quanto menos chaves se mudam, mais
barato é acrescentar um shard. Este programa conta quantas se mudam, para cem mil chaves, com o
módulo e com a alternativa chamada **hash consistente**:

```schooling-example
{"language": "python", "file": "keys.py", "parts": [{"code": "# keys.py\n\"\"\"How many keys move when two shards become three: modulo against a ring.\"\"\"\nimport bisect\nimport hashlib\nfrom collections import Counter\n\nkeys = [f\"event-{n}\" for n in range(1, 100_001)]\n\n\ndef h(text):\n    return int.from_bytes(hashlib.md5(text.encode()).digest()[:8], \"big\")", "note": "Cem mil chaves e uma função de hash. O MD5 está aqui como um jeito rápido de espalhar textos por uma faixa grande de números, não por nada ligado a segurança."}, {"code": "\n\ndef modulo(shards):\n    return {k: f\"s{h(k) % shards}\" for k in keys}", "note": "**Módulo**: o shard de uma chave é o resto da divisão do hash pelo número de shards. Simples, equilibrado, e o resto de toda chave muda quando o divisor muda."}, {"code": "\n\ndef ring(shards, points_each=100):\n    points = sorted((h(f\"s{s}#{p}\"), f\"s{s}\") for s in range(shards) for p in range(points_each))\n    hashes = [p for p, _ in points]\n    return {k: points[bisect.bisect(hashes, h(k)) % len(points)][1] for k in keys}", "note": "**Um anel de hash**: cada shard é posto em muitos pontos de um círculo pelo hash, e uma chave pertence ao primeiro ponto depois do próprio hash. Acrescentar um shard acrescenta pontos, e só as chaves logo antes dos pontos novos mudam de dono."}, {"code": "\n\ndef moved(before, after):\n    return sum(before[k] != after[k] for k in keys) / len(keys)\n\n\nprint(f\"modulo, 2 -> 3 shards: {moved(modulo(2), modulo(3)):.1%} of keys move,\",\n      dict(sorted(Counter(modulo(3).values()).items())))\nfor points in (10, 100, 1000):\n    after = ring(3, points)\n    print(f\"ring with {points:>4} points each: {moved(ring(2, points), after):.1%} move,\",\n          dict(sorted(Counter(after.values()).items())))", "note": "Para cada esquema, a fatia de chaves cujo shard muda de dois shards para três, e com quantas chaves cada um dos três shards fica."}]}
```

```
ana@lab:~/tickets$ python3 keys.py
modulo, 2 -> 3 shards: 66.6% of keys move, {'s0': 33405, 's1': 33165, 's2': 33430}
ring with   10 points each: 26.2% move, {'s0': 28093, 's1': 45734, 's2': 26173}
ring with  100 points each: 37.8% move, {'s0': 30579, 's1': 31651, 's2': 37770}
ring with 1000 points each: 33.0% move, {'s0': 33961, 's1': 33069, 's2': 32970}
```

**O módulo move 66,6% das chaves** de dois shards para três, quando o terceiro shard só precisa de
um terço delas. Dois terços dos dados viajam, boa parte de um shard antigo para o outro antigo, o
que não ajuda em nada. A aritmética é geral: ir de *n* shards para *n* + 1 pelo módulo move cerca
de *n* / (*n* + 1) de tudo.

**O anel move mais ou menos um terço**, que é o mínimo: o novo shard precisa receber a sua parte, e
só a parte dele se move. Cada shard é posto no anel em muitos pontos, e uma chave pertence ao
primeiro ponto depois do próprio hash; os pontos do novo shard tomam, cada um, um trecho curto do
anel, e as chaves desses trechos são as únicas que mudam de dono.

## Por que os pontos importam

As três linhas do anel mostram para que serve o número de pontos por shard. Com **10 pontos**, só
26,2% se moveram, mas os shards ficaram com 28 093, 45 734 e 26 173 chaves: um shard tem quase o
dobro de outro, porque dez pontos por shard deixam vãos grandes por acaso. Com **1000 pontos** os
shards ficam a uns 3% uns dos outros e 33,0% se moveram, bem no ideal. Mais pontos custam uma
tabela maior para procurar, o que não é nada perto de um shard desequilibrado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um anel de hash desenhado como um círculo. Dois shards, s0 e s1, têm vários pontos nele, e um terceiro shard, s2, acrescenta pontos novos. Arcos curtos logo antes de cada ponto novo estão destacados: são as únicas chaves que vão para o s2. Todo o resto fica onde estava.\"><circle cx=\"220\" cy=\"150\" r=\"110\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"2\"></circle><path d=\"M312.3 90.1 A110 110 0 0 1 327.6 127.1\" stroke=\"var(--phosphor)\" stroke-width=\"7\" fill=\"none\"></path><path d=\"M279.9 242.3 A110 110 0 0 1 242.9 257.6\" stroke=\"var(--phosphor)\" stroke-width=\"7\" fill=\"none\"></path><path d=\"M127.7 209.9 A110 110 0 0 1 112.4 172.9\" stroke=\"var(--phosphor)\" stroke-width=\"7\" fill=\"none\"></path><path d=\"M160.1 57.7 A110 110 0 0 1 197.1 42.4\" stroke=\"var(--phosphor)\" stroke-width=\"7\" fill=\"none\"></path><circle cx=\"239.1\" cy=\"41.7\" r=\"6\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"242.9\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s0</text><circle cx=\"310.1\" cy=\"86.9\" r=\"6\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"328.1\" y=\"74.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">s1</text><circle cx=\"328.3\" cy=\"130.9\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"350.0\" y=\"127.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">s2</text><circle cx=\"328.3\" cy=\"169.1\" r=\"6\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"350.0\" y=\"172.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s0</text><circle cx=\"283.1\" cy=\"240.1\" r=\"6\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"295.7\" y=\"258.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">s1</text><circle cx=\"239.1\" cy=\"258.3\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"242.9\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">s2</text><circle cx=\"200.9\" cy=\"258.3\" r=\"6\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"197.1\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s0</text><circle cx=\"129.9\" cy=\"213.1\" r=\"6\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"111.9\" y=\"225.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">s1</text><circle cx=\"111.7\" cy=\"169.1\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"90.0\" y=\"172.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">s2</text><circle cx=\"111.7\" cy=\"130.9\" r=\"6\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"90.0\" y=\"127.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s0</text><circle cx=\"156.9\" cy=\"59.9\" r=\"6\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"144.3\" y=\"41.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">s1</text><circle cx=\"200.9\" cy=\"41.7\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"197.1\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">s2</text><text x=\"560\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma chave pertence ao próximo</text><text x=\"560\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">ponto no sentido horário</text><path d=\"M430 130 L470 130\" stroke=\"var(--phosphor)\" stroke-width=\"7\" fill=\"none\"></path><text x=\"480\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">chaves que vão para o s2</text><text x=\"560\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">módulo, 2 → 3: 66,6% movem</text><text x=\"560\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">anel, 1000 pontos: 33,0% movem</text></svg>", "caption": "Acrescentar o s2 ao anel move só as chaves logo antes dos seus pontos. O módulo teria movido dois terços de tudo."}
```

O Cassandra, na aula 5, põe os dados num anel exatamente como este, e o DynamoDB aplica um hash à
chave de cada item para escolher onde ele mora. Muitos sistemas com sharding construídos sobre o
PostgreSQL tomam outro caminho para o mesmo fim: criam desde o início muito mais shards que
servidores, digamos 256 shards lógicos em quatro servidores, e movem shards lógicos inteiros entre
servidores. O shard lógico de uma chave nunca muda, então nenhuma chave precisa de um novo hash; só
o mapa de shard lógico para servidor muda.
