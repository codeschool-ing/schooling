---
title: O Sentinel, e um failover que ninguém digitou
version: 1
---

Uma réplica pode assumir, mas alguma coisa precisa perceber que o primário sumiu, escolher uma réplica,
promovê-la, apontar as outras réplicas para ela e avisar os clientes. **O Sentinel é essa coisa**: um
processo separado, rodando num número ímpar de cópias, que vigia o primário e só age quando a maioria
das cópias concorda. Um Sentinel só seria um ponto único de falha ele mesmo, e não saberia distinguir
"o primário caiu" de "eu fiquei isolado".

## A configuração, inteira

Todo Sentinel recebe as mesmas seis linhas:

```ini
port 26379
sentinel resolve-hostnames yes
sentinel announce-hostnames yes
sentinel monitor shop redis-1 6379 2
sentinel down-after-milliseconds shop 5000
sentinel failover-timeout shop 30000
```

| linha | o que diz |
| --- | --- |
| `port 26379` | a porta do próprio Sentinel, separada da 6379 do Redis |
| `resolve-hostnames`, `announce-hostnames` | usar e anunciar nomes como `redis-1` em vez de endereços |
| `monitor shop redis-1 6379 2` | vigiar o primário em `redis-1:6379` com o nome `shop`, e considerá-lo fora do ar quando **2** Sentinels concordarem: o quórum |
| `down-after-milliseconds shop 5000` | um primário em silêncio por 5 segundos está fora do ar, na opinião deste Sentinel |
| `failover-timeout shop 30000` | quanto tempo um failover pode levar antes que outro possa ser tentado |

O Sentinel reescreve o próprio arquivo conforme aprende: as réplicas que achou, os outros Sentinels, o
primário atual. Por isso cada cópia precisa de um arquivo próprio em que possa gravar, e o primeiro
comando abaixo dá a cada uma um diretório seu.

## Três Sentinels

```
ana@vm:~$ for i in 1 2 3; do mkdir sentinel-$i && cp sentinel.conf sentinel-$i/; done
ana@vm:~$ for i in 1 2 3; do docker run -d --name sentinel-$i --network nosql -v "$PWD/sentinel-$i:/conf" redis:7.4 redis-sentinel /conf/sentinel.conf; done
e7b6cf8bc30679058892da52b7816070e677f6026bb7db72a01529ca1e0a5207
93be74a7cf8a2912d33c20c0e4712766d3c332e63c4fa83b7787693a1a6ad02b
124166a00dee91fe3731b8f0d98e7da446ca27d71c05b00a184aa29d6e9f892a
```

O `redis-sentinel` é o mesmo programa que o `redis-server`, iniciado em outro modo, e vem na mesma
imagem. Perguntado quem é o primário, e o que sabe:

```
ana@vm:~$ docker exec sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name shop
redis-1
6379
ana@vm:~$ docker exec sentinel-1 redis-cli -p 26379 SENTINEL master shop | paste - - | grep -E "^(flags|num-slaves|num-other-sentinels|quorum)\s"
flags	master
num-slaves	2
num-other-sentinels	2
quorum	2
```

Um cliente nunca pede o `redis-1`; ele pergunta a um Sentinel pelo primário de `shop`, e é por isso que
um failover pode mudar o primário sem ninguém trocar um endereço. Toda biblioteca de cliente comum tem
um modo Sentinel que faz exatamente isso.

## Parando o primário

```
ana@vm:~$ docker stop redis-1
redis-1
ana@vm:~$ docker exec sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name shop
redis-2
6379
ana@vm:~$ for s in sentinel-1 sentinel-2 sentinel-3; do echo "== $s"; docker logs $s 2>&1 | grep -E "[+](sdown|odown|vote-for-leader|selected-slave|promoted-slave|switch-master) "; done
== sentinel-1
1:X 10 Oct 2026 20:13:16.130 # +sdown master shop redis-1 6379
1:X 10 Oct 2026 20:13:16.186 # +odown master shop redis-1 6379 #quorum 3/2
1:X 10 Oct 2026 20:13:16.189 # +vote-for-leader 00d0b02cc79045c8796a9a0d3834320e2a5863b2 1
1:X 10 Oct 2026 20:13:16.319 # +selected-slave slave redis-2:6379 redis-2 6379 @ shop redis-1 6379
1:X 10 Oct 2026 20:13:17.209 # +promoted-slave slave redis-2:6379 redis-2 6379 @ shop redis-1 6379
1:X 10 Oct 2026 20:13:18.296 # +switch-master shop redis-1 6379 redis-2 6379
1:X 10 Oct 2026 20:13:23.324 # +sdown slave redis-1:6379 redis-1 6379 @ shop redis-2 6379
== sentinel-2
1:X 10 Oct 2026 20:13:16.083 # +sdown master shop redis-1 6379
1:X 10 Oct 2026 20:13:16.194 # +vote-for-leader 00d0b02cc79045c8796a9a0d3834320e2a5863b2 1
1:X 10 Oct 2026 20:13:17.244 # +odown master shop redis-1 6379 #quorum 3/2
1:X 10 Oct 2026 20:13:17.307 # +switch-master shop redis-1 6379 redis-2 6379
1:X 10 Oct 2026 20:13:22.363 # +sdown slave redis-1:6379 redis-1 6379 @ shop redis-2 6379
== sentinel-3
1:X 10 Oct 2026 20:13:16.121 # +sdown master shop redis-1 6379
1:X 10 Oct 2026 20:13:16.194 # +vote-for-leader 00d0b02cc79045c8796a9a0d3834320e2a5863b2 1
1:X 10 Oct 2026 20:13:16.199 # +odown master shop redis-1 6379 #quorum 2/2
1:X 10 Oct 2026 20:13:17.307 # +switch-master shop redis-1 6379 redis-2 6379
1:X 10 Oct 2026 20:13:22.369 # +sdown slave redis-1:6379 redis-1 6379 @ shop redis-2 6379
```

Leia os três logs juntos. Uns cinco segundos depois da parada, cada Sentinel marcou o primário como
**subjetivamente fora do ar**, `+sdown`, a opinião dele. Quando dois concordaram, ele ficou
**objetivamente fora do ar**, `+odown`, com o quórum alcançado. Depois votaram num líder, e os três logs
citam o mesmo id em `+vote-for-leader`. O líder, aqui o `sentinel-1`, escolheu o `redis-2`
(`+selected-slave`), o promoveu (`+promoted-slave`) e anunciou a mudança (`+switch-master`), que os
outros dois repetem. Do `+sdown` ao `+switch-master` foram cerca de dois segundos no log do
`sentinel-1`, de 20:13:16.130 a 20:13:18.296. A última linha de cada um, `+sdown slave redis-1`, é o
Sentinel já contando o servidor parado como réplica do novo primário.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 220\" role=\"img\" aria-label=\"Uma linha do tempo do failover. O primário redis-1 para. Por cinco segundos nada acontece: é o down-after-milliseconds. Depois cada Sentinel o marca como subjetivamente fora do ar e, quando dois concordam, objetivamente fora do ar. Os Sentinels elegem um líder, o líder escolhe o redis-2, o promove e anuncia a troca. O redis-3 passa a seguir o novo primário. Quando o redis-1 volta, é transformado em réplica.\"><line x1=\"30\" y1=\"110\" x2=\"670\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><line x1=\"40\" y1=\"100\" x2=\"40\" y2=\"120\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"40\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">redis-1 para</text><line x1=\"210\" y1=\"100\" x2=\"210\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"2\"></line><text x=\"210\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+sdown</text><line x1=\"290\" y1=\"100\" x2=\"290\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"2\"></line><text x=\"290\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+odown</text><line x1=\"370\" y1=\"100\" x2=\"370\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"2\"></line><text x=\"370\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+vote-for-leader</text><line x1=\"460\" y1=\"100\" x2=\"460\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"460\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">+promoted-slave</text><line x1=\"560\" y1=\"100\" x2=\"560\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"560\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">+switch-master</text><rect x=\"40\" y=\"40\" width=\"170\" height=\"26\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"125\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5 s de silêncio</text><text x=\"260\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2 Sentinels concordam: o quórum</text><text x=\"460\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">redis-2 vira o primário</text><text x=\"620\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">clientes perguntam de novo</text><text x=\"620\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">redis-1, ao voltar: uma réplica</text></svg>", "caption": "O failover do Sentinel na ordem em que os logs o imprimem. Os primeiros cinco segundos são espera; o resto levou cerca de dois segundos no laboratório."}
```

## Depois do failover

```
ana@vm:~$ primary=$(docker exec sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name shop | head -1); echo $primary
redis-2
ana@vm:~$ docker exec $primary redis-cli GET order:1001
paid
ana@vm:~$ docker start redis-1
redis-1
ana@vm:~$ docker exec redis-1 redis-cli INFO replication | grep -E "^(role|master_host|master_link_status):"
role:slave
master_host:redis-2
master_link_status:down
```

O novo primário tem o pedido 1001: ele foi replicado bem antes da parada. E quando o `redis-1` voltou,
**não voltou como primário.** O Sentinel já tinha seguido em frente, então mandou o servidor que voltava
virar réplica do novo, e o `INFO replication` diz isso: uma réplica do `redis-2`, com o link ainda
subindo no momento da pergunta. Dois primários aceitando escritas para os mesmos dados é o resultado
que tudo isso existe para impedir.
