---
title: Um cache sobre vários servidores
version: 1
---

Servidores Memcached não sabem uns dos outros. **O cliente espalha as chaves**: ele calcula o hash de
cada chave e escolhe um servidor a partir do hash, então todo cliente com a mesma lista manda a mesma
chave para o mesmo servidor. Suba mais dois, nas portas 11212 e 11213:

```
ana@web:~$ sudo memcached -d -u memcache -l 127.0.0.1 -p 11212 -m 64 && sudo memcached -d -u memcache -l 127.0.0.1 -p 11213 -m 64 && pgrep -a memcached
1769 /usr/bin/memcached -m 64 -p 11211 -u memcache -l 127.0.0.1 -P /var/run/memcached/memcached.pid
1828 memcached -d -u memcache -l 127.0.0.1 -p 11212 -m 64
1840 memcached -d -u memcache -l 127.0.0.1 -p 11213 -m 64
```

Este programa entrega mil chaves a um cliente que conhece dois deles:

```schooling-example
{"language": "python", "file": "spread.py", "parts": [{"code": "from pymemcache.client.hash import HashClient\n\nservers = [(\"127.0.0.1\", 11211), (\"127.0.0.1\", 11212)]\nmc = HashClient(servers, default_noreply=False)\nfor i in range(1000):\n    mc.set(f\"book:{i}\", b\"1\")\nprint(\"book:7 lives on\", mc.hasher.get_node(\"book:7\"))\n", "note": "Mil chaves por um cliente que conhece dois servidores, e o servidor para onde foi o `book:7`."}]}
```

```
ana@web:~/work$ python3 spread.py
book:7 lives on 127.0.0.1:11212
ana@web:~/work$ for p in 11211 11212; do printf 'stats\r\n' | nc -q1 127.0.0.1 $p | grep ' curr_items '; done
STAT curr_items 513
STAT curr_items 487
```

513 chaves foram para um servidor e 487 para o outro, o `book:7` entre as do segundo. Nenhum dos dois
sabe que o outro guarda metade do cache.

O jeito óbvio de escolher um servidor é o hash módulo o número de servidores. Ele espalha as chaves por
igual e **falha no dia em que um servidor é acrescentado**, porque com três servidores em vez de dois a
maioria dos hashes cai num servidor diferente. O `HashClient` usa **hashing de rendezvous**: para cada
chave ele dá uma nota a cada servidor, a partir de um hash do nome do servidor junto com a chave, e fica
com a maior. Um servidor novo ganha as chaves em que agora tem a maior nota, e nenhuma outra chave se
move. Este programa conta os dois:

```schooling-example
{"language": "python", "file": "moves.py", "parts": [{"code": "import zlib\n\nfrom pymemcache.client.rendezvous import RendezvousHash\n\nkeys = [f\"book:{i}\" for i in range(10000)]\n\n\ndef modulo(key, n):\n    return zlib.crc32(key.encode()) % n\n\n\ndef rendezvous(key, n):\n    return RendezvousHash(nodes=list(range(n))).get_node(key)\n\n\nfor name, place in ((\"modulo\", modulo), (\"rendezvous\", rendezvous)):\n    moved = sum(place(k, 2) != place(k, 3) for k in keys)\n    print(f\"{name:>10}: {moved} of {len(keys)} keys move ({moved / len(keys):.0%})\")\n", "note": "Conta as chaves que mudam de servidor quando dois servidores viram três, por módulo e por rendezvous."}]}
```

```
ana@web:~/work$ python3 moves.py
    modulo: 6591 of 10000 keys move (66%)
rendezvous: 3327 of 10000 keys move (33%)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 178\" role=\"img\" aria-label=\"Duas barras, cada uma representando 10.000 chaves quando um terceiro servidor se junta a dois. Módulo: 6.591 chaves se movem, dois terços da barra. Rendezvous: 3.327 chaves se movem, um terço da barra.\"><defs><marker id=\"frh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"350\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">10.000 chaves, dois servidores viram três</text><text x=\"130\" y=\"57\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">módulo</text><rect x=\"145\" y=\"48\" width=\"316.368\" height=\"18\" fill=\"var(--amber)\" stroke=\"none\" fill-opacity=\"0.7\"></rect><rect x=\"461.368\" y=\"48\" width=\"163.632\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\" fill-opacity=\"0.4\"></rect><text x=\"145\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6.591 se movem</text><text x=\"625\" y=\"39\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ficam</text><text x=\"130\" y=\"115\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rendezvous</text><rect x=\"145\" y=\"106\" width=\"159.696\" height=\"18\" fill=\"var(--amber)\" stroke=\"none\" fill-opacity=\"0.7\"></rect><rect x=\"304.696\" y=\"106\" width=\"320.304\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\" fill-opacity=\"0.4\"></rect><text x=\"145\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3.327 se movem</text><text x=\"625\" y=\"97\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ficam</text><text x=\"350\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">toda chave que se move é um erro de cache</text></svg>", "caption": "Acrescentar um servidor custa um erro de cache por chave que se move. O hashing de rendezvous move só as chaves que o servidor novo assume.", "same": ["rendezvous"]}
```

De dois servidores para três, o módulo moveu duas chaves em cada três e o rendezvous uma em três, o terço
que o servidor novo deve ter. **Toda chave que se move é um erro de cache**, respondido pelo banco
enquanto o cache se refaz, então a distância entre esses dois números é a distância entre um terço e
dois terços do tráfego chegando ao banco de uma vez. O hashing consistente, que põe servidores e chaves
num anel, obtém a mesma propriedade de outro jeito, e muitos clientes de Memcached o usam.

Um servidor que para de responder é o mesmo evento ao contrário: a parte dele das chaves vira erro de
cache e os outros seguem. Um cache tem direito de perder dados, e esse é o momento em que o banco paga
por isso.

Quando terminar com eles, pare os dois servidores extras:

```sh
sudo kill $(pgrep -f 'memcached -d -u memcache')
```
