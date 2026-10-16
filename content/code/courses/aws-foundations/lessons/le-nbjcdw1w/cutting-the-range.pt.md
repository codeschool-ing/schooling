---
title: Cortando o intervalo em sub-redes, e os cinco endereços que a AWS guarda
version: 1
---

**Uma sub-rede é uma fatia do intervalo da VPC que mora em exatamente uma Availability Zone.** Todo
endereço que a AWS distribui sai de uma sub-rede, então toda máquina fica numa zona, a zona da sua
sub-rede. A imagem errada é uma sub-rede esticada pela região; isso não existe. **Um desenho que
sobrevive à perda de uma zona precisa de uma sub-rede em cada zona para cada tipo de máquina**, que é
o que a lição 1 prometeu que esta lição faria.

## Três camadas, três zonas, nove sub-redes

A loja roda três tipos de coisa, e cada um ganha uma camada própria:

| camada | o que mora ali | alcançada a partir de |
|---|---|---|
| `public` | o load balancer (lição 22) e os NAT gateways (lição 17) | a internet |
| `app` | as máquinas da aplicação da loja | só o load balancer |
| `data` | o banco de dados | só a aplicação |

Três camadas em três zonas são nove sub-redes. Cada uma ganha um `/20`, 4.096 endereços, e um `/16`
guarda dezesseis desses, então nove deixam **sete blocos de reserva** para uma camada em que ninguém
pensou ainda. Esse espaço de reserva importa mais do que parece, porque **o intervalo de uma
sub-rede não pode ser mudado depois que ela é criada**: uma sub-rede que fica sem endereços é
substituída, e tudo o que está nela se muda.

Calcular onde cada `/20` começa é aritmética binária, do tipo que erra por um bit na pressa. O módulo
`ipaddress` do Python faz isso, e o plano vira um programa que qualquer pessoa pode rodar de novo e
ler. Crie um diretório para os arquivos desta lição com `mkdir -p ~/aws/net` e salve isto como
`~/aws/net/plan.py`:

```schooling-example
{"language": "python", "file": "plan.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"The address plan of the shop's production VPC: one /20 per zone and tier.\n\n    python3 plan.py\n\nPrints one line per subnet, zone, tier, range and usable addresses, and a\nlast line, starting with #, saying how much of the VPC is left.\n\"\"\"\nimport ipaddress\n\n", "note": "Só a biblioteca do próprio Python. O `ipaddress` sabe o que é uma rede, quais endereços ela guarda e como cortá-la em redes menores."}, {"code": "VPC = ipaddress.ip_network('10.20.0.0/16')\nZONES = ['sa-east-1a', 'sa-east-1b', 'sa-east-1c']\nTIERS = ['public', 'app', 'data']\n\n", "note": "As três decisões em que o plano se apoia: o intervalo da VPC, as zonas de `sa-east-1` e as camadas. Mudar uma dessas linhas muda o plano inteiro, e é para isso que ele está escrito como programa."}, {"code": "blocks = VPC.subnets(new_prefix=20)\n", "note": "Todo `/20` dentro do `/16`, em ordem, a partir de `10.20.0.0`. Ele os entrega um de cada vez, então duas sub-redes nunca recebem o mesmo bloco."}, {"code": "for tier in TIERS:\n    for zone in ZONES:\n        net = next(blocks)\n        print(f'{zone}  {tier:<6}  {str(net):<14}  {net.num_addresses - 5}')\n", "note": "Um bloco para cada camada em cada zona, camada por camada, para que as três sub-redes de uma camada fiquem lado a lado. `num_addresses` é 4.096 para um `/20`, e cinco deles pertencem à AWS, como a próxima parte desta seção mede."}, {"code": "spare = list(blocks)\nprint(f'# spare: {len(spare)} blocks of /20, {spare[0]} to {spare[-1]}')\n", "note": "O que o laço não pegou. A linha começa com `#` para que um programa que lê o plano possa pulá-la."}]}
```

```
ana@laptop:~/aws$ python3 net/plan.py
sa-east-1a  public  10.20.0.0/20    4091
sa-east-1b  public  10.20.16.0/20   4091
sa-east-1c  public  10.20.32.0/20   4091
sa-east-1a  app     10.20.48.0/20   4091
sa-east-1b  app     10.20.64.0/20   4091
sa-east-1c  app     10.20.80.0/20   4091
sa-east-1a  data    10.20.96.0/20   4091
sa-east-1b  data    10.20.112.0/20  4091
sa-east-1c  data    10.20.128.0/20  4091
# spare: 7 blocks of /20, 10.20.144.0/20 to 10.20.240.0/20
```

**As três sub-redes de uma camada são vizinhas**, então o plano se lê de relance: a camada pública
vai de `10.20.0.0` a `10.20.47.255`, a camada de dados termina em `10.20.143.255`, e tudo de
`10.20.144.0` até o topo do intervalo está livre.

## Os cinco endereços que a AWS guarda

A última coluna diz 4.091, não 4.096. **A AWS reserva cinco endereços em toda sub-rede**, seja qual
for o tamanho dela, e nenhuma máquina recebe um deles:

- o primeiro, o endereço de rede da própria sub-rede;
- o segundo, o roteador da VPC, para onde vai primeiro todo pacote que sai da sub-rede;
- o terceiro, guardado para o resolvedor de DNS que a AWS roda na base do intervalo da VPC mais dois;
- o quarto, guardado para uso futuro;
- o último, o endereço de broadcast, que uma VPC não transporta mas guarda mesmo assim.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l16-reserved\" aria-label=\"Os dezesseis endereços de um /28, de 10.20.0.0 a 10.20.0.15, desenhados como uma fileira de células. Os quatro primeiros e o último são reservados pela AWS: .0 é o endereço da rede, .1 o roteador da VPC, .2 o resolvedor de DNS, .3 fica guardado para uso futuro e .15 é o endereço de broadcast. Os onze entre .4 e .14 são os que uma máquina pode receber. Um /20 guarda os mesmos cinco, então 4.096 endereços deixam 4.091.\"><text x=\"360.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">um /28, a menor sub-rede que a AWS aceita: 16 endereços</text><rect x=\"25.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"45.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.0</text><path d=\"M45.0 138.0 L45.0 146.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"45.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">rede</text><rect x=\"67.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"87.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.1</text><path d=\"M87.0 138.0 L87.0 168.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"87.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">roteador</text><rect x=\"109.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"129.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.2</text><path d=\"M129.0 138.0 L129.0 146.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"129.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">DNS</text><rect x=\"151.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"171.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.3</text><path d=\"M171.0 138.0 L171.0 168.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"171.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">futuro</text><rect x=\"193.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"213.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.4</text><rect x=\"235.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.5</text><rect x=\"277.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"297.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.6</text><rect x=\"319.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"339.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.7</text><rect x=\"361.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"381.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.8</text><rect x=\"403.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"423.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.9</text><rect x=\"445.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.10</text><rect x=\"487.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.11</text><rect x=\"529.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"549.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.12</text><rect x=\"571.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"591.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.13</text><rect x=\"613.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"633.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.14</text><rect x=\"655.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"675.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.15</text><path d=\"M675.0 138.0 L675.0 146.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"675.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">broadcast</text><path d=\"M194.0 86.0 L194.0 78.0 L652.0 78.0 L652.0 86.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"423.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">11 que uma máquina pode receber</text><text x=\"24.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.0.0/28</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">toda sub-rede guarda os mesmos cinco: um /24 deixa 251, um /20 deixa 4.091</text></svg>", "caption": "Cinco endereços de toda sub-rede pertencem à AWS, seja qual for o tamanho dela.", "same": ["DNS", "broadcast"]}
```

A regra é uma constante, então custa muito mais a uma sub-rede pequena do que a uma grande: **5 de
4.096 num `/20` não é nada, 5 de 16 num `/28` é quase um terço.** O moto subtrai os mesmos cinco, e
duas sub-redes no espaço de reserva mostram isso, um `/24` e um `/20`:

```
ana@laptop:~/aws$ aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.20.240.0/24 --availability-zone sa-east-1a --query "Subnet.[CidrBlock,AvailableIpAddressCount]" --output text
10.20.240.0/24	251
ana@laptop:~/aws$ aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.20.224.0/20 --availability-zone sa-east-1a --query "Subnet.[CidrBlock,AvailableIpAddressCount]" --output text
10.20.224.0/20	4091
```

**251 e 4.091 são 256 − 5 e 4.096 − 5.** `AvailableIpAddressCount` cai um a cada endereço que algo
ocupa, então na AWS ele também é o número a observar numa sub-rede que está enchendo.

## O que uma sub-rede não pode ser

Três regras decidem se uma sub-rede é aceita, e o moto recusa as duas primeiras do jeito que a AWS
recusa:

```
ana@laptop:~/aws$ aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.20.240.128/25 --availability-zone sa-east-1a

aws: [ERROR]: An error occurred (InvalidSubnet.Conflict) when calling the CreateSubnet operation: The CIDR '10.20.240.128/25' conflicts with another subnet
ana@laptop:~/aws$ aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.21.0.0/24 --availability-zone sa-east-1a

aws: [ERROR]: An error occurred (InvalidSubnet.Range) when calling the CreateSubnet operation: The CIDR '10.21.0.0/24' is invalid.
ana@laptop:~/aws$ aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.20.250.0/29 --availability-zone sa-east-1a --query "Subnet.[CidrBlock,AvailableIpAddressCount]" --output text
10.20.250.0/29	3
ana@laptop:~/aws$ for s in $(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc --query "Subnets[].SubnetId" --output text); do aws ec2 delete-subnet --subnet-id $s; done
ana@laptop:~/aws$ aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc --query "length(Subnets)"
0
```

**Duas sub-redes de uma VPC nunca se sobrepõem**: `10.20.240.128/25` é a metade de cima do `/24`
criado um momento antes, e é recusada como conflito. **Uma sub-rede fica dentro de um dos intervalos
da VPC**: `10.21.0.0/24` está fora de `10.20.0.0/16`, e é recusada como inválida. A terceira regra é
o tamanho, **entre `/28` e `/16`**, e aqui o moto é mais tolerante que a AWS: ele aceitou o `/29` e
deu a ele três endereços utilizáveis. A AWS recusa uma sub-rede menor que um `/28`; essa recusa não
foi executada aqui, já que o moto não a faz.

As três sub-redes de teste cumpriram o papel. O último comando dessa transcrição apagou todas, então
a VPC está vazia de novo para o plano.

## O plano, como script

As nove sub-redes saem do próprio plano, então ninguém digita um intervalo. Este script lê as linhas
do `plan.py` e cria uma sub-rede para cada uma, com o nome da camada e da zona (`public-a`, `app-b`,
`data-c`). Ele também cria a VPC quando não há nenhuma chamada `shop-prod`, e é isso que deixa as
lições 17 a 20 reconstruírem esta lição num passo só, num moto vazio. Escreva-o com:

```sh
cat > ~/aws/net/16-vpc.sh <<'EOF'
# Lesson 16: the shop's production VPC and its nine subnets.
# On an empty moto it creates the VPC too; after the lesson's own
# create-vpc it finds that VPC by its name and adds the subnets.
vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod \
  --query "Vpcs[0].VpcId" --output text)
if [ "$vpc" = None ]; then
  vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop-prod},{Key=project,Value=shop},{Key=env,Value=prod}]' \
    --query Vpc.VpcId --output text)
fi
python3 ~/aws/net/plan.py | grep -v '^#' | while read -r zone tier cidr usable; do
  aws ec2 create-subnet --vpc-id "$vpc" --cidr-block "$cidr" --availability-zone "$zone" \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$tier-${zone: -1}},{Key=tier,Value=$tier},{Key=project,Value=shop}]" \
    --query "Subnet.[Tags[?Key=='Name']|[0].Value,CidrBlock,AvailabilityZoneId,AvailableIpAddressCount]" \
    --output text < /dev/null
done
EOF
```

`${zone: -1}` é a última letra do nome da zona. O `< /dev/null` impede o `aws` de ler as linhas
restantes do plano como entrada dele, o que encerraria o laço em silêncio depois de uma sub-rede.
Depois rode-o:

```
ana@laptop:~/aws$ bash net/16-vpc.sh
public-a	10.20.0.0/20	sae1-az1	4091
public-b	10.20.16.0/20	sae1-az2	4091
public-c	10.20.32.0/20	sae1-az3	4091
app-a	10.20.48.0/20	sae1-az1	4091
app-b	10.20.64.0/20	sae1-az2	4091
app-c	10.20.80.0/20	sae1-az3	4091
data-a	10.20.96.0/20	sae1-az1	4091
data-b	10.20.112.0/20	sae1-az2	4091
data-c	10.20.128.0/20	sae1-az3	4091
```

**A terceira coluna é o id da zona**, de `sae1-az1` a `sae1-az3`, e é ele que se cita quando outra
conta precisa colocar algo na mesma zona (lição 1). A VPC agora tem a forma da rede da loja. Se
alguma parte dela alcança a internet é outra pergunta, e a próxima seção mostra que a resposta, por
enquanto, é não.
