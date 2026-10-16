---
title: Os pedidos lentos, que a média esconde
version: 1
---

**Um percentil é o tempo abaixo do qual aquela fração dos pedidos terminou**: o p95 é 120
milissegundos quando 95 de cada cem pedidos levaram menos que isso. É o número a observar porque
descreve pessoas: numa página que faz dez pedidos, um atraso de um em cem é sentido por mais ou menos
uma visita em dez, e a média não diz nada sobre elas.

Os mesmos 600 pedidos mandados um por vez, quatro por vez e dezesseis por vez mostram o que a carga
faz com esses números:

```
ana@dev:~/ml$ for n in 1 4 16; do python load.py 600 $n; python latency.py 600; done
600 requests in 3.7 s, 163 a second; status {200: 407, 404: 193}
600 requests, 0 errors; status {200: 407, 404: 193}
mean    5.0 ms
p50     6.5 ms
p95     7.8 ms
p99    10.8 ms
max    29.0 ms
600 requests in 5.6 s, 107 a second; status {200: 407, 404: 193}
600 requests, 0 errors; status {200: 407, 404: 193}
mean   30.9 ms
p50    36.2 ms
p95    56.3 ms
p99    64.4 ms
max    72.1 ms
600 requests in 6.9 s, 88 a second; status {200: 407, 404: 193}
600 requests, 0 errors; status {200: 407, 404: 193}
mean  134.4 ms
p50   142.4 ms
p95   237.5 ms
p99   351.8 ms
max   406.6 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-latency\" aria-label=\"Barras agrupadas de latência para 600 pedidos com um, quatro e dezesseis ao mesmo tempo. Um por vez: p50 6,5, p95 7,8 e p99 10,8 milissegundos, 163 pedidos por segundo. Quatro: 36,2, 56,3 e 64,4, 107 por segundo. Dezesseis: 142,4, 237,5 e 351,8, 88 por segundo.\"><path d=\"M80.0 40.0 L80.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 240.0 L80.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M80.0 190.0 L700.0 190.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 190.0 L80.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M80.0 140.0 L700.0 140.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 140.0 L80.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><path d=\"M80.0 90.0 L700.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 90.0 L80.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300</text><path d=\"M80.0 40.0 L700.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 40.0 L80.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400</text><text x=\"80.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">milissegundos</text><rect x=\"121.3\" y=\"236.8\" width=\"37.2\" height=\"3.2\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"139.9\" y=\"227.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6,5</text><rect x=\"162.7\" y=\"236.1\" width=\"37.2\" height=\"3.9\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"181.3\" y=\"227.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7,8</text><rect x=\"204.0\" y=\"234.6\" width=\"37.2\" height=\"5.4\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"222.6\" y=\"225.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10,8</text><text x=\"183.3\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 por vez</text><text x=\"183.3\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">163 por segundo</text><rect x=\"328.0\" y=\"221.9\" width=\"37.2\" height=\"18.1\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"346.6\" y=\"212.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">36,2</text><rect x=\"369.3\" y=\"211.8\" width=\"37.2\" height=\"28.2\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"387.9\" y=\"202.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">56,3</text><rect x=\"410.7\" y=\"207.8\" width=\"37.2\" height=\"32.2\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"429.3\" y=\"198.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">64,4</text><text x=\"390.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4 por vez</text><text x=\"390.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">107 por segundo</text><rect x=\"534.7\" y=\"168.8\" width=\"37.2\" height=\"71.2\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"553.3\" y=\"159.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">142,4</text><rect x=\"576.0\" y=\"121.2\" width=\"37.2\" height=\"118.8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"594.6\" y=\"112.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">237,5</text><rect x=\"617.3\" y=\"64.1\" width=\"37.2\" height=\"175.9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.9\" y=\"55.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">351,8</text><text x=\"596.7\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">16 por vez</text><text x=\"596.7\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">88 por segundo</text><rect x=\"110.0\" y=\"52.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"128.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">p50</text><rect x=\"180.0\" y=\"52.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">p95</text><rect x=\"250.0\" y=\"52.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"268.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">p99</text><path d=\"M80.0 240.0 L700.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "Mais pedidos em voo não aumentaram a vazão; ela caiu, e o tempo que cada pedido passou esperando é o que os percentis cresceram."}
```

**Um por vez, o serviço responde em 6,5 milissegundos na mediana e 10,8 no p99.** Com quatro, a
mediana é 36,2; com dezesseis, 142,4, com o p99 em 351,8. E a vazão, que uma leitura ingênua espera
que suba com mais pedidos em voo, caiu: 163 por segundo, depois 107, depois 88.

**Os pedidos a mais não fizeram o serviço trabalhar mais rápido; fizeram cada um esperar mais.** Um
processo do Uvicorn roda Python, e o Python roda uma thread de código Python por vez, então as
predições do modelo são feitas em fila, não importa quantas cheguem juntas, e a troca entre threads
também custa alguma coisa. Passado o ponto em que o processo está ocupado o tempo todo, mais tráfego é
só fila, e o tempo que um pedido passa na fila é o que o p99 mede.

**O remédio é mais processos, e ele é pago em memória.** `uvicorn serve:app --workers 4` inicia
quatro cópias do serviço, cada uma com o seu modelo, então quatro predições rodam ao mesmo tempo em
quatro núcleos, e a memória que o serviço ocupa é multiplicada por quatro. A seção 09 mede quanto uma
cópia ocupa. E a latência que um serviço promete sempre vem com a carga em que foi medida: "p99 abaixo
de 15 ms" quer dizer uma coisa com um pedido por vez e outra bem diferente com dezesseis.
