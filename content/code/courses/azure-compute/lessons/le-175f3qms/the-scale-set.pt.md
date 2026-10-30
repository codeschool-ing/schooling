---
title: "O scale set: um modelo e uma contagem"
version: 1
---

A primeira imagem que quase todo mundo tem de um scale set é a de um grupo de máquinas virtuais
criadas juntas, que cresce quando o tráfego sobe. As duas metades estão um pouco erradas. **Um scale
set é um modelo e um número**: a descrição de uma instância, chamada de perfil de máquina virtual, e
quantas instâncias devem existir. O Azure cria instâncias a partir do perfil até a contagem ser
atingida, e as apaga quando a contagem cai. O crescer não é do scale set. É de um segundo recurso,
uma configuração de autoscale, que move o número; a seção 04 desta lição escreve uma.

## O que o arquivo declara

A API de pedidos da loja roda em três instâncias, uma em cada zona de São Paulo, atrás do load
balancer que a lição 22 de `azure-foundations` construiu. Aqui está o scale set que as guarda, como
um arquivo Bicep. Salve-o como `shop-vmss.bicep`; ele é longo, e cada parte diz para que serve:

```schooling-example
{"language": "bicep", "file": "shop-vmss.bicep", "parts": [{"code": "// shop-vmss.bicep\nparam location string = 'brazilsouth'\nparam adminUser string = 'ana'\nparam adminKey string\n\nresource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {\n  name: 'shop-vnet'\n}\n\nresource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {\n  parent: vnet\n  name: 'app'\n}\n\nresource lb 'Microsoft.Network/loadBalancers@2024-05-01' existing = {\n  name: 'shop-lb'\n}\n\nresource pool 'Microsoft.Network/loadBalancers/backendAddressPools@2024-05-01' existing = {\n  parent: lb\n  name: 'shop-pool'\n}\n\nresource gallery 'Microsoft.Compute/galleries@2024-03-03' existing = {\n  name: 'shopgallery'\n}\n\nresource image 'Microsoft.Compute/galleries/images@2024-03-03' existing = {\n  parent: gallery\n  name: 'shop'\n}\n\n", "note": "Aquilo sobre o que o scale set se apoia, nomeado e não criado. `existing` aponta para a rede da lição 16 de `azure-foundations`, para o load balancer e seu backend pool da lição 22, e para uma imagem da loja numa galeria, como a que a lição 2 publica; os nomes aqui são desta lição. `adminKey` não tem valor padrão, então quem implanta o arquivo fornece uma chave pública."}, {"code": "resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2024-11-01' = {\n  name: 'shop-vmss'\n  location: location\n  zones: ['1', '2', '3']\n  sku: {\n    name: 'Standard_D2s_v5'\n    tier: 'Standard'\n    capacity: 3\n  }\n  properties: {\n", "note": "O tamanho de cada instância, e a contagem. `sku.name` é um tamanho do tipo que a lição 1 leu letra por letra; `capacity` é quantas instâncias o scale set deve ter agora, e é o número que o autoscale move. `zones` deixa o conjunto usar as três zonas de `brazilsouth`."}, {"code": "    orchestrationMode: 'Flexible'\n    platformFaultDomainCount: 1\n    singlePlacementGroup: false\n", "note": "Três linhas que fazem dele um scale set Flexible, o assunto da próxima seção. O modo é escolhido uma vez, quando o conjunto é criado."}, {"code": "    scaleInPolicy: {\n      rules: ['Default']\n    }\n", "note": "Qual instância sai quando a contagem cai. `Default` é o que o Azure aplica quando nada está escrito; está explícito para que a escolha possa ser lida."}, {"code": "    upgradePolicy: {\n      mode: 'Rolling'\n      rollingUpgradePolicy: {\n        maxBatchInstancePercent: 20\n        maxUnhealthyInstancePercent: 20\n        maxUnhealthyUpgradedInstancePercent: 20\n        pauseTimeBetweenBatches: 'PT2M'\n      }\n    }\n    automaticRepairsPolicy: {\n      enabled: true\n      gracePeriod: 'PT30M'\n      repairAction: 'Replace'\n    }\n", "note": "O que acontece com as instâncias em execução quando o modelo muda, e com uma instância que para de responder. A seção 05 desta lição lê as duas coisas."}, {"code": "    virtualMachineProfile: {\n      storageProfile: {\n        imageReference: {\n          id: image.id\n        }\n        osDisk: {\n          createOption: 'FromImage'\n          managedDisk: {\n            storageAccountType: 'Premium_LRS'\n          }\n        }\n      }\n      osProfile: {\n        computerNamePrefix: 'shop'\n        adminUsername: adminUser\n        linuxConfiguration: {\n          disablePasswordAuthentication: true\n          ssh: {\n            publicKeys: [\n              {\n                path: '/home/${adminUser}/.ssh/authorized_keys'\n                keyData: adminKey\n              }\n            ]\n          }\n        }\n      }\n", "note": "O perfil de que toda instância nova é feita: a imagem, o disco do sistema operacional, um prefixo de nome e a chave para entrar. O Azure acrescenta um número a `shop` para cada instância que cria."}, {"code": "      networkProfile: {\n        networkApiVersion: '2020-11-01'\n        networkInterfaceConfigurations: [\n          {\n            name: 'shop-nic'\n            properties: {\n              primary: true\n              ipConfigurations: [\n                {\n                  name: 'ipconfig'\n                  properties: {\n                    subnet: {\n                      id: subnet.id\n                    }\n                    loadBalancerBackendAddressPools: [\n                      {\n                        id: pool.id\n                      }\n                    ]\n                  }\n                }\n              ]\n            }\n          }\n        ]\n      }\n", "note": "Cada instância ganha uma interface de rede na sub-rede, e o endereço dela entra no backend pool do load balancer, então o tráfego chega a uma instância nova sem ninguém mexer no balanceador. `networkApiVersion` é a linha que o próprio template da Microsoft para um scale set Flexible traz, com este valor."}, {"code": "      extensionProfile: {\n        extensions: [\n          {\n            name: 'health'\n            properties: {\n              publisher: 'Microsoft.ManagedServices'\n              type: 'ApplicationHealthLinux'\n              typeHandlerVersion: '1.0'\n              autoUpgradeMinorVersion: true\n              settings: {\n                protocol: 'http'\n                port: 8080\n                requestPath: '/healthz'\n                intervalInSeconds: 5\n                numberOfProbes: 3\n              }\n            }\n          }\n        ]\n      }\n    }\n  }\n}\n", "note": "A extensão Application Health, que roda dentro de cada instância e pergunta ao `/healthz` da loja a cada cinco segundos. A seção 05 diz por que a versão `1.0` e não a `2.0`."}]}
```

Há quatro coisas nele, e são o que todo scale set guarda:

- o perfil, `virtualMachineProfile`: a imagem, o disco, as configurações do sistema operacional,
  a interface de rede e as extensões, de que toda instância é feita;
- o tamanho e a contagem, em `sku`: `Standard_D2s_v5` para toda instância, e `capacity: 3`;
- as zonas em que as instâncias podem ficar, que a lição 6 pesa contra o que custam;
- o backend pool do load balancer, nomeado dentro da interface de rede.

A última passa despercebida com facilidade. Uma instância criada às duas da manhã entra no pool por
ter sido criada, e é por isso que ninguém precisa editar o balanceador quando a contagem muda.
Compile o arquivo:

```
ana@laptop:~/azure$ bicep build shop-vmss.bicep
ana@laptop:~/azure$ ls
shop-vmss.bicep
shop-vmss.json
venv
ana@laptop:~/azure$ jq ".resources[] | {type, apiVersion, name, zones, sku}" shop-vmss.json
{
  "type": "Microsoft.Compute/virtualMachineScaleSets",
  "apiVersion": "2024-11-01",
  "name": "shop-vmss",
  "zones": [
    "1",
    "2",
    "3"
  ],
  "sku": {
    "name": "Standard_D2s_v5",
    "tier": "Standard",
    "capacity": 3
  }
}
```

Nenhum aviso, então todo nome e tipo de propriedade bate com o que a Microsoft publica para
`Microsoft.Compute/virtualMachineScaleSets` na versão de API `2024-11-01`. **O template guarda um
recurso, e as seis declarações `existing` não estão nele.** Eram nomes, e o compilador transformou
cada um numa expressão que o Resource Manager resolve quando o template é implantado:

```
ana@laptop:~/azure$ jq ".resources[0].properties.virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].properties.ipConfigurations[0].properties" shop-vmss.json
{
  "subnet": {
    "id": "[resourceId('Microsoft.Network/virtualNetworks/subnets', 'shop-vnet', 'app')]"
  },
  "loadBalancerBackendAddressPools": [
    {
      "id": "[resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'shop-lb', 'shop-pool')]"
    }
  ]
}
```

Então o compilador conferiu que o backend pool está nomeado no formato certo. Ele não tem como saber
se existe um load balancer chamado `shop-lb` na sua assinatura; isso é respondido na implantação,
com uma recusa se não existir. Implantar o arquivo seria este comando, que não foi rodado neste curso
porque precisa de uma assinatura e as três máquinas que ele cria seriam cobradas:

```sh
az deployment group create --resource-group shop --template-file shop-vmss.bicep --parameters adminKey="$(cat ~/.ssh/id_ed25519.pub)"
```

## A contagem, à mão

`capacity` é um número que se muda sem mexer em mais nada. A Microsoft documenta para isso o
`az vmss scale --resource-group shop --name shop-vmss --new-capacity 5`, não rodado aqui: o Azure cria
duas instâncias a partir do perfil, põe cada uma de modo que as zonas fiquem equilibradas, e elas
entram no backend pool. O mesmo número é o que o autoscale muda, e os dois não o dividem com
educação. **Uma contagem posta à mão fora do mínimo e do máximo da configuração de autoscale volta
para dentro na execução seguinte do autoscale.** A orientação da Microsoft dá o exemplo de uma faixa
de 3 a 6: ponha oito à mão e na execução seguinte são seis de novo.

O scale set em si não custa nada. A visão geral da Microsoft, lida em 2026-10-30, diz que se paga
pela computação, rede e armazenamento que as instâncias usam, e que um scale set Flexible guarda até
1.000 delas.

## Um modelo, e instâncias que podem diferir dele

Como o perfil é um modelo, mudá-lo muda as instâncias que ainda não foram criadas. Troque o tamanho
no arquivo para `Standard_D4s_v5` e implante de novo, e as instâncias que já rodam continuam
`D2s_v5`; a próxima criada é uma `D4s_v5`. **Se as que rodam são alinhadas com o modelo, quando, e
quantas de cada vez, é decisão da política de upgrade**, e a seção 05 desta lição a lê. Até lá, um
scale set cujo modelo foi editado guarda instâncias de dois tipos, e esse é um estado normal para
ele.

## Qual instância sai quando a contagem cai

Quando a contagem cai de cinco para quatro, o Azure tem de escolher qual instância apagar. A
**política de redução** (scale-in policy) no modelo decide. Ela tem três valores:

- `Default` equilibra o conjunto entre as zonas primeiro, depois entre os domínios de falha até
  onde consegue, e então apaga a instância com o maior instance id;
- `NewestVM` apaga a instância criada mais recentemente, depois de equilibrar as zonas;
- `OldestVM` apaga a mais antiga, depois de equilibrar as zonas.

O equilíbrio vem primeiro nas três, e é feito apagando, nunca movendo uma instância. Com três de
cinco instâncias na zona 1 e uma em cada uma das zonas 2 e 3, a próxima redução tira uma instância da
zona 1 seja qual for a política, e a política só escolhe qual dessas três. O arquivo da loja escreve
`Default` embora o Azure o aplique quando a propriedade falta, para que a escolha fique no arquivo,
onde alguém pode lê-la.

`OldestVM` combina com instâncias que envelhecem mal, enchendo um disco de cache ou de logs.
`NewestVM` combina com um conjunto em que a instância mais nova é a menos testada, como as primeiras
instâncias de uma mudança que você quer poder desfazer reduzindo.

## Tirar uma instância da escolha

Às vezes uma instância está ocupada com algo que não pode ser interrompido, como o relatório noturno
de vendas. A **proteção de instância** marca essa instância, não o modelo, e vem em duas forças.
`protectFromScaleIn` a deixa fora da escolha do autoscale quando a contagem cai.
`protectFromScaleSetActions` também a deixa fora das operações iniciadas no scale set inteiro, como
um upgrade ou um reimage. Nenhuma das duas detém uma pessoa: apagar a instância à mão ainda a apaga.

Num scale set Flexible, a proteção de instância precisa da versão `2023-09-01` ou posterior da API
de Compute, e a `2024-11-01` do arquivo é. Uma instância protegida também é deixada em paz pelos
reparos automáticos, que a seção 05 explica.
