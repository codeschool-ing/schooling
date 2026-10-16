---
title: Um teste de estresse
version: 1
---

Um teste de estresse aumenta a carga até algo ceder, para achar duas coisas: **onde está o limite**,
e **o que quebra primeiro**. A segunda costuma ser a mais útil, porque costuma não ser o que alguém
esperava.

Uma cópia da bilheteria, e quatro execuções de quinze segundos a 100, 200, 300 e 400 vendas por
segundo:

```
ana@lab:~/tickets$ for rate in 100 200 300 400; do docker run --rm -i --network host grafana/k6:2.3.0 run -q --log-output=none -e RATE=$rate -e DURATION=15s - < sale.js; echo; done
asked     100 a second for 15s
answered  1501 = 99.8 a second
latency   p50 38.2 ms  p95 48.1 ms  p99 56.2 ms  max 67.4 ms
sold 1501  refused 0  failed 0  never sent 0

asked     200 a second for 15s
answered  2973 = 189.3 a second
latency   p50 272.1 ms  p95 959.4 ms  p99 1281.4 ms  max 2549.9 ms
sold 2820  refused 153  failed 0  never sent 28

asked     300 a second for 15s
answered  4334 = 259.7 a second
latency   p50 577.8 ms  p95 2789.1 ms  p99 4275.1 ms  max 7922.7 ms
sold 2593  refused 194  failed 1547  never sent 166

asked     400 a second for 15s
answered  5828 = 354.6 a second
latency   p50 2.4 ms  p95 2571.0 ms  p99 3616.7 ms  max 6882.1 ms
sold 2695  refused 156  failed 2977  never sent 172

ana@lab:~/tickets$ docker compose logs lb --no-log-prefix | grep -m1 alert
2026/10/16 00:40:17 [alert] 20#20: 512 worker_connections are not enough
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Vendas por segundo pedidas contra vendas por segundo respondidas, com 100, 200, 300 e 400 pedidas. As respondidas acompanham as pedidas em 100 e 200, e então se afastam: 189 com 200 pedidas, 260 com 300 e 355 com 400. Ao lado de cada ponto, a fração que falhou: nenhuma em 100 e 200, 36 por cento em 300, 51 por cento em 400.\"><path d=\"M90 220 L650 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M90 220 L90 40\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M90.0 220.0 L650.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"552.0\" y=\"52.599999999999994\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">respondido = pedido</text><path d=\"M 230.0 175.1 L 370.0 134.8 L 510.0 103.1 L 650.0 60.4\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"230.0\" cy=\"175.09\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"238.0\" y=\"189.09\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0% falharam</text><circle cx=\"370.0\" cy=\"134.815\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"378.0\" y=\"148.815\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0% falharam</text><circle cx=\"510.0\" cy=\"103.135\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"518.0\" y=\"117.135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">36% falharam</text><circle cx=\"650.0\" cy=\"60.42999999999998\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"658.0\" y=\"74.42999999999998\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">51% falharam</text><text x=\"90.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"82\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"230.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><text x=\"82\" y=\"175.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><text x=\"370.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><text x=\"82\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><text x=\"510.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300</text><text x=\"82\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300</text><text x=\"650.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">400</text><text x=\"82\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">400</text><text x=\"650\" y=\"252\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedido, por segundo</text><text x=\"96\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">respondido, por segundo</text></svg>", "caption": "Depois do joelho, o respondido para de acompanhar o pedido, e boa parte do que é respondido é falha."}
```

Leia execução por execução.

- **100 por segundo**: toda venda respondida na taxa pedida, mediana de 38 ms. Confortável.
- **200 por segundo**: o k6 conseguiu 189 por segundo. A mediana subiu para 272 ms e o percentil 95
  para 959 ms, e o descarte de carga da aula 9 recusou 153 vendas com `503`. **Esse é o joelho**: em
  algum ponto abaixo de 200 por segundo, esta cópia nesta máquina deixa de acompanhar. A sua máquina
  vai pô-lo em outro lugar; a forma vai ser a mesma.
- **300 por segundo**: agora 1547 vendas **falharam**, nem vendidas nem recusadas. Isso é novo, e
  nada nos logs da bilheteria explicaria, porque a bilheteria nunca as viu.
- **400 por segundo**: 2977 falharam, e a **mediana caiu para 2,4 ms**. Não porque algo ficou mais
  rápido: as falhas foram instantâneas, e entram na latência como todo o resto. Uma mediana que
  melhora enquanto a contagem de erros sobe é motivo para ler a contagem de erros primeiro.

O último comando acha as falhas no log do nginx: **`512 worker_connections are not enough`**. O padrão
do nginx permite a cada processo trabalhador 512 conexões, contando os dois lados: a conexão do
comprador chegando e a conexão saindo para a bilheteria. Com centenas de vendas esperando na
bilheteria ao mesmo tempo, o nginx esgotou as suas, e fechou conexões novas sem resposta.

**A primeira coisa a quebrar não foi a bilheteria.** Foi um padrão do balanceador de carga que
ninguém tinha tocado desde a aula 1, porque nada antes desta aula tinha mandado mais que algumas
centenas de conexões de uma vez.
