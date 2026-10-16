---
title: Recursos ociosos, achados por um programa
version: 1
---

A economia mais barata de uma conta é um recurso que ninguém usa: custa o mesmo toda hora, não faz nada, e
removê-lo não muda nada para ninguém. Eles se acumulam do mesmo jeito em toda conta: um disco desanexado
de uma instância que foi encerrada, um endereço mantido depois que o servidor dele foi embora, uma
instância parada "por enquanto" há oito meses, os snapshots de um volume que não existe mais. Nenhum deles
aparece num painel, porque um painel mostra o que funciona.

O laboratório cria um de cada, em `~/aws/rightsize` (`mkdir -p ~/aws/rightsize && cd ~/aws/rightsize`):

```sh
AMI=$(aws ec2 describe-images --owners amazon --query 'Images[0].ImageId' --output text)
aws ec2 run-instances --image-id $AMI --instance-type m7g.large --count 2 --query 'Instances[].InstanceId' --output text
OLD=$(aws ec2 describe-instances --query 'Reservations[0].Instances[0].InstanceId' --output text)
aws ec2 stop-instances --instance-ids $OLD --query 'StoppingInstances[0].CurrentState.Name'
aws ec2 create-volume --availability-zone sa-east-1a --size 200 --volume-type gp3 --query VolumeId --output text
aws ec2 allocate-address --domain vpc --query AllocationId --output text
GONE=$(aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --query VolumeId --output text)
aws ec2 create-snapshot --volume-id $GONE --description 'before the migration' --query SnapshotId --output text
aws ec2 delete-volume --volume-id $GONE
```

O `idle.py` pergunta ao EC2 por cada tipo e dá preço ao que acha, com os preços de São Paulo que a próxima
parte desta seção lê na lista de preços:

```python
# idle.py: what in this region is paid for and does nothing, and what it costs a month
import boto3

GP3_GB_MONTH = 0.152  # SAE1-EBS:VolumeUsage.gp3
SNAPSHOT_GB_MONTH = 0.068  # SAE1-EBS:SnapshotUsage, if every block were stored
IDLE_IPV4_HOUR = 0.005  # SAE1-PublicIPv4:IdleAddress
HOURS = 730

ec2 = boto3.client("ec2")
found = []

volumes = ec2.describe_volumes()["Volumes"]
for v in volumes:
    if v["State"] == "available":
        found.append(("volume, attached to nothing", v["VolumeId"], v["Size"] * GP3_GB_MONTH))

for a in ec2.describe_addresses()["Addresses"]:
    if "AssociationId" not in a:
        found.append(("public IPv4, idle", a["AllocationId"], IDLE_IPV4_HOUR * HOURS))

stopped = ec2.describe_instances(Filters=[{"Name": "instance-state-name", "Values": ["stopped"]}])
for r in stopped["Reservations"]:
    for i in r["Instances"]:
        ids = [m["Ebs"]["VolumeId"] for m in i.get("BlockDeviceMappings", [])]
        size = sum(v["Size"] for v in volumes if v["VolumeId"] in ids)
        found.append(("instance, stopped, its disks", i["InstanceId"], size * GP3_GB_MONTH))

me = boto3.client("sts").get_caller_identity()["Account"]
live = {v["VolumeId"] for v in volumes}
for s in ec2.describe_snapshots(OwnerIds=["self"])["Snapshots"]:
    if s["OwnerId"] == me and s["VolumeId"] not in live:
        found.append(("snapshot of a deleted volume", s["SnapshotId"], s["VolumeSize"] * SNAPSHOT_GB_MONTH))

for kind, rid, usd in found:
    print(f"{kind:<30} {rid:<24} {usd:8.2f} USD a month")
print(f"{'total':<55} {sum(u for _, _, u in found):8.2f} USD a month")
```

```
ana@laptop:~/aws/rightsize$ python3 idle.py
volume, attached to nothing    vol-cf446da070549843f       30.40 USD a month
public IPv4, idle              eipalloc-bceaa6620f2bd0dc8     3.65 USD a month
instance, stopped, its disks   i-00301edfa1d4a6f6c          1.22 USD a month
snapshot of a deleted volume   snap-54fe7e295470e848f       6.80 USD a month
total                                                      42.07 USD a month
```

Quatro coisas sem fazer nada, 42,07 USD por mês, **cerca de 505 USD por ano**, e esta conta é um
laboratório com duas instâncias. A conferência do dono no laço dos snapshots está lá por causa do moto:
perguntado pelos snapshots da própria conta, ele também devolve os mais de mil por trás das suas imagens
de exemplo, que pertencem a outra conta, e a AWS não faria isso. Um snapshot que uma imagem da conta ainda
usa também não está ocioso, e um programa mais completo conferiria `describe-images` para ele.

A instância parada é a que as pessoas leem errado: **uma instância parada não custa nada de computação e
custa tudo dos seus discos**, que mantêm o preço haja ou não algo rodando.

## Os preços

Os preços de disco e de snapshot estão na oferta do EC2, que o `rates.py` da lição 22 já baixou; um
programa pequeno lê duas linhas dela, `ec2lines.py`:

```python
# ec2lines.py: lines of the EC2 offer that lesson 22's rates.py downloaded, by usage type
import json
import os
import sys

path = os.path.expanduser("~/.cache/aws-prices/AmazonEC2-20261015191316-sa-east-1-index.json")
with open(path) as f:
    offer = json.load(f)
lines = set()
for sku, product in offer["products"].items():
    usage = product["attributes"].get("usagetype")
    if usage in sys.argv[1:]:
        for term in offer["terms"]["OnDemand"].get(sku, {}).values():
            for d in term["priceDimensions"].values():
                lines.add(f"{usage:<26} {d['description']}")
print("\n".join(sorted(lines)))
```

O endereço está na oferta da VPC, que é pequena o bastante para ler com `curl` e `jq`, como a lição 16 leu
a do Shield:

```
ana@laptop:~/aws/rightsize$ python3 ec2lines.py SAE1-EBS:VolumeUsage.gp3 SAE1-EBS:SnapshotUsage
SAE1-EBS:SnapshotUsage     $0.068 per GB-Month of snapshot data stored - South America (Sao Paulo)
SAE1-EBS:VolumeUsage.gp3   $0.152 per GB-month of General Purpose (gp3) provisioned storage - South America (Sao Paulo)
ana@laptop:~/aws/rightsize$ curl -sS https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonVPC/20260917190528/sa-east-1/index.json | jq -r '.products as $p | .terms.OnDemand | to_entries[] | select($p[.key].attributes.usagetype | test("IdleAddress")) | .value[].priceDimensions[] | [.pricePerUnit.USD, .description] | @tsv'
0.0050000000	$0.005 per Idle public IPv4 address per hour
```

**15,2 centavos por GB-mês de gp3**, **6,8 centavos por GB-mês de snapshot**, e **meio centavo por hora por
endereço IPv4 público**, ocioso ou não: a AWS cobra por todo endereço IPv4 público desde 2024, em uso ou
ocioso, e a linha do ocioso é a que ninguém nota. Um snapshot é cobrado pelos blocos que guarda, o que no
primeiro snapshot de um volume são os dados gravados nele, então a conta do `idle.py` para ele é o máximo
que pode ser.

## Antes de apagar

O `idle.py` acha; não apaga, e nada automático deveria apagar. **Um disco sem anexo pode ser a única cópia
de alguma coisa.** A ordem é: marcar o que foi achado com a data, avisar a equipe, tirar um snapshot de um
volume antes de apagá-lo se alguém hesitar, e apagar depois de uma semana de silêncio. Um snapshot de um
volume de 200 GB que guarda 20 GB de dados custa 1,36 USD por mês; o volume custa 30,40.
