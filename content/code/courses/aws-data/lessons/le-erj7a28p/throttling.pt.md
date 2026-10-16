---
title: Throttling e partições quentes
version: 1
---

**Uma requisição que precisa de mais capacidade do que existe é estrangulada** (*throttled*): recusada,
tipicamente com `ProvisionedThroughputExceededException`, e nada é escrito. Os SDKs a tentam de novo com
pausas crescentes antes de desistir, então um programa encontra o throttling primeiro como lentidão e só
depois como erro. Dois limites o produzem, e o segundo é o que surpreende as pessoas.

**O primeiro é a capacidade da tabela, e ele é mais macio do que parece.** A AWS guarda até cinco
minutos da capacidade não usada de uma tabela provisionada como **capacidade de burst** e a gasta em
surtos curtos, sem prometer que ela vai estar lá. Sob demanda, uma tabela recebe na hora até o dobro do
pico anterior, e só é estrangulada quando o tráfego passa do dobro desse pico em cerca de meia hora.

**O segundo é o da partição, e ele não se mexe: 3.000 unidades de leitura e 1.000 de escrita por
segundo por partição.** Uma tabela de 10.000 unidades de escrita espalhada por vinte partições tem 500
por partição de folga; a mesma tabela manda toda escrita para uma partição se todas tiverem a mesma chave
de partição, e aí ela tem 1.000. **Uma partição quente é uma chave de partição que recebe mais do que a
sua parte**, e ela é estrangulada enquanto a tabela como um todo está quase parada. A capacidade
adaptativa da AWS empresta a uma partição ocupada a capacidade que as vizinhas não estão usando, na hora,
e divide em duas uma partição cujos itens estão quentes, mas nenhuma das duas coisas ergue o teto de uma
chave. Nenhuma configuração ergue.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"À esquerda: as 1.000 escritas por segundo da chave 2026-10-16 enchem uma partição até o limite de 1.000 unidades de escrita, enquanto três outras partições estão quase ociosas. À direita: as mesmas escritas com um sufixo de 0 a 9, de 2026-10-16#0 a #9, espalhadas por quatro partições, cada uma bem abaixo do limite.\" data-fig=\"l11-hot\"><defs><marker id=\"l11-hot-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">uma chave para o dia</text><line x1=\"20\" y1=\"60\" x2=\"320\" y2=\"60\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><rect x=\"30\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"34\" y=\"60.0\" width=\"48\" height=\"150.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"58\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 1</text><text x=\"58\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2026-10-16</text><rect x=\"102\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"106\" y=\"207.75\" width=\"48\" height=\"2.25\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"130\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 2</text><text x=\"130\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">…</text><rect x=\"174\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"178\" y=\"208.5\" width=\"48\" height=\"2\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"202\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 3</text><text x=\"202\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">…</text><rect x=\"246\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"250\" y=\"207.0\" width=\"48\" height=\"3.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"274\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 4</text><text x=\"274\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">…</text><text x=\"320\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1.000 por segundo por partição</text><text x=\"390\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o mesmo dia, dez chaves</text><line x1=\"390\" y1=\"60\" x2=\"690\" y2=\"60\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><rect x=\"400\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"404\" y=\"165.0\" width=\"48\" height=\"45.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"428\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 1</text><text x=\"428\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">#0 #4 #8</text><rect x=\"472\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"476\" y=\"180.0\" width=\"48\" height=\"30.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"500\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 2</text><text x=\"500\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">#1 #5</text><rect x=\"544\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"548\" y=\"165.0\" width=\"48\" height=\"45.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"572\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 3</text><text x=\"572\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">#2 #6 #9</text><rect x=\"616\" y=\"60\" width=\"56\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"620\" y=\"180.0\" width=\"48\" height=\"30.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"/><text x=\"644\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 4</text><text x=\"644\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">#3 #7</text><text x=\"690\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1.000 por segundo por partição</text></svg>", "caption": "Uma partição aguenta 1.000 escritas por segundo, tenha a tabela o que tiver. Dividir a chave espalha os pedidos de um dia por dez chaves, e o leitor paga consultando as dez."}
```

**A Quitanda tem uma, no índice da lição 10.** O `by-day` recebe todo pedido de um dia sob uma chave de
partição, `2026-10-16`. A 1.000 pedidos por segundo na promoção da noite, essa chave sozinha fica
exatamente no limite de escrita de uma partição, e um índice global que não dá conta estrangula as
escritas da tabela a que pertence. O conserto é a **divisão da escrita** (*write sharding*): acrescentar
um sufixo de 0 a 9 à chave do índice, `2026-10-16#7`, para que os pedidos de um dia se espalhem por dez
chaves e dez partições. O preço é pago por quem lê, que agora consulta dez chaves e junta as respostas. É
a mesma troca das chaves da lição 9: o projeto é feito para os padrões, e o padrão de escrita é um deles.

## O que o moto faz em vez disso

**O moto nunca estrangula.** A tabela products está provisionada em 5 unidades de escrita, e um programa
que escreve o mais rápido que pode, salvo como `flood.py`:

```python
import time

import boto3

db = boto3.client('dynamodb')
retries, start = 0, time.time()
for i in range(5000):
    answer = db.put_item(TableName='products', Item={'sku': {'S': f'hot-{i:04d}'}})
    retries += answer['ResponseMetadata']['RetryAttempts']
took = time.time() - start
print(f'5000 writes in {took:.1f} s, {5000 / took:.0f} a second, {retries} retried')
```

```
ana@laptop:~/aws$ python3 flood.py
5000 writes in 13.8 s, 363 a second, 0 retried
ana@laptop:~/aws$ aws dynamodb describe-table --table-name products --query 'Table.[ItemCount,ProvisionedThroughput.WriteCapacityUnits]' --output text
5002	5
```

**5.000 escritas em 13,8 segundos, 363 por segundo, contra uma capacidade de 5, e nenhuma foi repetida.**
Os 5.002 itens são as 5.000 e os dois da primeira seção. A AWS não foi consultada. Pelas regras
documentadas dela, esses 13,8 segundos teriam carregado umas 69 escritas a 5 por segundo, mais no máximo
1.500 de cinco minutos de capacidade de burst se a tabela tivesse ficado parada esse tempo todo. O resto
teria sido estrangulado, e o boto3 teria tentado de novo, transformando um programa que levou 14
segundos aqui num que leva muitos minutos lá. **Um teste de carga contra o moto mede o seu programa e o
seu laptop, nunca o DynamoDB.** A capacidade de um projeto se confere com a aritmética desta lição, e
numa conta real com orçamento, não aqui.
