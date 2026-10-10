---
title: Divida os dados por chave, e a parede se move
version: 1
---

**O caminho para passar da parede é garantir que nenhum passo precise de todos os dados de uma
vez.** Contar os visitantes diferentes de um livro precisa de todos os eventos dos visitantes desse
livro juntos, mas não precisa de todos os visitantes juntos. Então a Ana divide o trabalho por
visitante e conta cada parte sozinha. Salve como `~/big/buckets.py`:

```schooling-example
{
  "language": "python",
  "file": "buckets.py",
  "parts": [
    {
      "code": "\"\"\"The same question, in two passes, without holding every visitor at once.\"\"\"\nimport csv\nimport glob\nimport gzip\nimport os\nimport resource\nimport zlib\n\n"
    },
    {
      "code": "N = 16\nos.makedirs(\"buckets\", exist_ok=True)\nout = [open(f\"buckets/{i:02}.csv\", \"w\") for i in range(N)]\nfor path in sorted(glob.glob(\"data/raw/clicks/day=*/*.csv.gz\")):\n    with gzip.open(path, \"rt\") as f:\n        for row in csv.DictReader(f):\n            if row[\"book_id\"]:\n                i = zlib.crc32(row[\"visitor_id\"].encode()) % N\n                out[i].write(f'{row[\"book_id\"]},{row[\"visitor_id\"]}\\n')\nfor f in out:\n    f.close()\n\n",
      "note": "**A primeira passada manda cada par para um de dezesseis arquivos**, escolhido pelo visitante. O `crc32` é um checksum usado aqui como hash: o mesmo visitante sempre cai no mesmo arquivo. O `hash()` do próprio Python não serviria, porque muda de uma execução para outra."
    },
    {
      "code": "counts = {}\nfor i in range(N):\n    seen = {}\n    with open(f\"buckets/{i:02}.csv\") as f:\n        for line in f:\n            book, visitor = line.rstrip(\"\\n\").split(\",\")\n            seen.setdefault(book, set()).add(visitor)\n    for book, visitors in seen.items():\n        counts[book] = counts.get(book, 0) + len(visitors)\n\nfor book, n in sorted(counts.items(), key=lambda kv: kv[1], reverse=True)[:3]:\n    print(f\"book {book}: {n:,} visitors\")\npeak = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss\nprint(f\"peak memory: {peak / 1024:,.0f} MB\")\n",
      "note": "**A segunda passada lê um arquivo por vez**, monta os conjuntos só daquele arquivo e os descarta. Cada visitante está em exatamente um arquivo, então as contagens dos dezesseis simplesmente se somam."
    }
  ]
}
```

O mesmo limite de 1 GB:

```
ana@lab:~/big$ (ulimit -v 1000000; time python3 buckets.py)
book 1: 936,076 visitors
book 2: 335,986 visitors
book 3: 244,287 visitors
peak memory: 163 MB

real	1m10.381s
user	1m8.465s
sys	0m0.976s
```

**Os mesmos três números, no mesmo tempo, com 163 MB em vez de 2,3 GB.** A primeira passada custa
uma segunda cópia dos pares em disco, 271 MB, e essa é a troca: disco é barato e farto, e memória
não é nem uma coisa nem outra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-buckets\" aria-label=\"Duas passadas sobre os cliques. À esquerda, 365 arquivos diários de eventos. A primeira passada os lê uma vez e manda cada par de livro e visitante para um de dezesseis arquivos, escolhido por um hash do visitante. Quinze arquivos têm cerca de 17 MB; o 09, que guarda o robô, tem 28 MB. A segunda passada lê um arquivo por vez, conta os visitantes diferentes de cada livro nele e soma as contagens num total por livro.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16.0\" y=\"115.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"91.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">365 arquivos diários</text><text x=\"91.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">24 milhões de eventos</text><rect x=\"290.0\" y=\"30.0\" width=\"80.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">00.csv</text><path d=\"M166.0 145.0 L288.0 43.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M370.0 43.0 L470.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"290.0\" y=\"64.0\" width=\"80.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">01.csv</text><path d=\"M166.0 145.0 L288.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M370.0 77.0 L470.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"290.0\" y=\"98.0\" width=\"80.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">02.csv</text><path d=\"M166.0 145.0 L288.0 111.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M370.0 111.0 L470.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"330.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">· · ·</text><rect x=\"290.0\" y=\"158.0\" width=\"80.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">09.csv</text><path d=\"M166.0 145.0 L288.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M370.0 180.0 L470.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"380.0\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o robô</text><text x=\"330.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">· · ·</text><rect x=\"290.0\" y=\"236.0\" width=\"80.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">15.csv</text><path d=\"M166.0 145.0 L288.0 249.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M370.0 249.0 L470.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"228.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">passada 1: por visitante</text><text x=\"420.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">passada 2: um por vez</text><rect x=\"472.0\" y=\"115.0\" width=\"220.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"582.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">visitantes por livro</text><text x=\"582.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as contagens se somam</text></svg>", "caption": "A primeira passada decide para onde vai cada par; a segunda nunca segura mais de um arquivo. O mesmo visitante sempre cai no mesmo arquivo, e é isso que deixa as contagens se somarem."}
```

**Olhe os tamanhos dos dezesseis arquivos**, porque um deles não é como os outros:

```
ana@lab:~/big$ ls -lS buckets | head -4
total 276932
-rw-r--r-- 1 ana ana 28342444 Oct 10 04:23 09.csv
-rw-r--r-- 1 ana ana 17091101 Oct 10 04:23 03.csv
-rw-r--r-- 1 ana ana 17042747 Oct 10 04:23 01.csv
ana@lab:~/big$ ls -lS buckets | tail -2
-rw-r--r-- 1 ana ana 16969934 Oct 10 04:23 14.csv
-rw-r--r-- 1 ana ana 16961778 Oct 10 04:23 08.csv
ana@lab:~/big$ du -sh buckets
271M	buckets
```

Quinze arquivos de uns 17 MB e um de 28 MB. Os visitantes foram espalhados por igual pelo hash, mas
os eventos não: o arquivo 09 guarda o `v0000000`, o robô, e com ele quatro eventos em cada cem. A
memória da segunda passada, o seu tempo e a sua chance de falhar são decididos pelo maior arquivo e
não pela média. A aula 8 é inteira sobre esse arquivo.

## O que isso tem a ver com um cluster

Leia o programa de novo pensando num cluster, porque **você acabou de escrever, à mão, os três
passos de que todo job distribuído é feito**:

1. **Dividir por chave.** Cada registro vai para a parte que a sua chave decide, e a mesma chave
   sempre vai para a mesma parte. O Spark chama isso de *shuffle*.
2. **Trabalhar em cada parte sozinha.** Nada na segunda passada para o arquivo 03 precisa do
   arquivo 07. As dezesseis partes poderiam ser contadas em dezesseis máquinas ao mesmo tempo, e
   num cluster elas são.
3. **Combinar.** As contagens parciais somam a resposta.

Aqui as dezesseis partes foram feitas uma depois da outra, numa máquina só, então o programa passou
da parede da memória e não ganhou tempo nenhum. Um cluster faz a mesma divisão e depois trabalha
nas partes ao mesmo tempo, em máquinas diferentes: é assim que ele passa também da parede do tempo.
