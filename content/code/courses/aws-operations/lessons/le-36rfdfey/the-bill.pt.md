---
title: Lendo a conta por dono e por tipo de uso
version: 1
---

A conta detalhada é o **Cost and Usage Report**, CUR: uma linha por recurso, por tipo de uso, por hora ou
dia, com uma coluna para cada tag ativada, entregue num bucket como CSV ou Parquet. As linhas dele usam os
mesmos **tipos de uso** da lista de preços da lição 1, `SAE1-BoxUsage:m7g.large` e os outros, o que torna a
conta legível para quem já leu a lista de preços.

O moto não produz conta, então o mês da loja é escrito à mão aqui, resumido a quatro das colunas do CUR,
com vinte linhas feitas dos recursos e preços das lições anteriores:

```sh
cd ~/aws/owners
cat > bill.csv <<'CSV'
line_item_usage_type,line_item_resource_id,line_item_unblended_cost,resource_tags_user_owner
SAE1-BoxUsage:m7g.xlarge,i-0api1,189.87,api
SAE1-BoxUsage:m7g.xlarge,i-0api2,189.87,api
SAE1-BoxUsage:m7g.2xlarge,i-0worker,379.75,checkout
SAE1-BoxUsage:m7g.large,i-0stg1,94.97,platform
SAE1-BoxUsage:m7g.large,i-0stg2,94.97,platform
SAE1-BoxUsage:m7g.large,i-0stg3,94.97,
SAE1-BoxUsage:m7g.large,i-0stg4,94.97,
SAE1-EBS:VolumeUsage.gp3,vol-0lab200,30.40,
SAE1-EBS:SnapshotUsage,snap-0migration,6.80,
SAE1-PublicIPv4:IdleAddress,eipalloc-0spare,3.65,
SAE1-TimedStorage-ByteHrs,shop-orders,41.20,checkout
SAE1-Requests-Tier1,shop-orders,12.10,checkout
SAE1-TimedStorage-ByteHrs,tmp-test-ana,18.40,
SAE1-DataTransfer-Out-Bytes,,180.00,
SAE1-WebACLV2,shop,5.00,platform
SAE1-RequestV2-Tier1,shop,30.00,platform
SAE1-RuleV2,shop,3.00,platform
SAE1-DataProcessing-Bytes,/shop/api,52.30,api
sa-east-1-KMS-Keys,alias/shop-orders,1.00,platform
SAE1-AWSSecretsManager-Secrets,shop/prod/db,2.40,platform
CSV
```

O `bill.py` soma de dois jeitos, por dono e por tipo de uso, e lista o que não tem dono:

```python
# bill.py: a month's line items, by owner and by usage type
import collections
import csv

by_owner, by_usage = collections.Counter(), collections.Counter()
nobody = []
for row in csv.DictReader(open("bill.csv")):
    cost = float(row["line_item_unblended_cost"])
    owner = row["resource_tags_user_owner"] or "(nobody)"
    by_owner[owner] += cost
    by_usage[row["line_item_usage_type"]] += cost
    if owner == "(nobody)":
        nobody.append((cost, row["line_item_usage_type"], row["line_item_resource_id"] or "(no resource)"))

total = sum(by_owner.values())
print(f"total {total:.2f} USD")
for owner, cost in by_owner.most_common():
    print(f"  {owner:<10} {cost:>8.2f}  {cost / total:4.0%}")
print("largest usage types:")
for usage, cost in by_usage.most_common(4):
    print(f"  {usage:<28} {cost:>8.2f}")
print("owned by nobody:")
for cost, usage, resource in sorted(nobody, reverse=True):
    print(f"  {cost:>8.2f}  {usage:<28} {resource}")
```

```
ana@laptop:~/aws/owners$ python3 bill.py
total 1525.62 USD
  checkout     433.05   28%
  api          432.04   28%
  (nobody)     429.19   28%
  platform     231.34   15%
largest usage types:
  SAE1-BoxUsage:m7g.large        379.88
  SAE1-BoxUsage:m7g.2xlarge      379.75
  SAE1-BoxUsage:m7g.xlarge       379.74
  SAE1-DataTransfer-Out-Bytes    180.00
owned by nobody:
    180.00  SAE1-DataTransfer-Out-Bytes  (no resource)
     94.97  SAE1-BoxUsage:m7g.large      i-0stg4
     94.97  SAE1-BoxUsage:m7g.large      i-0stg3
     30.40  SAE1-EBS:VolumeUsage.gp3     vol-0lab200
     18.40  SAE1-TimedStorage-ByteHrs    tmp-test-ana
      6.80  SAE1-EBS:SnapshotUsage       snap-0migration
      3.65  SAE1-PublicIPv4:IdleAddress  eipalloc-0spare
```

**Mais de um quarto do mês, 429,19 USD, não tem dono.** Isso se divide em dois tipos, e eles pedem
respostas diferentes.

**Recursos sem a tag.** Duas das quatro instâncias de staging foram lançadas à mão e nunca receberam tag; o
volume, o snapshot e o endereço são os quatro ociosos da lição 23; `tmp-test-ana` é o bucket que a seção
anterior achou. Cada um é um recurso com id, e cada um se resolve dando um dono a ele ou apagando-o.

**Custos que não têm recurso nenhum.** A transferência de dados para fora da região, 180 USD aqui, é
cobrada da conta, e não de uma instância, e nenhuma tag pode ser posta nela. Nem em planos de suporte,
impostos ou na maioria dos créditos. Esses são **custos compartilhados**, e a resposta honesta é uma regra
para dividi-los, que é a próxima seção.

Os tipos de uso dizem outra coisa: três tamanhos de instância são três quartos da conta, e é ali que os
compromissos da lição 22 e o rightsizing da lição 23 se aplicam. Ler a conta por tipo de uso diz para onde
vai o dinheiro; ler por dono diz quem pode mudá-lo.
