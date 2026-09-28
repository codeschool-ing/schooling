---
title: Estimando um mês antes que ele aconteça
version: 1
---

Uma estimativa é **o desenho das aulas 4 a 9 multiplicado pela lista de preços**. Não é preciso nada
mais sofisticado para acertar a ordem de grandeza, e nada menos serve: um desenho que ninguém orçou é uma
conta que ninguém esperava.

Pegue uma pequena aplicação web em São Paulo, desenhada do jeito que a aula 6 desenhou uma:

- duas máquinas `t3.medium`, uma em cada uma de duas zonas, em sub-redes privadas;
- um application load balancer na frente delas, voltado para a internet;
- um volume raiz gp3 de 30 GB em cada máquina;
- um NAT gateway, para as máquinas alcançarem a internet para atualizações e APIs externas, processando
  uns 50 GB por mês;
- 200 GB de uploads e imagens no S3 Standard;
- uns 500 GB por mês de páginas e imagens enviados a usuários na internet.

Há uma linha que ninguém desenhou: **endereços IPv4 públicos**. As máquinas não têm nenhum, por serem
privadas, mas o NAT gateway tem um, e um load balancer voltado para a internet tem pelo menos um em cada
zona onde roda. São três endereços, e cada um é cobrado por hora.

A estimativa é um programa curto. Cada preço é copiado da tabela com um comentário que diz de qual
linha veio, para que quem for conferir ache o número em `python3 prices.py`:

```schooling-example
{
  "language": "python",
  "file": "estimate.py",
  "parts": [
    {
      "code": "# One month of a small web application in sa-east-1 (Sao Paulo),\n# from the public price list: python3 prices.py, the sa-east-1 column.\nHOURS = 730\n",
      "note": "Um mês são **730 horas**: as 8.760 do ano divididas por doze, a mesma convenção que as calculadoras dos provedores usam."
    },
    {
      "code": "T3_MEDIUM = 0.06720      # EC2, on demand: t3.medium\nALB = 0.0340             # load balancer (ALB), per hour\nNAT_HOUR = 0.0930        # NAT gateway, per hour\nNAT_GB = 0.0930          # NAT gateway, per GB processed\nIPV4 = 0.0050            # public IPv4 address, per hour\nGP3 = 0.1520             # EBS: gp3 SSD volume, per GB-month\nS3_STANDARD = 0.04050    # S3: Standard, per GB-month\nOUT_GB = 0.1500          # out to the internet, first 10 TB\n",
      "note": "Cada preço é **copiado da tabela**, coluna `sa-east-1`, com um comentário que diz de qual linha veio. Um número sem a linha dele não pode ser conferido, e no ano que vem não pode ser atualizado."
    },
    {
      "code": "lines = [\n    ('2 x t3.medium', 2 * T3_MEDIUM * HOURS),\n    ('load balancer, hours', ALB * HOURS),",
      "note": "As máquinas e o load balancer são **cobrados por existir**: um preço por hora vezes todas as horas do mês, com trabalho ou sem."
    },
    {
      "code": "    ('NAT gateway, hours', NAT_HOUR * HOURS),\n    ('NAT gateway, 50 GB', 50 * NAT_GB),\n    ('3 public IPv4 addresses', 3 * IPV4 * HOURS),",
      "note": "As linhas da própria rede. O NAT gateway é cobrado duas vezes, por hora e por gigabyte que processa, e os **três endereços** são do NAT gateway e do load balancer, um em cada uma das duas zonas dele."
    },
    {
      "code": "    ('2 x 30 GB gp3', 2 * 30 * GP3),\n    ('S3 Standard, 200 GB', 200 * S3_STANDARD),",
      "note": "Armazenamento em GB-mês. Os volumes gp3 são cobrados pelos 30 GB **provisionados**, cheios ou vazios; o bucket, pelos 200 GB que **guarda**."
    },
    {
      "code": "    ('500 GB out', 500 * OUT_GB),\n]",
      "note": "Tráfego de saída para a internet, todo dentro da primeira faixa, a dos primeiros 10 TB. A entrada é gratuita, então não tem linha."
    },
    {
      "code": "\nfor name, usd in lines:\n    print(f'{name:<26}{usd:>9.2f}')\nprint(f'{\"total, USD a month\":<26}{sum(u for _, u in lines):>9.2f}')",
      "note": "Imprime cada linha e o total. A saída abaixo é o que este programa imprimiu."
    }
  ],
  "output": "2 x t3.medium                 98.11\nload balancer, hours          24.82\nNAT gateway, hours            67.89\nNAT gateway, 50 GB             4.65\n3 public IPv4 addresses       10.95\n2 x 30 GB gp3                  9.12\nS3 Standard, 200 GB            8.10\n500 GB out                    75.00\ntotal, USD a month           298.64"
}
```

Um mês aqui são **730 horas**, as 8.760 horas do ano divididas por doze; é a convenção que as
calculadoras dos provedores usam, e faz meses de 28 e de 31 dias custarem o mesmo.

O total é **298,64 USD por mês**, sem impostos. Leia a coluna antes de confiar nele, porque uma
estimativa também é a primeira olhada em para onde vai o dinheiro. As duas máquinas somam 98,11, a maior
linha e cerca de um terço do total. As horas do NAT gateway são 67,89: um equipamento de rede que
existe para as máquinas saírem custa mais do que qualquer uma das máquinas que ele atende, a 49,06 cada.
A próxima seção desmonta essa linha, o tráfego de saída e os três endereços.

## O que a estimativa deixa de fora

Uma estimativa é honesta quando diz o que não contou. Esta deixa de fora:

- **impostos**, que a lista de preços exclui e a conta acrescenta;
- **um plano de suporte**, que os provedores vendem à parte e cobram como uma parcela da conta ou um
  mínimo mensal;
- **as unidades de capacidade do load balancer**. Um application load balancer é cobrado por hora, o
  que está na tabela, e também por uma medida do tráfego e das conexões que atende, que não está;
- **requisições**: cada GET e PUT no bucket do S3, 0.00056 e 0.00700 por mil;
- **logs e métricas**, cujo armazenamento cresce a cada mês que a aplicação roda;
- **snapshots e backups** dos volumes;
- **tráfego entre as duas zonas**, 0.0100 por GB em cada sentido, sempre que uma máquina conversa com
  algo na outra zona;
- DNS, um domínio e o que for comprado fora do provedor;
- **franquias gratuitas**. A lista de preços dá a toda conta os primeiros 100 GB de saída para a
  internet por mês sem custo, o que tiraria 15,00 da última linha; a seção sobre camadas gratuitas diz
  por que uma estimativa as deixa de fora.

Nenhum desses é grande sozinho para esta aplicação, e juntos são o motivo de um orçamento sensato para
ela não ser 298,64. Arredondar para 400, cerca de um terço a mais, dá o número que a seção sobre
orçamentos usa.

**Uma estimativa serve para duas decisões**, não para uma previsão ao centavo. Ela diz se o desenho cabe
no bolso antes de você construí-lo, e deixa comparar dois desenhos nos mesmos termos: troque o NAT
gateway, mude para `us-east-1`, mude o tamanho da máquina, rode o programa de novo. Ela também é a base
contra a qual a conta real é lida. Quando a primeira fatura disser 520, é a estimativa que diz qual linha
olhar.
