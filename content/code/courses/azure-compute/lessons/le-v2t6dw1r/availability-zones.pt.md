---
title: Zonas de disponibilidade, e os três jeitos de um recurso ficar numa região
version: 1
---

Um conjunto de disponibilidade espalha máquinas por racks num só lugar. **Uma zona de
disponibilidade as põe em lugares diferentes**: locais fisicamente separados dentro de uma região,
cada um com a sua energia, a sua refrigeração e a sua rede, perto o bastante para uma conexão rápida
e longe o bastante para que uma falha local ou o tempo dificilmente alcance dois deles. A
documentação da Microsoft, lida em 2026-10-30, diz que uma região com suporte a zonas tem pelo menos
três, que cada uma é um ou mais datacenters, e que elas são ligadas por uma rede com ida e volta
abaixo de dois milissegundos. A lição 1 de `azure-foundations` diz o que é uma zona para a
plataforma inteira; esta seção trata do que ela significa para uma máquina.

Brazil South tem zonas. Ela está na lista da Microsoft de regiões que oferecem armazenamento com
redundância de zona, um tipo de armazenamento que só existe entre zonas, e a lição 4 espalhou o
scale set da loja pelas suas zonas `1`, `2` e `3`.

## Zonal, com redundância de zona, e nenhum dos dois

A imagem comum é que um recurso está "numa zona" ou "não está". São três casos, e o terceiro é o que
surpreende:

- Um recurso **zonal** fica preso a uma zona e divide o destino dela. Uma máquina virtual criada com
  `zones: ['1']` é zonal, os seus discos gerenciados são criados na mesma zona, e quando essa zona
  apaga a máquina cai junto.
- Um recurso **com redundância de zona** é espalhado entre zonas pelo próprio Azure, e sobrevive à
  perda de qualquer uma delas. Você o declara uma vez e não escolhe onde ficam as suas cópias. Um
  endereço IP público Standard pode ter redundância de zona.
- Um recurso **regional**, escrito sem zona nenhuma, é colocado pelo Azure em algum lugar da região.
  **Ninguém lhe diz em que zona ele está, e uma falha em qualquer uma das zonas da região pode
  derrubá-lo.** Uma máquina virtual criada sem `zones` é regional, e ela não está "em todas as
  zonas": está numa que você não vê.

Então duas máquinas zonais em duas zonas são redundantes entre zonas, e duas máquinas regionais
podem estar na mesma. O arquivo da loja abaixo faz o primeiro arranjo de propósito.

## Duas máquinas em duas zonas, e um endereço para as duas

Salve isto como `shop-zones.bicep`. Ele declara a API de pedidos em duas máquinas, uma na zona `1` e
outra na zona `2`, e o endereço público em que o load balancer da lição 22 de `azure-foundations`
atenderia, espalhado pelas três:

```schooling-example
{"language": "bicep", "file": "shop-zones.bicep", "parts": [{"code": "// shop-zones.bicep\nparam location string = 'brazilsouth'\nparam adminUsername string = 'ana'\nparam sshPublicKey string\n\nvar zones = ['1', '2']\n\nresource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {\n  name: 'shop-vnet'\n}\n\nresource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {\n  parent: vnet\n  name: 'app'\n}\n\n", "note": "Os mesmos parâmetros e a mesma rede do arquivo do conjunto. `zones` é a lista que os laços abaixo percorrem: uma máquina por item."}, {"code": "resource ip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {\n  name: 'shop-lb-ip'\n  location: location\n  zones: ['1', '2', '3']\n  sku: {\n    name: 'Standard'\n    tier: 'Regional'\n  }\n  properties: {\n    publicIPAllocationMethod: 'Static'\n    publicIPAddressVersion: 'IPv4'\n  }\n}\n\n", "note": "**Um endereço com redundância de zona.** Um IP público Standard que recebe as três zonas sobrevive à perda de qualquer uma. Ele é estático, então o endereço que os clientes da loja alcançam não muda."}, {"code": "resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = [for zone in zones: {\n  name: 'shop-web-z${zone}-nic'\n  location: location\n  properties: {\n    ipConfigurations: [\n      {\n        name: 'ipconfig'\n        properties: {\n          subnet: {\n            id: subnet.id\n          }\n        }\n      }\n    ]\n  }\n}]\n\n", "note": "Uma interface de rede por zona, com o nome dela: `shop-web-z1-nic` e `shop-web-z2-nic`."}, {"code": "resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = [for (zone, i) in zones: {\n  name: 'shop-web-z${zone}'\n  location: location\n  zones: [zone]\n  properties: {\n    hardwareProfile: {\n      vmSize: 'Standard_D2s_v5'\n    }\n", "note": "**Cada máquina é zonal.** `zones` recebe uma lista, e uma máquina aceita um item nela; `[zone]` é o desta cópia. `(zone, i)` dá ao laço o item e a sua posição, que escolhe a interface abaixo."}, {"code": "    storageProfile: {\n      imageReference: {\n        publisher: 'Canonical'\n        offer: 'ubuntu-24_04-lts'\n        sku: 'server'\n        version: 'latest'\n      }\n      osDisk: {\n        createOption: 'FromImage'\n        managedDisk: {\n          storageAccountType: 'Premium_LRS'\n        }\n      }\n    }\n    osProfile: {\n      computerName: 'shop-web-z${zone}'\n      adminUsername: adminUsername\n      linuxConfiguration: {\n        disablePasswordAuthentication: true\n        ssh: {\n          publicKeys: [\n            {\n              path: '/home/${adminUsername}/.ssh/authorized_keys'\n              keyData: sshPublicKey\n            }\n          ]\n        }\n      }\n    }\n    networkProfile: {\n      networkInterfaces: [\n        {\n          id: nic[i].id\n        }\n      ]\n    }\n  }\n}]\n", "note": "Como no arquivo do conjunto, exceto o nome. Os discos de uma máquina zonal são criados na zona dela, então `Premium_LRS` aqui quer dizer três cópias dentro da zona 1 para a primeira máquina e dentro da zona 2 para a segunda."}]}
```

Compile-o:

```
ana@laptop:~/azure$ bicep build shop-zones.bicep
ana@laptop:~/azure$ jq -c ".resources[] | {type, name, zones, sku}" shop-zones.json
{"type":"Microsoft.Network/publicIPAddresses","name":"shop-lb-ip","zones":["1","2","3"],"sku":{"name":"Standard","tier":"Regional"}}
{"type":"Microsoft.Network/networkInterfaces","name":"[format('shop-web-z{0}-nic', variables('zones')[copyIndex()])]","zones":null,"sku":null}
{"type":"Microsoft.Compute/virtualMachines","name":"[format('shop-web-z{0}', variables('zones')[copyIndex()])]","zones":["[variables('zones')[copyIndex()]]"],"sku":null}
```

O endereço mantém as suas três zonas como foram escritas. A zona da máquina virou uma expressão,
porque vem do laço: `variables('zones')[copyIndex()]` é "a zona desta cópia", `1` para a primeira
máquina e `2` para a segunda. A linha de comando pede as mesmas duas coisas:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-zone -z : [^.]*\."
--zone -z : Availability zone into which to provision the resource.
ana@laptop:~/azure$ az network public-ip create --help | tr -s "[:space:]" " " | grep -o "\-\-zone -z : [^.]*\.\|\-\-sku : [^.]*\.[^.]*\."
--sku : Name of a public IP address SKU. Allowed values: Basic, Standard, StandardV2.
--zone -z : Space-separated list of availability zones into which to provision the resource.
```

**Uma máquina recebe uma zona e um endereço recebe uma lista**: uma zona para um endereço zonal,
todas as da região para um com redundância de zona. A página da Microsoft sobre endereços IP
públicos acrescenta o que a ajuda não diz sobre os três SKUs que ela lista. `Basic` foi aposentado
em 30 de setembro de 2025 e nunca teve zonas, e `StandardV2` sempre tem redundância de zona onde a
região tem zonas. Um endereço Standard criado sem zonas numa região que as tem fica com
redundância de zona, então `zones: ['1', '2', '3']` e nenhuma zona querem dizer a mesma coisa ali; o
arquivo escreve as três para que quem o lê não precise saber disso. E um endereço não pode mudar de
zona depois de criado.

## A zona 1 é um rótulo, não um prédio

O número de uma zona é **lógico**. O Resource Manager mapeia os números de zona de cada assinatura
para zonas físicas, e a descrição do SDK para a lista de locais diz isso em dois campos:

```
ana@laptop:~/azure$ grep -h -A3 ':ivar logical_zone:' venv/lib/python3.12/site-packages/azure/mgmt/resource/subscriptions/v2022_12_01/models/_models_py3.py
    :ivar logical_zone: The logical zone id for the availability zone.
    :vartype logical_zone: str
    :ivar physical_zone: The fully qualified physical zone id of availability zone to which logical
     zone id is mapped to.
```

O mapeamento é devolvido por assinatura, e é para isso que ele é devolvido: a zona `1` na assinatura
da loja e a zona `1` na da equipe financeira não têm a promessa de ser o mesmo prédio. Duas
assinaturas que se espalham cada uma pelas zonas `1` e `2` ainda podem dividir uma zona física, e um
projeto que depende de duas assinaturas estarem em zonas diferentes tem de ler os dois mapeamentos.
Isto os lê para a assinatura em que você entrou; precisa de uma, e não foi executado neste curso:

```sh
az rest --method get --uri "https://management.azure.com/subscriptions/{subscriptionId}/locations?api-version=2022-12-01" --query "value[?name=='brazilsouth'].availabilityZoneMappings"
```

## O que o compilador confere aqui

Uma cópia do arquivo com dois erros: as zonas do endereço escritas como números, e as máquinas
postas nas zonas `1` e `4`:

```
ana@laptop:~/azure$ sed -e "s/zones: \['1', '2', '3'\]/zones: [1, 2, 3]/" -e "s/var zones = \['1', '2'\]/var zones = ['1', '4']/" shop-zones.bicep > zones-wrong.bicep
ana@laptop:~/azure$ diff shop-zones.bicep zones-wrong.bicep
6c6
< var zones = ['1', '2']
---
> var zones = ['1', '4']
20c20
<   zones: ['1', '2', '3']
---
>   zones: [1, 2, 3]
ana@laptop:~/azure$ bicep build zones-wrong.bicep
/home/ana/azure/zones-wrong.bicep(20,11) : Warning BCP034: The enclosing array expected an item of type "string", but the provided item was of type "1". [https://aka.ms/bicep/core-diagnostics#BCP034]
/home/ana/azure/zones-wrong.bicep(20,14) : Warning BCP034: The enclosing array expected an item of type "string", but the provided item was of type "2". [https://aka.ms/bicep/core-diagnostics#BCP034]
/home/ana/azure/zones-wrong.bicep(20,17) : Warning BCP034: The enclosing array expected an item of type "string", but the provided item was of type "3". [https://aka.ms/bicep/core-diagnostics#BCP034]
```

**Três avisos para um erro, e nenhum para o outro.** Uma zona é uma string, então `1` sem aspas é
recusado uma vez por item. `'4'` é uma string, e uma região com três zonas não tem zona 4, mas o tipo
não sabe quantas zonas Brazil South tem. O Resource Manager recusaria o pedido, e um laptop não
consegue ver como.

A mesma cegueira cobre uma combinação. Um conjunto de disponibilidade e uma zona são duas respostas
para a mesma pergunta, e **uma máquina recebe uma ou a outra**: a página da Microsoft sobre a
disponibilidade de discos diz que conjuntos de disponibilidade não podem ser usados com zonas de
disponibilidade. Aqui está o arquivo do conjunto da seção anterior com uma zona acrescentada a cada
máquina:

```
ana@laptop:~/azure$ sed "/^resource vm/,/^  properties/s/^  location: location$/&\n  zones: ['1']/" shop-avset.bicep > both.bicep
ana@laptop:~/azure$ diff shop-avset.bicep both.bicep
46a47
>   zones: ['1']
ana@laptop:~/azure$ bicep build both.bicep
```

Nenhum aviso. Cada propriedade é válida sozinha, e a regra que proíbe o par não está no tipo.

## Zonas num scale set

O scale set da lição 4 recebeu `zones: ['1', '2', '3']`, o que o faz *abranger zonas*: cada
instância é zonal, presa a uma zona com os seus discos, e o scale set escolhe qual. Ele procura
manter as zonas *equilibradas*, o que a Microsoft define como cada zona com o mesmo número de
instâncias, mais ou menos uma, de modo que cinco instâncias em três zonas são duas, duas e uma.

O que acontece quando uma zona falha depende do modo de equilíbrio, escolhido no scale set:

- Melhor esforço, o padrão: o conjunto continua aumentando nas zonas que ainda funcionam e
  aceita o desequilíbrio enquanto uma zona está fora. Com duas ou mais zonas fora, ele para de
  escalar. Quando a zona volta, os aumentos seguintes acrescentam nela e as reduções tiram das
  cheias.
- Estrito: uma operação de escala que deixaria o conjunto desequilibrado é bloqueada, mesmo com
  uma zona fora.

Melhor esforço é o que mantém capacidade durante uma falha, que é quando a capacidade faz falta.
Mais duas coisas valem saber antes que surpreendam. **Acrescentar uma zona a um scale set existente
não move nada**: as instâncias ficam onde estão, e só as novas vão para a zona nova. E um conjunto
reequilibrado à mão é reequilibrado como a lição 4 descreveu a redução, acrescentando instâncias e
depois removendo outras, nunca movendo uma.
