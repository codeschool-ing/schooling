---
title: "A emenda: quanto custa o link"
version: 1
---

O link entre dois ambientes custa tempo e dinheiro, e o dinheiro **não é o mesmo nos dois sentidos**.
Aqui está a parte da tabela de preços do curso que trata disso: a lista pública de preços da AWS para
`sa-east-1` (São Paulo) e `us-east-1` (N. Virginia), em USD, sem impostos, nas versões de oferta que
ela imprime.

```
ana@laptop:~/cloud$ python3 prices.py transfer
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

Data transfer, USD per GB
  out to the internet, first 10 TB         0.1500       0.0900
  out to the internet, next 40 TB          0.1380       0.0850
  out to the internet, next 100 TB         0.1260       0.0700
  out to the internet, over 150 TB         0.1140       0.0500
  between zones, each direction            0.0100       0.0100
  to the other region                      0.1380       0.0200
  in from the internet                     0.0000       0.0000
```

A última linha é a primeira a notar. **Dado entrando da internet não custa nada**, nas duas regiões.
Dado saindo para a internet é cobrado por gigabyte, a um preço que cai conforme o volume do mês cresce.
Mover dados entre duas zonas de uma região custa 0,0100 USD por GB em cada sentido, e mandar de São
Paulo para outra região custa 0,1380 por GB. A lista não diz por que os sentidos são diferentes. O
efeito é bem claro: trazer dados é de graça, e levá-los embora é cobrado.

## Como uma faixa é contada

"Primeiros 10 TB, próximos 40 TB" dá para ler de dois jeitos. Ou o mês inteiro sai ao preço da faixa
em que ele termina, ou cada faixa cobra só os gigabytes que caem dentro dela. O próprio arquivo da
oferta resolve, e ele é público: isto baixa a oferta de transferência de dados de `sa-east-1`, na
versão que a tabela imprimiu, e lista as faixas da linha de saída para a internet.

```
ana@laptop:~/cloud$ curl -s -o dt.json https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSDataTransfer/20260916132208/sa-east-1/index.json
ana@laptop:~/cloud$ jq -r '(.products[] | select(.attributes.usagetype == "SAE1-DataTransfer-Out-Bytes") | .sku) as $s | [.terms.OnDemand[$s][].priceDimensions[]] | sort_by(.beginRange | tonumber)[] | [.beginRange, .endRange, .description] | join("  ")' dt.json
0  10240  $0.150 per GB - up to 10 TB / month data transfer out
10240  51200  $0.138 per GB - next 40 TB / month data transfer out
51200  153600  $0.126 per GB - next 100 TB / month data transfer out
153600  Inf  $0.114 per GB - greater than 150 TB / month data transfer out
```

As faixas estão em GB, e a primeira termina em `10240`, então **um TB nesta lista é 1.024 GB**. Cada
faixa tem o próprio preço, que é a segunda leitura: um gigabyte é cobrado pela faixa em que cai, e
passar de 10 TB não muda o preço dos primeiros 10.

## Cinquenta terabytes saindo de São Paulo

Uma empresa tira 50 TB de `sa-east-1` para o próprio datacenter por uma VPN, que passa pela internet,
em um mês. Passo a passo:

1. 50 TB são 50 × 1.024 = 51.200 GB.
2. Os primeiros 10.240 GB saem a 0,150: 10.240 × 0,150 = 1.536,00 USD.
3. O que sobra, 51.200 − 10.240 = 40.960 GB, cai na faixa dos 40 TB seguintes, que termina exatamente
   em 51.200. A 0,138: 40.960 × 0,138 = 5.652,48 USD.
4. O total é 1.536,00 + 5.652,48 = **7.188,48 USD**.

Os dois atalhos tentadores estão errados. Cobrar os 51.200 GB inteiros aos 0,150 da primeira faixa
dá 7.680,00; cobrar tudo a 0,138, a faixa em que o mês termina, dá 7.065,60.

A mesma conta, como um programa que percorre as faixas:

```schooling-example
{
  "language": "python",
  "file": "egress.py",
  "parts": [
    {
      "code": "import sys\n\n# sa-east-1, out to the internet, USD per GB, from `prices.py transfer`\nTIERS = [\n    (10 * 1024, 0.150),    # first 10 TB\n    (40 * 1024, 0.138),    # next 40 TB\n    (100 * 1024, 0.126),   # next 100 TB\n    (None, 0.114),         # over 150 TB\n]",
      "note": "As quatro linhas `out to the internet` da tabela para `sa-east-1`, cada uma com o tamanho da sua faixa em GB. A última faixa não tem fim, então o tamanho dela é `None`."
    },
    {
      "code": "tb = float(sys.argv[1])\nleft = tb * 1024           # the tiers are written in GB, 1,024 to a TB\ntotal = 0.0",
      "note": "O volume do mês em TB, vindo da linha de comando, convertido em GB do jeito que a lista de preços conta: `10240` é onde a primeira faixa termina, então aqui um TB é 1.024 GB."
    },
    {
      "code": "for size, price in TIERS:\n    gb = left if size is None else min(left, size)\n    if gb <= 0:\n        break",
      "note": "Percorre as faixas a partir da primeira. Cada uma pega no máximo o próprio tamanho do que sobrou, e o laço para quando não sobra nada."
    },
    {
      "code": "    cost = gb * price\n    print(f'{gb:>9,.0f} GB x {price:.3f} = {cost:>10,.2f}')\n    total += cost\n    left -= gb",
      "note": "**O preço vale só para os gigabytes que caem dentro da faixa.** Imprime a linha da faixa, soma no total e desconta esses gigabytes do que sobrou."
    },
    {
      "code": "print(f'{\"total\":>20} = {total:>10,.2f} USD')",
      "note": "A soma das faixas, alinhada embaixo delas."
    }
  ]
}
```

```
ana@laptop:~/cloud$ python3 egress.py 50
   10,240 GB x 0.150 =   1,536.00
   40,960 GB x 0.138 =   5,652.48
               total =   7,188.48 USD
ana@laptop:~/cloud$ python3 egress.py 200
   10,240 GB x 0.150 =   1,536.00
   40,960 GB x 0.138 =   5,652.48
  102,400 GB x 0.126 =  12,902.40
   51,200 GB x 0.114 =   5,836.80
               total =  25,927.68 USD
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um gráfico em degraus do preço da transferência de dados para a internet a partir de sa-east-1, em USD por GB, contra os terabytes enviados em um mês, de 0 a 200. O preço é 0,150 nos primeiros 10 TB, 0,138 até 50 TB, 0,126 até 150 TB e 0,114 dali em diante. A área sob os degraus até 50 TB está sombreada em dois blocos: 10.240 GB a 0,150, que dão 1.536,00 USD, e 40.960 GB a 0,138, que dão 5.652,48 USD, somando 7.188,48 USD. O tráfego que entra da internet tem preço zero e seria uma linha sobre o eixo de baixo.\"><defs><marker id=\"eg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"90\" y=\"62.5\" width=\"30\" height=\"187.5\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"77.49999999999997\" width=\"120\" height=\"172.50000000000003\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><path d=\"M90 40 L90 250 L700 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"82\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">USD por GB</text><text x=\"390.0\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">TB enviados para a internet em um mês</text><path d=\"M90 250 L90 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"90\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M120 250 L120 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"120\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M240 250 L240 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"240\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M540 250 L540 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"540\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150</text><path d=\"M690 250 L690 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"84\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M90 62.5 L120 62.5 L120 77.49999999999997 L240 77.49999999999997 L240 92.5 L540 92.5 L540 107.5 L690 107.5\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"84\" y=\"62.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.150</text><text x=\"180.0\" y=\"67.49999999999997\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.138</text><text x=\"390.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.126</text><text x=\"615.0\" y=\"97.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.114</text><text x=\"84\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1,536.00</text><text x=\"180\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5,652.48</text><path d=\"M240 37.49999999999997 L240 77.49999999999997\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"246\" y=\"37.49999999999997\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">50 TB saindo: 7.188,48 USD</text><text x=\"690\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">entrando da internet: 0,0000</text></svg>", "caption": "A conta é a área sob os degraus. Cada faixa cobra só os gigabytes que caem dentro dela, então passar de 10 TB não muda o preço dos primeiros 10; os 50 TB do exemplo são os dois blocos sombreados."}
```

Os mesmos 50 TB saindo de `us-east-1` dariam 10.240 × 0,090 + 40.960 × 0,085 = 921,60 + 3.481,60 =
4.403,20 USD. O formato da lista é o mesmo; a região muda todos os preços.

## Gravidade dos dados

O tempo é o outro custo. 51.200 GB são uns 409.600 gigabits, contando um GB como um bilhão de bytes e
oito bits por byte. Um link de 1 Gbit/s sem fazer mais nada move isso em 409.600 segundos, o que dá
**quase cinco dias**. Um conjunto de dados desse tamanho não se move por capricho, e ele cresce a cada
mês que fica onde está.

É isso que as pessoas querem dizer com **gravidade dos dados** (*data gravity*). Quando um grande
volume de dados mora num lugar, as aplicações que o usam são puxadas para perto dele, porque rodar o
processamento ao lado dos dados não custa nem tempo de transferência nem conta por gigabyte, enquanto
mover os dados custa as duas coisas. O primeiro grande conjunto de dados que uma empresa põe num lugar
costuma decidir onde as próximas aplicações vão rodar.

Para um desenho híbrido a regra prática vem daí: ponha o processamento do lado onde já estão os dados
que ele mais lê, e mande resultados pela emenda, não dados brutos. Um relatório de poucos megabytes
atravessando uma vez por noite custa uma fração de centavo; a tabela de onde ele saiu atravessando a
cada hora é a conta acima, de novo e de novo. O tempo de ida e volta também se soma a cada travessia,
e a aula 9 mede isso entre regiões.
