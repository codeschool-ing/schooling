---
title: Quanto custa atravessar uma fronteira
version: 1
---

**Dentro do Google Cloud, o dado é cobrado pelas fronteiras que atravessa.** Para dentro do Google
Cloud, vindo da internet, é grátis. Entre duas máquinas na mesma zona, pelos endereços internos, é
grátis. Todo o resto tem preço por gibibyte, e o preço depende de **qual fronteira, e a partir de
onde**. É a linha da fatura que ninguém previu, porque ela não está presa a máquina nenhuma: está presa
às setas entre elas.

## Os preços, e o dia em que foram lidos

O Google publica os preços de rede numa página pública, `cloud.google.com/vpc/network-pricing`, que se
lê sem conta. Ao contrário da AWS, ele não publica um arquivo de preços que um programa possa baixar sem
chave: o catálogo legível por máquina, a Cloud Billing Catalog API, pede uma chave de API, e uma chave
de API pertence a um projeto. Então os números abaixo foram **lidos nessa página em 30 de outubro de
2026**, e são da página, não de um programa. Um preço é um fato com data; confira a página antes de
citar um para alguém.

| travessia | preço por GiB, USD |
|---|---|
| entre duas VMs na mesma zona, por endereço interno | grátis |
| entre duas zonas de uma região | 0,01 |
| entre duas regiões da América do Norte | 0,02 |
| de uma região da América do Sul para qualquer outra região, Santiago inclusive | 0,14 |
| para dentro do Google Cloud, vindo da internet | grátis |

**A linha da América do Sul é a surpresa.** Todo outro continente cobra menos para ficar em casa do que
para sair: América do Norte para América do Norte é 0,02, Europa para Europa 0,02. De São Paulo, o
preço é 0,14 para onde quer que o dado vá, seja Santiago ao lado, seja Iowa. Para um projeto que
replica entre duas regiões sul-americanas, isso é sete vezes o que o mesmo projeto custa nos Estados
Unidos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-crossings\" aria-label=\"Quanto custa atravessar cada fronteira, lido na página de preços de rede do Google em 30 de outubro de 2026, em dólares por GiB. Dentro de southamerica-east1, duas zonas. Entre duas máquinas na mesma zona, por endereço interno: grátis. Entre as duas zonas: 0,01. De São Paulo para Santiago, southamerica-west1: 0,14. De São Paulo para Iowa, us-central1: também 0,14. De Iowa para a Carolina do Sul, us-east1, para comparar: 0,02. Da internet para dentro: grátis.\"><defs><marker id=\"l01-crossings-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-crossings-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"300.0\" height=\"200.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"170.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">southamerica-east1</text><rect x=\"40.0\" y=\"78.0\" width=\"120.0\" height=\"140.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">zone a</text><rect x=\"180.0\" y=\"78.0\" width=\"120.0\" height=\"140.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">zone b</text><rect x=\"52.0\" y=\"126.0\" width=\"36.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">VM</text><rect x=\"112.0\" y=\"126.0\" width=\"36.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">VM</text><rect x=\"192.0\" y=\"126.0\" width=\"36.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">VM</text><path d=\"M88.0 140.0 L112.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"100.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">grátis</text><path d=\"M148.0 150.0 L192.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-amber)\" marker-start=\"url(#l01-crossings-af-ah-amber)\"></path><text x=\"170.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">0.01</text><rect x=\"470.0\" y=\"40.0\" width=\"230.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"585.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">southamerica-west1 (Santiago)</text><rect x=\"470.0\" y=\"120.0\" width=\"230.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"585.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">us-central1 (Iowa)</text><path d=\"M322.0 100.0 L466.0 62.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-amber)\"></path><text x=\"394.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">0.14</text><path d=\"M322.0 140.0 L466.0 142.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-amber)\"></path><text x=\"394.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">0.14</text><rect x=\"470.0\" y=\"200.0\" width=\"230.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"585.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">us-east1 (Carolina do Sul)</text><path d=\"M600.0 166.0 L600.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-crossings-af-ah-paper-dim)\"></path><text x=\"612.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.02</text><text x=\"170.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">da internet para dentro: grátis</text><text x=\"585.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">USD por GiB, lido em 30 de outubro de 2026</text></svg>", "caption": "De São Paulo, a região vizinha custa o mesmo que outro continente.", "same": ["southamerica-west1 (Santiago)", "us-central1 (Iowa)"]}
```

O tráfego para a internet tem uma tabela própria, com preço pela região de onde o dado sai e pelo
continente onde chega, e um **Standard Tier** mais barato para o tráfego que pode viajar pela internet
pública em vez da rede do Google. A página desenha essa tabela por região, atrás de um seletor, e este
curso não cita número nenhum dela.

## Um programa que faz a conta

O programa abaixo guarda os quatro preços da tabela e transforma um volume mensal numa fatura mensal. É
o tipo de coisa que vale guardar ao lado de um documento de projeto: quando alguém pergunta quanto custa
espalhar um sistema por duas regiões, a resposta é um comando. Salve-o como `~/gcp/cost.py`.

```schooling-example
{"language": "python", "file": "cost.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"What a month of traffic across one boundary costs, at prices read by hand.\n\n    python3 cost.py GIB CROSSING\n\nCROSSING is zone, region, continent or us-region. The prices were read off\ncloud.google.com/vpc/network-pricing on 2026-10-30, in USD per GiB.\n\"\"\"\nimport sys\n\n", "note": "Para que serve o programa, e de onde vêm os números dele. A data faz parte do preço: um número sem data não pode ser conferido com a página."}, {"code": "READ_ON = '2026-10-30'\nPRICES = {\n    'zone': ('between two zones of southamerica-east1', 0.01),\n    'region': ('southamerica-east1 to southamerica-west1', 0.14),\n    'continent': ('southamerica-east1 to us-central1', 0.14),\n    'us-region': ('us-central1 to us-east1', 0.02),\n}\n\n", "note": "Quatro travessias, cada uma com a frase que diz de que seta se trata. A última está ali para comparar: o mesmo tipo de travessia, em outro continente."}, {"code": "gib, crossing = float(sys.argv[1]), sys.argv[2]\nwhat, price = PRICES[crossing]\nprint(f'{gib:,.0f} GiB {what}')\nprint(f'  {price:.2f} USD per GiB, read {READ_ON}')\nprint(f'  {gib * price:,.2f} USD a month')\n", "note": "A conta é uma multiplicação. O que o programa acrescenta é que ninguém a faz de memória, e que a data viaja junto com a resposta."}]}
```

Uma equipe manda 500 GiB por mês entre as partes de um sistema. Eis esse volume atravessando cada
fronteira:

```
ana@laptop:~/gcp$ python3 cost.py 500 zone
500 GiB between two zones of southamerica-east1
  0.01 USD per GiB, read 2026-10-30
  5.00 USD a month
ana@laptop:~/gcp$ python3 cost.py 500 region
500 GiB southamerica-east1 to southamerica-west1
  0.14 USD per GiB, read 2026-10-30
  70.00 USD a month
ana@laptop:~/gcp$ python3 cost.py 500 continent
500 GiB southamerica-east1 to us-central1
  0.14 USD per GiB, read 2026-10-30
  70.00 USD a month
ana@laptop:~/gcp$ python3 cost.py 500 us-region
500 GiB us-central1 to us-east1
  0.02 USD per GiB, read 2026-10-30
  10.00 USD a month
```

Os mesmos 500 GiB custam **5 dólares por mês entre duas zonas e 70 entre duas regiões**, e trocar a
segunda região de Santiago para Iowa não muda nada. Entre duas regiões dos Estados Unidos custariam 10.
São esses os números a levar para a conversa sobre se um sistema precisa de uma segunda região, e eles
dizem que em São Paulo responder sim a essa pergunta sai mais caro.

**O que o programa não sabe** é tudo o mais que a página cobra além da travessia: a máquina que manda o
dado, o balanceador de carga por onde ele passa, o gateway de NAT da lição 17. Cada um tem um preço
próprio, e a lição 13 lê uma fatura em que eles aparecem juntos.
