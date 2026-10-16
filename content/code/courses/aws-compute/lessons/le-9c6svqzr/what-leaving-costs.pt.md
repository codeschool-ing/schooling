---
title: Quanto custaria sair, estimado antes de chegar
version: 1
---

"O quanto estamos presos?" não tem resposta. **"Quanto custaria sair, em dinheiro e em semanas?"
tem**, e dá para estimar no primeiro dia, quando mudar é mais barato. A estimativa tem quatro
linhas, e cada uma vem de algo que se pode contar: o código que seria reescrito, os dados que seriam
movidos, as pessoas que precisariam aprender algo novo e as semanas rodando as duas coisas enquanto
a mudança acontece.

**Todo número de esforço no exemplo desta seção é inventado.** As contagens de linhas, os preços por
gigabyte e a conta mensal da aula 23 são capturas, e a aritmética sobre eles é exata.

## A superfície de reescrita

Comece pelo código. A pergunta não é o tamanho da aplicação, e sim quanto dela toca o provedor. Para
a loja da seção anterior, isso pode ser contado diretamente:

```
ana@laptop:~/aws/shop$ wc -l orders.py lambda_app.py server.py
  14 orders.py
  11 lambda_app.py
  20 server.py
  45 total
ana@laptop:~/aws/shop$ grep -n "quote" lambda_app.py server.py
lambda_app.py:4:from orders import quote
lambda_app.py:8:    status, body = quote(json.loads(event.get("body") or "{}"))
server.py:5:from orders import quote
server.py:11:        status, body = quote(json.loads(self.rfile.read(size) or b"{}"))
```

Catorze linhas de `orders.py` guardam a regra da loja, o nome dela e a docstring, e os outros dois
arquivos existem para alcançá-la: onze linhas para o Lambda, vinte para um servidor web. O `grep`
mostra que cada um deles toca a regra em exatamente dois lugares, o import e a chamada. Sair do
Lambda para um contêiner quer dizer usar o arquivo de vinte linhas, que já existe; sair de um
contêiner para o Lambda quer dizer o de onze. **O que precisa ser reescrito são os adaptadores,
nunca a regra**, porque a regra nunca aprendeu onde roda.

Numa base de código real, a mesma contagem é uma busca: todo arquivo que importa `boto3`, lê um
dicionário `event`, interpreta uma entrada do Step Functions ou nomeia um ARN. Uma base em que essa
busca devolve quatro arquivos tem uma superfície de reescrita pequena; uma em que devolve duzentos
tem uma grande, diga o diagrama de arquitetura o que disser.

## Os dados, e o preço de movê-los

Dados são o lock-in que cresce sozinho. Todo mês a loja guarda mais fotos e mais relatórios, e cada
gigabyte é mais um para carregar para fora. Levá-los da AWS para a internet tem preço por gigabyte,
em faixas, e as faixas estão na oferta do EC2 que o `prices.py` já baixou. Um programa curto as lê,
na mesma versão fixa do resto da tabela:

```python
# egress.py
"""Data transfer from São Paulo to the internet, from AWS's price list.

Reads the EC2 offer that prices.py downloaded, at the same pinned version.
"""
import json
import os

PATH = '~/.cache/aws-prices/AmazonEC2-20261015191316-sa-east-1.json'

doc = json.load(open(os.path.expanduser(PATH)))
tiers = []
for sku, product in doc['products'].items():
    if product['attributes'].get('usagetype') == 'SAE1-DataTransfer-Out-Bytes':
        for term in doc['terms']['OnDemand'][sku].values():
            tiers += term['priceDimensions'].values()
for d in sorted(tiers, key=lambda d: float(d['beginRange'])):
    usd = float(d['pricePerUnit']['USD'])
    print(f"{d['beginRange']:>7} to {d['endRange']:>6} GB a month  {usd:.2f} USD per GB")
```

```
ana@laptop:~/aws$ python3 egress.py
      0 to      1 GB a month  0.00 USD per GB
      1 to  10240 GB a month  0.25 USD per GB
  10240 to  51200 GB a month  0.23 USD per GB
  51200 to 153600 GB a month  0.21 USD per GB
 153600 to    Inf GB a month  0.19 USD per GB
```

Então, a partir de São Paulo, depois do primeiro gigabyte do mês, dados para a internet custam
**0,25 USD por GB até 10 TB**, caindo em degraus até 0,19 acima de 150 TB. Dois terabytes de fotos e
relatórios, 2.048 GB, custariam (2.048 − 1) × 0,25 = **511,75 USD** para sair num mês, a preço de
lista.

Esse preço de lista não é a história toda, e o resto dela não foi executado aqui. Em 5 de março de
2024, a AWS anunciou que dispensa a cobrança de transferência de dados para a internet para clientes
que estão saindo da AWS: o cliente pede antes ao AWS Support, recebe um crédito pela transferência e
tem um prazo limitado para concluir a mudança. Trate isso como uma política que pode mudar, leia os
termos atuais no dia em que precisar e mantenha na estimativa o preço de lista, que é o número que
vale sem a aprovação de ninguém.

## Pessoas e sobreposição

As duas últimas linhas são onde mora a maior parte do custo:

- habilidades: a equipe que roda a loja no Fargate precisaria aprender o serviço de contêineres
  do novo provedor, o modelo de identidade dele e a rede dele. Conte pessoas vezes dias;
- sobreposição: durante a mudança as duas plataformas rodam, e a antiga custa o que custava
  antes. Para a loja, são 49,60 USD por mês de tasks de Fargate, da aula 23, para cada mês que a
  mudança levar, antes do load balancer e do armazenamento.

## A estimativa, por escrito

Tudo junto, com os números de esforço inventados do exemplo ao lado dos capturados:

| linha | como se conta | a loja, como exemplo |
| --- | --- | --- |
| reescrita | arquivos e linhas que tocam o provedor | os adaptadores, 31 linhas; chamadas ao armazenamento, 2 dias |
| dados | GB a mover × preço por GB | 2.048 GB × 0,25 = 511,75 USD, ou uma dispensa |
| habilidades | pessoas × dias para aprender | 3 pessoas × 3 dias |
| sobreposição | meses × a conta mensal antiga | 1 mês × 49,60 USD, mais armazenamento |

**O total não é o que importa; a maior linha é.** Para a loja, são as pessoas, não o dinheiro, o que
é comum numa equipe pequena. Isso diz onde uma costura se pagaria e onde não: nenhum adaptador faz
três pessoas conhecerem uma plataforma nova, mas manter a regra fora dos handlers deixou a linha de
reescrita quase em nada.
