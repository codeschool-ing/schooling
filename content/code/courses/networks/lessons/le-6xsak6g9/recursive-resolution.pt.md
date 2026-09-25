---
title: Da raiz até a resposta
version: 1
---

O resolver também não sabia `www.example.com`. Ele descobriu perguntando, e o `dig +trace` repete o
caminho sozinho, imprimindo cada passo:

```
ana@laptop:~$ dig +trace www.example.com

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> +trace www.example.com
;; global options: +cmd
.                       86400   IN      NS      a.root-servers.test.
;; Received 76 bytes from 198.51.100.53#53(198.51.100.53) in 4 ms

com.                    172800  IN      NS      a.gtld-servers.test.
;; Received 124 bytes from 192.0.2.10#53(a.root-servers.test) in 0 ms

example.com.            172800  IN      NS      ns1.example.com.
;; Received 106 bytes from 192.0.2.20#53(a.gtld-servers.test) in 0 ms

www.example.com.        300     IN      A       192.0.2.80
example.com.            3600    IN      NS      ns1.example.com.
;; Received 122 bytes from 192.0.2.53#53(ns1.example.com) in 0 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Como o nome www.example.com foi resolvido. 1: o laptop pergunta ao seu resolver, 198.51.100.53, por www.example.com. 2: o resolver pergunta ao servidor raiz, que responde com uma indicação: pergunte aos servidores .com. 3: o resolver pergunta ao servidor .com, que indica o próximo: pergunte a ns1.example.com. 4: o resolver pergunta a ns1.example.com, que responde com o endereço, 192.0.2.80, e um TTL de 300 segundos. 5: o resolver devolve o endereço ao laptop e o guarda no cache.\"><defs><marker id=\"rs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"107\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"32\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">faz uma pergunta</text><rect x=\"260\" y=\"107\" width=\"190\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"272\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">resolver</text><text x=\"272\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.53, faz o trabalho</text><rect x=\"560\" y=\"20\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rootns</text><text x=\"572\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a raiz, .</text><rect x=\"560\" y=\"107\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tldns</text><text x=\"572\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.com</text><rect x=\"560\" y=\"194\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ns1</text><text x=\"572\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">example.com</text><path d=\"M160 122 L258 122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rs-ah)\"></path><circle cx=\"209\" cy=\"122\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"209\" y=\"122.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><path d=\"M258 138 L162 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rs-ah)\"></path><circle cx=\"209\" cy=\"138\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"209\" y=\"138.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">5</text><path d=\"M450 118 L558 43\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rs-ah)\" marker-start=\"url(#rs-ah)\"></path><circle cx=\"504.0\" cy=\"80.5\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"504.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2</text><path d=\"M450 128 L558 130\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rs-ah)\" marker-start=\"url(#rs-ah)\"></path><circle cx=\"504.0\" cy=\"129.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"504.0\" y=\"129.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3</text><path d=\"M450 138 L558 217\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rs-ah)\" marker-start=\"url(#rs-ah)\"></path><circle cx=\"504.0\" cy=\"177.5\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"504.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">4</text><text x=\"20\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  laptop → resolver: www.example.com?</text><text x=\"20\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2  raiz → resolver: pergunte aos servidores .com</text><text x=\"20\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3  .com → resolver: pergunte a ns1.example.com</text><text x=\"380\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4  ns1 → resolver: 192.0.2.80, TTL 300</text><text x=\"380\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5  resolver → laptop: 192.0.2.80</text></svg>", "caption": "O laptop pergunta uma vez e o resolver faz o caminho: a raiz, depois o domínio de topo, depois o servidor do próprio domínio. Só o último sabe a resposta; os outros só sabem a quem perguntar em seguida.", "same": [".com", "1 laptop → resolver: www.example.com?", "4 ns1 → resolver: 192.0.2.80, TTL 300", "5 resolver → laptop: 192.0.2.80", "example.com"]}
```

1. O resolver é perguntado sobre quais servidores respondem por `.`, a raiz. A resposta é
   `a.root-servers.test`. (A internet de verdade tem treze nomes de servidores raiz, de
   `a.root-servers.net` a `m.root-servers.net`; o laboratório tem um.)
2. **A raiz não sabe `www.example.com`.** Ela sabe quem cuida de `.com`, e diz:
   `a.gtld-servers.test`.
3. O servidor de `.com` também não sabe. Ele sabe quem cuida de `example.com`: `ns1.example.com`.
4. `ns1.example.com` sabe. A resposta é o registro `A`, `192.0.2.80`, TTL 300.

Cada servidor da cadeia responde só pela sua parte do nome, e **passa o resto adiante**. Isso é
**delegação**, e é o que deixa o DNS ser operado por milhões de organizações sem nenhuma delas ter o
todo. Um servidor que manda você a outro devolve uma *indicação* (*referral*) em vez de uma resposta.
Perguntar direto à raiz, com a recursão desligada, mostra uma:

```
ana@laptop:~$ dig @192.0.2.10 www.example.com +norecurse

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> @192.0.2.10 www.example.com +norecurse
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 30762
;; flags: qr; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: ab20c6e566ce2d13010000006ab6a3bb71d088f054d63a40 (good)
;; QUESTION SECTION:
;www.example.com.               IN      A

;; AUTHORITY SECTION:
com.                    172800  IN      NS      a.gtld-servers.test.

;; ADDITIONAL SECTION:
a.gtld-servers.test.    86400   IN      A       192.0.2.20

;; Query time: 0 msec
;; SERVER: 192.0.2.10#53(192.0.2.10) (UDP)
;; WHEN: Fri Sep 25 13:39:23 -03 2026
;; MSG SIZE  rcvd: 124
```

`ANSWER: 0`, e a seção `AUTHORITY` dá o nome do servidor de `.com`, com o endereço dele em
`ADDITIONAL` para o resolver não ter de procurar isso também. O resolver percorre essa cadeia uma vez
e depois lembra de cada passo: a próxima pergunta sobre qualquer nome `.com` começa no passo 3.
