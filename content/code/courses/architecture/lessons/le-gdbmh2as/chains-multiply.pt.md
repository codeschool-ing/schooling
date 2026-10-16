---
title: Falhas sobem pela cadeia
version: 1
---

A latência soma ao longo de uma cadeia. **A disponibilidade multiplica.** Se o checkout precisa do preço
e o preço precisa do estoque, o checkout só consegue responder nos momentos em que os três estão de pé,
e a chance disso é o produto das chances separadas.

| cada serviço de pé | cadeia de 3 | cadeia de 5 | cadeia de 10 |
| --- | --- | --- | --- |
| 99,9% | 99,7% | 99,5% | 99,0% |
| 99% | 97,0% | 95,1% | 90,4% |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Um gráfico da disponibilidade de uma cadeia contra o número de serviços nela, de um a dez. Com cada serviço em 99,9%, a cadeia cai devagar, para cerca de 99,0% com dez serviços. Com cada um em 99%, cai rápido, para cerca de 90,4% com dez.\"><defs><marker id=\"l5-avail-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M80 240 L680 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-avail-ah-wire)\"></path><path d=\"M80 240 L80 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-avail-ah-wire)\"></path><text x=\"72\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">90%</text><text x=\"72\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">95%</text><text x=\"72\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100%</text><text x=\"80.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"337.8\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"660.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"370\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">serviços na cadeia</text><path d=\"M80.0 42.0 L144.4 44.0 L208.9 46.0 L273.3 48.0 L337.8 50.0 L402.2 52.0 L466.7 54.0 L531.1 55.9 L595.6 57.9 L660.0 59.9\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"80.0\" cy=\"42.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"144.4\" cy=\"44.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"208.9\" cy=\"46.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"273.3\" cy=\"48.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"337.8\" cy=\"50.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"402.2\" cy=\"52.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"466.7\" cy=\"54.0\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"531.1\" cy=\"55.9\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"595.6\" cy=\"57.9\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"660.0\" cy=\"59.9\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><path d=\"M80.0 60.0 L144.4 79.8 L208.9 99.4 L273.3 118.8 L337.8 138.0 L402.2 157.0 L466.7 175.9 L531.1 194.5 L595.6 213.0 L660.0 231.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"80.0\" cy=\"60.0\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"144.4\" cy=\"79.8\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"208.9\" cy=\"99.4\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"273.3\" cy=\"118.8\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"337.8\" cy=\"138.0\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"402.2\" cy=\"157.0\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"466.7\" cy=\"175.9\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"531.1\" cy=\"194.5\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"595.6\" cy=\"213.0\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"660.0\" cy=\"231.2\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"560\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">cada 99,9%: 99,0% com dez</text><text x=\"230\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cada 99%: 90,4% com dez</text></svg>", "caption": "A disponibilidade se multiplica ao longo de uma cadeia síncrona. Dez serviços a 99% cada dão uma cadeia fora do ar quase uma hora em cada dez."}
```

Um mês tem cerca de 720 horas. Um serviço a 99,9% fica fora do ar uns 43 minutos delas; uma cadeia de
dez serviços assim, umas sete horas. **Cada dependência síncrona que você acrescenta é uma fatia do tempo
fora do ar de outra pessoa somada ao seu.** Os números supõem que os serviços falham de forma
independente, o que é otimista: serviços que dividem um banco, uma rede ou um deploy tendem a cair
juntos.

## Vendo acontecer

Pare o serviço no fim da cadeia e pergunte ao checkout:

```
ana@vm:~/lab/chain$ docker compose stop stock
 Container chain-stock-1 Stopping 
 Container chain-stock-1 Stopped 
ana@vm:~/lab/chain$ curl -s -w "%{http_code}\n" localhost:8000/
{"name": "checkout", "error": "http://pricing:8000/ answered 502", "next": {"name": "pricing", "error": "http://stock:8000/ unreachable: <urlopen error [Errno -2] Name or service not known>", "took_ms": 102}, "took_ms": 206}
502
```

O estoque está fora do ar, e **nada no checkout está errado**, mas o checkout responde `502`. O preço
não alcançou o estoque e disse isso; o checkout recebeu o erro do preço e disse isso por sua vez,
levando a resposta do preço dentro da sua. Cada elo relatou com honestidade, e a requisição falhou no
topo por um motivo lá embaixo. Num sistema de verdade quem lê o erro do checkout tem de descer a cadeia
para achar a causa, e é para isso que servem o id de requisição da aula 2 e os traces de `scale`.

Inicie o estoque de novo:

```
ana@vm:~/lab/chain$ docker compose start stock
 Container chain-stock-1 Starting 
 Container chain-stock-1 Started 
```

## Três jeitos de encurtar a multiplicação

- **Menos saltos**: pergunte se o preço precisa mesmo do estoque neste caminho, ou se o checkout pode
  perguntar aos dois, em paralelo, e decidir ele mesmo.
- **Uma alternativa**: quando o estoque não responde, o preço poderia cotar a cesta e marcar a
  disponibilidade como desconhecida, em vez de falhar a requisição inteira. Nem toda dependência
  permite; um pagamento não permite.
- **Não esperar de jeito nenhum**: se quem chama não precisa da resposta agora, não precisa que o outro
  lado esteja de pé agora. É o estilo assíncrono, duas seções adiante.
