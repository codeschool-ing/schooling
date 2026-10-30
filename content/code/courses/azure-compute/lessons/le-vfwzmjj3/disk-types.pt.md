---
title: Cinco tipos de disco, e o que cada um vende
version: 1
---

É tentador ler os tipos de disco como uma escada de qualidade, em que um disco melhor é a mesma
coisa feita mais rápida. **O que os separa é o jeito como o desempenho é vendido.** Standard HDD,
Standard SSD e Premium SSD vêm em faixas de tamanho, e cada faixa tem IOPS e vazão fixos: para ter
mais, você compra uma faixa maior. Premium SSD v2 e Ultra Disk vendem os três números separados, os
GiB, os IOPS e os MB/s, e cada um pode ser mudado sozinho. Seja qual for a escolha, a máquina em
que o disco está ligado tem um teto próprio, e o programa recebe o menor dos dois.

## Os cinco

A tabela de comparação da Microsoft, lida em 2026-10-30:

| | Ultra Disk | Premium SSD v2 | Premium SSD | Standard SSD | Standard HDD |
| --- | --- | --- | --- | --- | --- |
| vendido como | três números | três números | faixas de tamanho | faixas de tamanho | faixas de tamanho |
| maior disco | 65.536 GiB | 65.536 GiB | 32.767 GiB | 32.767 GiB | 32.767 GiB |
| máximo de IOPS | 400.000 | 80.000 | 20.000 | 6.000 | 2.000 |
| máximo de MB/s | 10.000 | 2.000 | 900 | 750 | 500 |
| disco do SO | não | não | sim | sim | até 8 de setembro de 2028 |
| nome do SKU | `UltraSSD_LRS` | `PremiumV2_LRS` | `Premium_LRS` | `StandardSSD_LRS` | `Standard_LRS` |

Standard HDD é para backups e dados lidos raramente, e a Microsoft vai aposentá-lo como disco do
SO na data da tabela. Standard SSD é para servidores web, aplicações leves e máquinas de teste.
Premium SSD é para trabalho de produção que precisa de latência baixa, e é o que o banco da loja
usou na etapa anterior. Os outros dois são para bancos de dados que precisam de uma taxa que as
faixas não dão, e os dois só servem como disco de dados.

## Premium SSD: a faixa decide

Um Premium SSD de um certo tamanho é uma faixa com uma letra e um número, e a faixa fixa as taxas
dele. Estas são as faixas para as quais as páginas da Microsoft dão números:

| faixa | tamanho | IOPS | MB/s |
| --- | --- | --- | --- |
| P4 | 32 GiB | 120 | 25 |
| P10 | 128 GiB | 500 | 100 |
| P30 | 1 TiB | 5.000 | 200 |
| P50 | 4 TiB | 7.500 | 250 |

Um tamanho entre duas faixas é cobrado como a de cima: o exemplo da Microsoft é um Standard SSD de
200 GiB cobrado como E15, 256 GiB. Então o `shop-db-log`, com 128 GiB, recebe 500 IOPS. Se o log
precisasse de 2.000, a resposta antiga era um disco quatro vezes maior do que o log precisa. **Um
Premium SSD também pode receber uma faixa de desempenho mais alta sem crescer**: um P10 posto na
faixa P50 tem 7.500 IOPS e 250 MB/s com 128 GiB, e é cobrado pelo preço do P50 até voltar.

## Burst, de dois jeitos

Premium SSD e Standard SSD também podem rodar acima da faixa por um tempo, o que se chama burst, e
há dois modelos.

**O burst por créditos** vem ligado por padrão em Premium SSDs de até 512 GiB (P20 e menores) e em
Standard SSDs de até 1.024 GiB, e não custa nada. Um disco junta créditos enquanto roda abaixo da
faixa e gasta acima dela, e um balde cheio dura 30 minutos na taxa de burst mais alta, enchendo de
novo em menos de um dia. O exemplo da Microsoft é o P4, que ela aponta como o disco do SO padrão
dos tamanhos que aceitam Premium SSD: 120 IOPS e 25 MB/s, com burst até 3.500 e 170, e é por isso
que uma máquina dá boot mais rápido do que a faixa do disco do SO sugere. A Microsoft também chama o
modelo de melhor esforço, então não é uma taxa para entrar no planejamento.

**O burst sob demanda** é para Premium SSDs maiores que 512 GiB, fica desligado até você ligá-lo e é
cobrado: uma taxa por hora enquanto está ligado, mais cada operação acima da faixa. Um P30 com ele
ligado pode ir de 5.000 IOPS a 30.000, e de 200 MB/s a 1.000. O exemplo calculado da Microsoft é um
job em lote rodando o P30 a 7.000 IOPS por 60 segundos: (7.000 − 5.000) × 60 = 120.000 operações
acima da faixa, cobradas como 12 unidades de 10.000. Um disco que passa a maior parte do dia em
burst pertence a uma faixa mais alta, e a documentação diz isso.

## Premium SSD v2: três números

O Premium SSD v2 não tem faixas. Ele tem qualquer tamanho de 1 GiB a 64 TiB, de um em um, e **os
IOPS e a vazão dele são definidos à parte do tamanho**, dentro de limites que crescem com ele:

- todo disco tem 3.000 IOPS e 125 MB/s sem custo, e o que você define acima disso é cobrado;
- a partir de 6 GiB, o máximo de IOPS cresce 500 por GiB, até 80.000, então um disco de 10 GiB pode
  ter 5.000 e um disco precisa de 160 GiB para ter 80.000;
- o máximo de vazão é 0,25 MB/s para cada IOPS definido, até 2.000 MB/s.

O desempenho pode ser mudado quatro vezes em 24 horas, e criar o disco conta como a primeira. Três
limites vêm junto: ele não pode ser disco do SO, ele **não aceita cache do host**, então a ligação
dele diz `None`, e na maioria das regiões com zonas ele só se liga a uma máquina numa zona. Brazil
South está na lista da Microsoft de regiões que o suportam em zonas. A lista de SKUs da CLI na etapa
anterior tinha `PremiumV2_LRS` e nenhum `PremiumV2_ZRS`, e isso não é esquecimento: ZRS não é
oferecido para ele.

O Ultra Disk leva a mesma ideia mais longe, a 1.000 IOPS por GiB, 400.000 por disco e 10.000 MB/s,
e é criado vazio, como disco de dados, para cargas como o SAP HANA.

Aqui está o disco de dados do banco da loja em Premium SSD v2, com as taxas a que a próxima parte
desta etapa chega. Salve como `disk.bicep`:

```bicep
// disk.bicep
param location string = 'brazilsouth'

resource data 'Microsoft.Compute/disks@2024-03-02' = {
  name: 'shop-db-data'
  location: location
  zones: [
    '1'
  ]
  sku: {
    name: 'PremiumV2_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 256
    diskIOPSReadWrite: 5000
    diskMBpsReadWrite: 145
  }
}
```

A ajuda da CLI para as duas propriedades está atrás do serviço que ela descreve:

```
ana@laptop:~/azure$ az disk create --help | tr -s "[:space:]" " " | grep -o "\-\-disk-[a-z]*-read-write : [^.]*\.[^.]*\."
--disk-iops-read-write : The number of IOPS allowed for this disk. Only settable for UltraSSD disks.
--disk-mbps-read-write : The bandwidth allowed for this disk. Only settable for UltraSSD disks.
```

As duas linhas dizem *Only settable for UltraSSD disks*, e o próprio guia da Microsoft para
implantar o Premium SSD v2 define as duas nesse SKU. O compilador aceita:

```
ana@laptop:~/azure$ bicep build disk.bicep
ana@laptop:~/azure$ jq ".resources[0] | {sku, zones, properties}" disk.json
{
  "sku": {
    "name": "PremiumV2_LRS"
  },
  "zones": [
    "1"
  ],
  "properties": {
    "creationData": {
      "createOption": "Empty"
    },
    "diskSizeGB": 256,
    "diskIOPSReadWrite": 5000,
    "diskMBpsReadWrite": 145
  }
}
```

Três erros, cada um feito numa cópia do arquivo:

```
ana@laptop:~/azure$ bicep build disk-sku.bicep
ana@laptop:~/azure$ jq -r ".resources[0].sku.name" disk-sku.json
Premium_V2_LRS
ana@laptop:~/azure$ bicep build disk-text.bicep
/home/ana/azure/disk-text.bicep(19,24) : Warning BCP036: The property "diskMBpsReadWrite" expected a value of type "int | null" but the provided value is of type "'145'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
ana@laptop:~/azure$ bicep build disk-small.bicep
ana@laptop:~/azure$ jq -c ".resources[0].properties | {diskSizeGB, diskIOPSReadWrite, diskMBpsReadWrite}" disk-small.json
{"diskSizeGB":8,"diskIOPSReadWrite":5000,"diskMBpsReadWrite":145}
```

O SKU escrito errado entrou no template sem uma palavra: o nome do SKU é um texto qualquer para o
compilador, e o Azure o recusaria. A vazão escrita como texto foi recusada. **O último é o erro de
que trata esta etapa, e nada aqui o pegou**: 5.000 IOPS num disco de 8 GiB. Cada número é um inteiro
válido; o que está errado é a conta entre eles, já que 8 GiB permitem 4.000. O Azure confere isso
quando o pedido chega. Você confere antes.

## A máquina limita o disco

As taxas de um disco são o que o disco consegue fazer. O que chega ao programa também é limitado
pela máquina, e a tabela da lição 1 deu a cada tamanho um limite próprio para todos os seus discos
juntos. A página da série Ddsv5 da Microsoft, lida em 2026-10-30, dá os dois tamanhos daqui, sem
cache:

| tamanho | discos de dados | IOPS | MB/s | IOPS em burst | MB/s em burst |
| --- | --- | --- | --- | --- | --- |
| `Standard_D2ds_v5` | 4 | 3.750 | 85 | 10.000 | 1.200 |
| `Standard_D4ds_v5` | 8 | 6.400 | 145 | 20.000 | 1.200 |

As colunas de burst são os créditos da própria máquina, o mesmo modelo de 30 minutos de um disco.

No `shop-db-1`, um `D4ds_v5`, o P30 e o P10 oferecem 5.000 + 500 = 5.500 IOPS, o que cabe nos
6.400. A vazão deles é 200 + 100 = 300 MB/s, e a máquina aceita 145. Um backup lendo o disco de
dados de ponta a ponta recebe 145 MB/s quando os créditos da máquina acabam, não os 200 do P30. Os
mesmos discos num `D2ds_v5` seriam limitados duas vezes, a 3.750 IOPS e 85 MB/s. O exemplo da
própria Microsoft tem a mesma forma: um `D8s_v3` com limite de 12.800 IOPS, com três discos P30,
pediu 15.000 e recebeu 12.800.

É daí que vêm os números do `disk.bicep`. O P30 tinha 1 TiB só porque 5.000 IOPS não vinham com
nada menor; no Premium SSD v2 os mesmos 5.000 IOPS ficam em 256 GiB, 2.000 acima dos 3.000 grátis,
e deixam 1.400 dos 6.400 da máquina para o log e o disco do SO. A vazão é 145 MB/s, 20 acima dos
125 grátis, porque é isso que o `D4ds_v5` aceita. **Um disco provisionado além da máquina compra uma
taxa que nada consegue usar**, e uma taxa maior no disco só vale a pena junto com um tamanho maior;
a tabela de tamanhos da lição 1 é o lugar para ler os dois.

Nada aqui mediu um disco. Essas taxas são as metas da Microsoft, e o jeito de medir um disco de
verdade é um benchmark como o `fio` numa máquina no Azure, o que este curso não consegue rodar.
