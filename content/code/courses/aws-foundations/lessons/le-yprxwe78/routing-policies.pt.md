---
title: Verificações de saúde e políticas de roteamento
version: 1
---

**Uma política de roteamento decide qual dos vários registros de um nome um resolvedor recebe.**
Todo registro até aqui teve o roteamento padrão, **simples**: um conjunto de registros, todos os
valores dele, a mesma resposta para todo mundo. As outras seis políticas deixam um nome guardar
vários conjuntos de registros, distinguidos por um `SetIdentifier`, e escolhem entre eles no momento
de cada pergunta. A imagem errada é que o Route 53 fica no caminho do tráfego e o conduz. **Ele não
conduz nada.** Ele escolhe uma resposta, a resposta fica em cache pelo TTL dela, e o tráfego vai para
onde a resposta disse.

## As sete políticas

| política | escolhe por | um uso na loja |
|---|---|---|
| simples (*simple*) | nada: uma resposta | o servidor de e-mail |
| ponderada (*weighted*) | um peso por registro, em proporção | mandar um pedido de busca em dez para o cluster de busca novo |
| latência (*latency*) | a região da AWS com a menor latência medida até quem pergunta | São Paulo para o Brasil, Virgínia para a América do Norte |
| failover | uma verificação de saúde: o primário enquanto saudável, o secundário fora disso | a API em São Paulo, uma reserva na Virgínia |
| geolocalização (*geolocation*) | o continente, o país ou o estado americano de quem pergunta, pelo endereço do resolvedor | uma página em português para o Brasil, em espanhol para a Argentina |
| geoproximidade (*geoproximity*) | a distância até cada recurso, com um viés que você ajusta para aumentar ou diminuir a fatia dele | mover tráfego entre regiões aos poucos |
| múltiplos valores (*multivalue*) | até oito registros saudáveis, escolhidos ao acaso | vários servidores, cada um com a sua verificação de saúde |

Duas delas são fáceis de confundir. **Latência é sobre a rede**, medida pela AWS entre as regiões e
os lugares de onde as pessoas perguntam. **Geolocalização é sobre onde quem pergunta está**, diga a
rede o que disser, e é com isso que uma lei ou uma licença se importa. Um conjunto de geolocalização
deve sempre incluir um registro `Default`, senão um resolvedor de um país que ninguém listou não
recebe resposta nenhuma.

## Verificações de saúde

**Uma verificação de saúde (*health check*) é um conjunto de sondas que a AWS envia de vários
lugares do mundo** a um endereço que você nomeia, a cada 30 segundos ou a cada 10. Ela guarda um
veredito: saudável, ou não saudável depois de um número de falhas seguidas. Um registro que cita a
verificação fica fora das respostas enquanto ela está não saudável. Crie uma para a API em São
Paulo:

```
ana@laptop:~/aws$ aws route53 create-health-check --caller-reference shop-api-sp-1 --health-check-config Type=HTTPS,IPAddress=203.0.113.20,Port=443,ResourcePath=/health,FullyQualifiedDomainName=api.shop.example.com,RequestInterval=30,FailureThreshold=3 --query "HealthCheck.[Id,HealthCheckConfig.Type,HealthCheckConfig.IPAddress]" --output text
283ed0d6-48b1-4372-b739-5df27b68b6fa	HTTPS	203.0.113.20
```

```
ana@laptop:~/aws$ hc=$(aws route53 list-health-checks --query "HealthChecks[0].Id" --output text)
ana@laptop:~/aws$ echo $hc
283ed0d6-48b1-4372-b739-5df27b68b6fa
```

Depois pergunte como ela vai:

```
ana@laptop:~/aws$ aws route53 get-health-check-status --health-check-id $hc
{
    "HealthCheckObservations": [
        {
            "Region": "us-east-1",
            "IPAddress": "127.0.13.37",
            "StatusReport": {
                "Status": "Success: HTTP Status Code: 200. Resolved IP: 127.0.13.37. OK",
                "CheckedTime": "2026-10-16T16:00:34.261386+00:00"
            }
        }
    ]
}
```

**Leia essa resposta como invenção do moto, palavra por palavra.** Nada escuta em `203.0.113.20`: é
um endereço de documentação, e o moto não enviou sonda nenhuma a ele nem a lugar nenhum. O status, o
código 200 e o endereço `127.0.13.37` são o que o moto 5.2.3 diz sobre toda verificação de saúde. Na
AWS, o mesmo comando lista uma observação por região que sonda, cada uma com o que aquela sonda viu
de fato. Uma verificação de um endereço que não responde informa uma falha. **Um plano de failover
não pode ser testado no moto**. O que o moto consegue conferir é que os registros e a verificação
estão ligados do jeito que você quis.

## Ponderada e failover, num lote só

As duas políticas precisam do id da verificação de saúde dentro do lote, então este arquivo é escrito
com um *here document* que põe o `$hc` no lugar para você. Digite-o como está:

```sh
cat > ~/aws/policies.json <<EOF
{
  "Comment": "a canary for search, a standby for the API",
  "Changes": [
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "search.shop.example.com", "Type": "A", "TTL": 60,
      "SetIdentifier": "current", "Weight": 90,
      "ResourceRecords": [{"Value": "203.0.113.30"}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "search.shop.example.com", "Type": "A", "TTL": 60,
      "SetIdentifier": "canary", "Weight": 10,
      "ResourceRecords": [{"Value": "203.0.113.31"}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "api.shop.example.com", "Type": "A", "TTL": 60,
      "SetIdentifier": "sao-paulo", "Failover": "PRIMARY", "HealthCheckId": "$hc",
      "ResourceRecords": [{"Value": "203.0.113.20"}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "api.shop.example.com", "Type": "A", "TTL": 60,
      "SetIdentifier": "virginia", "Failover": "SECONDARY",
      "ResourceRecords": [{"Value": "198.51.100.20"}]}}
  ]
}
EOF
```

```
ana@laptop:~/aws$ aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch file://policies.json --query ChangeInfo.Status --output text
INSYNC
```

```
ana@laptop:~/aws$ aws route53 list-resource-record-sets --hosted-zone-id $zone --query "ResourceRecordSets[?SetIdentifier].[Name,SetIdentifier,Weight,Failover,HealthCheckId]" --output text
api.shop.example.com.	sao-paulo	None	PRIMARY	283ed0d6-48b1-4372-b739-5df27b68b6fa
api.shop.example.com.	virginia	None	SECONDARY	None
search.shop.example.com.	current	90	None	None
search.shop.example.com.	canary	10	None	None
```

**Um peso é uma fatia, não uma porcentagem.** O Route 53 divide o peso de cada registro pela soma
dos pesos daquele nome. Então 90 e 10 são nove respostas em dez e uma em dez, e 9 e 1 também. Um
peso 0 tira um registro do rodízio sem apagá-lo, e é assim que um canário é parado às pressas.

**O par de failover responde com o primário enquanto a verificação dele está saudável**, e com o
secundário quando não está. O secundário aqui não tem verificação, então é sempre considerado
saudável. Uma reserva que nunca é verificada é uma aposta de que ela ainda está lá no dia em que for
preciso, e uma reserva de verdade ganha uma verificação própria. O TTL de 60 faz parte do projeto.
Um resolvedor que guardou o endereço de São Paulo continua usando-o por até um minuto depois da
troca, então o TTL é o piso de quão rápido um failover pode ser.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l21-routing\" aria-label=\"Duas políticas de roteamento lado a lado. À esquerda, ponderada: o nome search.shop.example.com tem dois registros, current com peso 90 em 203.0.113.30 e canary com peso 10 em 203.0.113.31, então nove respostas em dez dão o primeiro endereço. À direita, failover: api.shop.example.com tem um primário em São Paulo em 203.0.113.20, vigiado por uma verificação de saúde, e um secundário na Virgínia em 198.51.100.20, dado só enquanto a verificação diz que o primário não está saudável. Embaixo: o Route 53 escolhe a resposta, e o tráfego nunca passa por ele.\"><defs><marker id=\"l21-routing-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l21-routing-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"330.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"36.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">ponderada</text><rect x=\"370.0\" y=\"20.0\" width=\"330.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"386.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">failover</text><rect x=\"70.0\" y=\"60.0\" width=\"230.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">search.shop.example.com</text><rect x=\"40.0\" y=\"180.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">current</text><text x=\"105.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.30</text><rect x=\"200.0\" y=\"180.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">canary</text><text x=\"265.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.31</text><path d=\"M150.0 98.0 L110.0 176.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\" marker-end=\"url(#l21-routing-af-ah-phosphor)\"></path><path d=\"M220.0 98.0 L260.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.0\" fill=\"none\" marker-end=\"url(#l21-routing-af-ah-amber)\"></path><text x=\"112.0\" y=\"132.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">9 em 10</text><text x=\"256.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">1 em 10</text><text x=\"185.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">pesos 90 e 10, uma fração da soma</text><rect x=\"420.0\" y=\"60.0\" width=\"230.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">api.shop.example.com</text><rect x=\"390.0\" y=\"180.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">PRIMARY, São Paulo</text><text x=\"460.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.20</text><rect x=\"550.0\" y=\"180.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"620.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SECONDARY, Virgínia</text><text x=\"620.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">198.51.100.20</text><path d=\"M500.0 98.0 L465.0 176.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l21-routing-af-ah-phosphor)\"></path><path d=\"M570.0 98.0 L615.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l21-routing-af-ah-amber)\"></path><text x=\"494.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">enquanto saudável</text><text x=\"600.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">quando não está</text><circle cx=\"425.0\" cy=\"128.0\" r=\"11\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"425.0\" y=\"128.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">✓</text><text x=\"425.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">verificação</text><path d=\"M430.0 158.0 L440.0 176.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.0\" fill=\"none\" stroke-dasharray=\"2 2\"></path><text x=\"535.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">verificação de saúde só no primário</text><text x=\"360.0\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o Route 53 escolhe a resposta; o tráfego nunca passa por ele</text></svg>", "caption": "Uma política é uma regra para escolher entre registros. A escolha é feita uma vez por pergunta, e fica em cache pelo TTL.", "same": ["PRIMARY, São Paulo", "failover"]}
```

## Perguntar ao Route 53 o que ele responderia

A AWS tem um comando exatamente para a pergunta que o moto não sabe responder. O `test-dns-answer`
pergunta ao Route 53 quais valores ele devolveria para um nome e um tipo, a partir de um endereço de
resolvedor que você pode escolher.

```
ana@laptop:~/aws$ aws route53 test-dns-answer --hosted-zone-id $zone --record-name search.shop.example.com --record-type A

aws: [ERROR]: An error occurred (404) when calling the TestDNSAnswer operation: Not Found
```

**O moto 5.2.3 não o implementa**, e o `404` é o moto dizendo isso, não o Route 53 dizendo que o
nome falta. O moto também não serve DNS em porta nenhuma, então o `dig` não tem a quem perguntar.
Apontar o `dig` para os servidores de nomes reais do Route 53 é assunto da internet e fica fora
deste curso. O que o laboratório dá é a configuração, lida de volta exatamente como foi escrita, e é
nela que mora a maioria dos erros de uma zona.

## Quanto custa um milhão de respostas

O `price.py` imprime quatro casas decimais, e uma consulta de DNS custa menos de um centésimo de
centavo, então as linhas sairiam todas `0.0000`. Este programa curto lê o arquivo que o `price.py` já
baixou e imprime o preço por milhão. Salve-o como `~/aws/per-million.py`:

```python
#!/usr/bin/env python3
"""Prints prices per million units, from an offer price.py has already downloaded.

    python3 per-million.py OFFER VERSION REGION USAGETYPE...
"""
import json
import os
import sys

code, version, region, *usages = sys.argv[1:]
path = os.path.expanduser(f'~/.cache/aws-prices/{code}-{version}-{region}.json')
with open(path) as f:
    doc = json.load(f)
for usage in usages:
    tiers = []
    for sku, product in doc['products'].items():
        if product['attributes'].get('usagetype') == usage:
            for term in doc['terms']['OnDemand'].get(sku, {}).values():
                for d in term['priceDimensions'].values():
                    tiers.append((float(d['beginRange']), float(d['pricePerUnit']['USD'])))
    print(usage)
    for begin, price in sorted(tiers):
        print(f'  from {begin:>13,.0f}  {price * 1_000_000:.2f} per million')
```

```
ana@laptop:~/aws$ python3 per-million.py AmazonRoute53 20260911124504 aws-other DNS-Queries LBR-Queries Geo-Queries Intra-AWS-DNS-Queries
DNS-Queries
  from             0  0.40 per million
  from 1,000,000,000  0.20 per million
LBR-Queries
  from             0  0.60 per million
  from 1,000,000,000  0.30 per million
Geo-Queries
  from             0  0.70 per million
  from 1,000,000,000  0.35 per million
Intra-AWS-DNS-Queries
  from             0  0.00 per million
```

```
ana@laptop:~/aws$ python3 price.py AmazonRoute53 20260911124504 aws-other Health-Check-AWS Health-Check-Non-AWS Health-Check-Option-Non-AWS
AmazonRoute53 20260911124504, published 2026-09-11, USD
Health-Check-AWS
          0 to        50 Mo   0.0000
         50 to       Inf Mo   0.5000
Health-Check-Non-AWS
          0 to       Inf Mo   0.7500
Health-Check-Option-Non-AWS
          0 to       Inf Mo   2.0000
```

Na lista de **11 de setembro de 2026**:

| o quê | dólares |
|---|---|
| um milhão de consultas comuns, no primeiro bilhão do mês | 0,40 |
| um milhão de consultas baseadas em latência (`LBR`) | 0,60 |
| um milhão de consultas de geolocalização | 0,70 |
| um milhão de consultas respondidas a partir de um alias para um recurso da AWS | grátis |
| uma verificação de saúde de um endpoint da AWS, por mês | grátis nas primeiras 50, depois 0,50 |
| uma verificação de saúde de qualquer outra coisa, por mês | 0,75 |
| cada recurso opcional numa verificação dessas, por mês | 2,00 |

**A política faz parte do preço.** A mesma pergunta custa metade a mais quando o registro por trás
dela é baseado em latência, e três quartos a mais quando é de geolocalização. A verificação da API
sonda `203.0.113.20`, um endereço fora da AWS, então é a linha de 0,75. Ela também sonda por HTTPS,
que a página de preços da AWS conta como um dos recursos opcionais, junto com a busca de texto na
resposta, o intervalo de 10 segundos e a medição de latência. Isso soma a linha de 2,00, então essa
única verificação custa 2,75 dólares por mês. Uma loja que responde dez milhões de consultas por mês
a partir de registros simples paga 4 dólares por elas, e nada pelas que o alias do ápice responde.
