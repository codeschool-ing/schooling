---
title: Comparar e gravar
version: 1
---

Dois clientes que leem um valor, mudam e gravam de volta têm a corrida que a aula 8 encontrou com os
contadores. O `incr` resolve para números. Para qualquer outro valor, o Memcached dá a cada item um
**token CAS**, um número que muda toda vez que o item é gravado, e o `gets` o devolve como último campo
da linha `VALUE`:

```
ana@web:~$ printf 'set stock:2 0 0 1\r\n4\r\ngets stock:2\r\n' | nc -q1 127.0.0.1 11211
STORED
VALUE stock:2 0 1 6
4
END
```

O valor é 4 e o token é 6. Chame de estoque do livro 2; uma loja de verdade guarda estoque no banco, e
aqui ele só representa qualquer valor que dois clientes queiram mudar. Um cliente que vende um exemplar
grava 3 com `cas`, dizendo o token que leu, e **a gravação só dá certo se o token ainda for o que ele
leu**, o que quer dizer que ninguém gravou o item no meio do caminho:

```
ana@web:~$ t=$(printf 'gets stock:2\r\n' | nc -q1 127.0.0.1 11211 | awk 'NR==1{print $5}'); echo "token $t"; printf "cas stock:2 0 0 1 $t\r\n3\r\n" | nc -q1 127.0.0.1 11211; printf "cas stock:2 0 0 1 $t\r\n3\r\n" | nc -q1 127.0.0.1 11211
token 6
STORED
EXISTS
ana@web:~$ printf 'get stock:2\r\n' | nc -q1 127.0.0.1 11211
VALUE stock:2 0 1
3
END
```

O primeiro `cas` guardou 3, e guardar mudou o token. O segundo usou o mesmo token velho, como faria um
segundo cliente que tivesse lido o estoque no mesmo instante, e recebeu `EXISTS`: alguém gravou antes.
Esse cliente lê de novo, encontra 3 e grava 2. **Nada foi travado e nenhuma venda se perdeu**; o cliente
que perdeu a corrida fez o trabalho duas vezes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 320\" role=\"img\" aria-label=\"Três colunas: cliente A, Memcached e cliente B. 1 e 2: os dois clientes leem o valor 4 com token 6. 3: A grava 3 dizendo o token 6 e recebe STORED, e o token muda. 4: B grava 3 dizendo o token 6 e recebe EXISTS. 5: B lê de novo e recebe 3 com o token novo. 6: B grava 2 com o token novo e recebe STORED.\"><defs><marker id=\"fcas-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"10\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente A</text><rect x=\"280\" y=\"10\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">memcached</text><rect x=\"520\" y=\"10\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente B</text><line x1=\"110\" y1=\"44\" x2=\"110\" y2=\"310\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"350\" y1=\"44\" x2=\"350\" y2=\"310\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"590\" y1=\"44\" x2=\"590\" y2=\"310\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"350\" y1=\"75\" x2=\"113\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fcas-ah)\"></line><text x=\"230.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1. 4, token 6</text><line x1=\"350\" y1=\"110\" x2=\"587\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fcas-ah)\"></line><text x=\"470.0\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2. 4, token 6</text><line x1=\"110\" y1=\"150\" x2=\"347\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fcas-ah)\"></line><text x=\"230.0\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3. cas 3 com 6: STORED</text><line x1=\"590\" y1=\"190\" x2=\"353\" y2=\"190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#fcas-ah)\"></line><text x=\"470.0\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">4. cas 3 com 6: EXISTS</text><line x1=\"350\" y1=\"230\" x2=\"587\" y2=\"230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fcas-ah)\"></line><text x=\"470.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5. 3, token novo</text><line x1=\"590\" y1=\"270\" x2=\"353\" y2=\"270\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fcas-ah)\"></line><text x=\"470.0\" y=\"261\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">6. cas 2 com ele: STORED</text><text x=\"350\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o token mudou no passo 3</text></svg>", "caption": "Os dois clientes leem o mesmo token. A primeira gravação o muda, então a segunda é recusada e aquele cliente recomeça com uma leitura nova.", "same": ["memcached", "1. 4, token 6", "2. 4, token 6"]}
```

O `cas` é otimista. Não custa nada quando não há conflito e custa uma nova tentativa quando há, o que
serve para um valor que dois clientes raramente gravam no mesmo instante. Um valor que todo mundo grava
o tempo todo, um contador de visualizações por exemplo, pertence ao `incr`, que nunca precisa tentar de
novo.
