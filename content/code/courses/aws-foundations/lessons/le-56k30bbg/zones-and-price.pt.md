---
title: Atravessar zonas, e quanto custa um balanceador
version: 1
---

**Um balanceador de carga não é uma máquina só.** A AWS roda um pedaço dele, um **nó**, em cada zona
em que você deu a ele uma sub-rede. O nome `shop-web-1.sa-east-1.elb.amazonaws.com` responde com os
endereços de todos os nós. Cada chamador cai num nó. A pergunta desta seção é o que esse nó faz em
seguida: mandar só para alvos da própria zona, ou para alvos de todas as zonas. Essa escolha é o **balanceamento
entre zonas** (*cross-zone load balancing*), e ela decide tanto o quão por igual a carga se espalha
quanto se o preço de atravessar uma zona, da lição 1, aparece na fatura.

## Quando as zonas são desiguais

A imagem errada é que um balanceador divide as requisições por igual entre os alvos. Ele as divide
por igual entre os **nós**, porque o DNS entrega os endereços dos nós em rodízio. O que cada nó faz
com a sua parte depende da configuração. Ponha dois alvos em `sa-east-1a` e oito em `sa-east-1b`:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l22-cross-zone\" aria-label=\"Balanceamento entre zonas, com dois alvos em sa-east-1a e oito em sa-east-1b. Cada zona tem um nó do balanceador, e cada nó recebe metade do tráfego. À esquerda, entre zonas desligado: cada nó manda só para a própria zona, então os dois alvos em sa-east-1a carregam 25% cada e os oito em sa-east-1b 6,25% cada. À direita, entre zonas ligado: cada nó manda para todo alvo, e os dez carregam 10% cada.\"><defs><marker id=\"l22-cross-zone-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l22-cross-zone-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l22-cross-zone-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"185.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">entre zonas desligado</text><rect x=\"20.0\" y=\"44.0\" width=\"110.0\" height=\"236.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"41.0\" y=\"76.0\" width=\"68.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nó: 50%</text><rect x=\"31.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"51.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">25%</text><rect x=\"79.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"99.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">25%</text><rect x=\"150.0\" y=\"44.0\" width=\"200.0\" height=\"236.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"216.0\" y=\"76.0\" width=\"68.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nó: 50%</text><rect x=\"158.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6,25%</text><rect x=\"206.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"226.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6,25%</text><rect x=\"254.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"274.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6,25%</text><rect x=\"302.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"322.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6,25%</text><rect x=\"158.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6,25%</text><rect x=\"206.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"226.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6,25%</text><rect x=\"254.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"274.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6,25%</text><rect x=\"302.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"322.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6,25%</text><path d=\"M75.0 106.0 L75.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\" marker-end=\"url(#l22-cross-zone-af-ah-amber)\"></path><path d=\"M250.0 106.0 L250.0 166.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l22-cross-zone-af-ah-paper-dim)\"></path><text x=\"535.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">entre zonas ligado</text><rect x=\"370.0\" y=\"44.0\" width=\"110.0\" height=\"236.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"391.0\" y=\"76.0\" width=\"68.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nó: 50%</text><rect x=\"381.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"401.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"429.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"449.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"500.0\" y=\"44.0\" width=\"200.0\" height=\"236.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"566.0\" y=\"76.0\" width=\"68.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nó: 50%</text><rect x=\"508.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"528.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"556.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"576.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"604.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"624.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"652.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"672.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"508.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"528.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"556.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"576.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"604.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"624.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"652.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"672.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><path d=\"M425.0 106.0 L425.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l22-cross-zone-af-ah-phosphor)\"></path><path d=\"M600.0 106.0 L600.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l22-cross-zone-af-ah-phosphor)\"></path><path d=\"M450.0 104.0 L490.0 134.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M490.0 134.0 L538.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l22-cross-zone-af-ah-phosphor)\"></path><path d=\"M566.0 104.0 L490.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M490.0 140.0 L442.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l22-cross-zone-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">cada nó recebe metade do tráfego; a configuração decide para onde ele pode mandar</text></svg>", "caption": "Desligado, uma zona carrega metade da carga por menos alvos que tenha. Ligado, a carga segue os alvos."}
```

**Com o balanceamento entre zonas desligado, cada zona recebe metade do tráfego, tenha o que
tiver**. As duas máquinas de `sa-east-1a` carregam um quarto cada, e as oito de `sa-east-1b` um
oitavo de metade, 6,25% cada. As duas vão estar sobrecarregadas muito antes de as oito ficarem
ocupadas. Com ele ligado, todo nó espalha por todo alvo e cada um dos dez carrega 10%. O outro jeito
de resolver é manter as zonas iguais. Um grupo de auto scaling espalhado pelas mesmas zonas faz
isso, e a lição 4 do `aws-compute` constrói um.

## A configuração, por tipo

| | entre zonas por padrão | dá para desligar | atravessar uma zona, do LB ao alvo |
|---|---|---|---|
| application | ligado | por grupo de alvos, não para o ALB inteiro | não cobrado |
| network | desligado | liga e desliga, por LB ou por grupo de alvos | cobrado, como a lição 1 precificou |
| gateway | desligado | liga e desliga | cobrado, como a lição 1 precificou |

A tabela é o comportamento documentado da AWS. Pergunte ao moto sobre o ALB e o NLB que esta lição
criou:

```
ana@laptop:~/aws$ nlb=$(aws elbv2 describe-load-balancers --names shop-tcp --query "LoadBalancers[0].LoadBalancerArn" --output text)
ana@laptop:~/aws$ aws elbv2 describe-load-balancer-attributes --load-balancer-arn $lb --query "Attributes[?Key=='load_balancing.cross_zone.enabled'].Value" --output text
false
ana@laptop:~/aws$ aws elbv2 describe-load-balancer-attributes --load-balancer-arn $nlb --query "Attributes[?Key=='load_balancing.cross_zone.enabled'].Value" --output text
false
```

**O moto informa `false` para os dois, e para o ALB isso está errado**. Um ALB sempre balanceia
entre zonas no nível do balanceador. O que pode ser desligado é a mesma configuração num dos grupos
de alvos dele. Para o NLB, `false` é o padrão verdadeiro, e ligá-lo é uma chamada:

```
ana@laptop:~/aws$ aws elbv2 modify-load-balancer-attributes --load-balancer-arn $nlb --attributes Key=load_balancing.cross_zone.enabled,Value=true --query "Attributes[?Key=='load_balancing.cross_zone.enabled'].Value" --output text
true
```

**Num NLB, essa chamada tem preço.** Com os alvos espalhados por igual em duas zonas, cerca de
metade do que cada nó repassa atravessa para a outra zona. A lição 1 leu essa travessia a 0,01 dólar
o gigabyte ao sair de uma zona mais 0,01 ao chegar na outra. Um NLB que repassa 2 TB por mês com o
balanceamento entre zonas ligado manda cerca de 1.024 GB para o outro lado, então 1.024 × 0,02 = **20,48
dólares por mês** só pela travessia. A travessia do ALB não é cobrada, o que a página de preços da
AWS diz e as linhas de transferência da lista de preços não mostram. Então o padrão do NLB é uma
escolha entre uma carga por igual e uma fatura menor. A resposta certa muitas vezes é deixar o
balanceamento entre zonas desligado e as zonas iguais.

## A lista de preços

Os balanceadores têm uma oferta própria, `AWSELB`, com 16 kilobytes para São Paulo. A oferta do EC2
de onde o curso `cloud` leu a mesma linha tem cerca de 290 megabytes, e as duas dizem 0,0340 pela
hora de um ALB. Peça ao `price.py` os dois tipos de uso que importam:

```
ana@laptop:~/aws$ python3 price.py AWSELB 20260911124544 sa-east-1 SAE1-LoadBalancerUsage SAE1-LCUUsage
AWSELB 20260911124544, published 2026-09-11, USD
SAE1-LoadBalancerUsage
          0 to       Inf Hrs  0.0189
          0 to       Inf Hrs  0.0340
          0 to       Inf Hrs  0.0340
          0 to       Inf Hrs  0.0340
SAE1-LCUUsage
          0 to       Inf LCU-Hrs 0.0055
          0 to       Inf LCU-Hrs 0.0083
          0 to       Inf LCU-Hrs 0.0110
```

**Quatro preços sob um nome, e três sob o outro, sem nada que diga qual é qual**. As quatro casas
decimais também transformaram um deles, 0,00825, em `0.0083`. Um tipo de uso nem sempre é único
dentro de uma oferta: o mesmo `SAE1-LoadBalancerUsage` é a hora de um balanceador Classic, de um
application, de um network e de um gateway. O que os separa é outro atributo do produto, a **operação**
(*operation*). Este programa curto a imprime ao lado de cada preço. Salve-o como `~/aws/ops.py`:

```python
#!/usr/bin/env python3
"""Prints each price of a usage type beside the operation it is charged for.

    python3 ops.py OFFER VERSION REGION USAGETYPE...

Reads the offer price.py has already downloaded into ~/.cache/aws-prices.
"""
import json
import os
import sys

code, version, region, *usages = sys.argv[1:]
path = os.path.expanduser(f'~/.cache/aws-prices/{code}-{version}-{region}.json')
with open(path) as f:
    doc = json.load(f)
for usage in usages:
    rows = []
    for sku, product in doc['products'].items():
        a = product['attributes']
        if a.get('usagetype') == usage:
            for term in doc['terms']['OnDemand'].get(sku, {}).values():
                for d in term['priceDimensions'].values():
                    rows.append((a.get('operation', ''), float(d['pricePerUnit']['USD']), d['unit']))
    print(usage)
    for operation, price, unit in sorted(rows):
        print(f'  {operation:<26} {price:.5f} per {unit}')
```

```
ana@laptop:~/aws$ python3 ops.py AWSELB 20260911124544 sa-east-1 SAE1-LoadBalancerUsage SAE1-LCUUsage
SAE1-LoadBalancerUsage
  LoadBalancing              0.03400 per Hrs
  LoadBalancing:Application  0.03400 per Hrs
  LoadBalancing:Gateway      0.01890 per Hrs
  LoadBalancing:Network      0.03400 per Hrs
SAE1-LCUUsage
  LoadBalancing:Application  0.01100 per LCU-Hrs
  LoadBalancing:Gateway      0.00550 per LCU-Hrs
  LoadBalancing:Network      0.00825 per LCU-Hrs
```

`LoadBalancing` sozinho é o balanceador Classic; os outros três nomeiam o seu tipo. Na lista que a AWS
publicou em **11 de setembro de 2026**, em São Paulo:

| | por hora | por unidade de capacidade-hora |
|---|---|---|
| application | 0,034 | 0,011 (LCU) |
| network | 0,034 | 0,00825 (NLCU) |
| gateway | 0,0189 | 0,0055 (GLCU) |

## Dois medidores rodando ao mesmo tempo

**Um balanceador é cobrado pela hora em que existe e pelo trabalho que faz**, e o segundo medidor é o
que surpreende. Uma **unidade de capacidade** é um pacote de trabalho, e uma hora é cobrada pela
maior das suas dimensões. A página de preços da AWS, não a lista, as define. Num ALB, uma LCU é até 25 conexões novas por
segundo, 3.000 conexões ativas por minuto, 1 GB processado na hora para alvos que são máquinas, ou
1.000 avaliações de regra por segundo. A unidade de um NLB é maior em conexões, 800 conexões TCP novas
por segundo e 100.000 ativas, com o mesmo 1 GB.

O ALB da loja num mês de 730 horas, processando cerca de 2 GB por hora:

- as horas: 730 × 0,034 = **24,82 dólares**, visite alguém ou não;
- o trabalho: os bytes são a maior dimensão, então 2 LCU por hora, 2 × 730 × 0,011 = **16,06
  dólares**;
- juntos, **40,88 dólares por mês**, antes dos bytes que ele manda para a internet, que são os 0,15
  por gigabyte de São Paulo da lição 1 e a maior linha quando a loja estiver movimentada.

**O medidor de horas é o motivo de um balanceador deixado ligado ser a cobrança esquecida de
sempre**: 24,82 dólares por mês por um que não atende ninguém, que é o aviso que a lição 1 deu para
uma conta real. O moto não cobrou nada pelos três que esta lição criou, e a AWS cobraria pelos três
desde o minuto em que cada um foi criado. Numa conta real, apague-os no mesmo dia, quando a lição
acabar.
