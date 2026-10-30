---
title: Domínios de falha, domínios de atualização e o conjunto de disponibilidade
version: 1
---

Duas máquinas virtuais rodando o mesmo programa parecem redundância, e num diagrama são.
**Se são redundantes depende do que elas dividem.** Duas máquinas num mesmo host físico param
juntas quando esse host falha. Duas em hosts diferentes do mesmo rack param juntas quando o rack
perde a energia ou o switch de rede. Então redundância é sempre redundância contra alguma coisa, e
a pergunta a fazer de qualquer projeto é de que tamanho é a coisa que falha:

| o que falha | o que leva junto | o que mantém uma cópia fora disso |
|---|---|---|
| um host | toda máquina rodando nesse servidor | uma segunda máquina em outro host |
| a energia ou o switch de um rack | todo host do rack | um domínio de falha diferente |
| uma reinicialização planejada para manutenção | um grupo de hosts por vez | um domínio de atualização diferente |
| a energia, a refrigeração ou a rede de um datacenter | todo rack do prédio | uma zona de disponibilidade diferente |
| uma região | toda zona dela | uma segunda região |

Esta seção trata da segunda e da terceira linhas, que um conjunto de disponibilidade responde. A
próxima seção trata da quarta. A quinta é onde a lição 1 de `azure-foundations` parou, com o par de
cada região, e a seção 05 desta lição diz o que isso deixa para você fazer.

## Dois números para cada máquina

Quando uma máquina virtual é criada num conjunto de disponibilidade, o Azure dá a ela dois números,
e nenhum dos dois é você quem escolhe.

Um **domínio de falha** é um grupo de máquinas que dividem uma fonte de energia e um switch de rede.
Uma falha ali não é planejada: uma fonte queima, um switch para de encaminhar, e tudo o que está
atrás dele cai de uma vez. A visão geral da Microsoft sobre conjuntos de disponibilidade, lida em
2026-10-30, diz que um conjunto tem até 3 domínios de falha e que as suas máquinas são separadas
entre eles.

Um **domínio de atualização** é um grupo de máquinas, e do hardware sob elas, que pode ser
reiniciado ao mesmo tempo. Um conjunto tem até 20. Quando uma manutenção planejada precisa de
reinicialização, **só um domínio de atualização é reiniciado por vez**, e um domínio reiniciado tem
30 minutos para se recuperar antes que a manutenção comece no próximo. A documentação não promete a
ordem, só o um de cada vez.

Nenhuma das duas contagens pode ser mudada depois que o conjunto existe. Com cinco domínios de
atualização, a sexta máquina vai para o mesmo domínio de atualização da primeira, a sétima com a
segunda, e assim por diante. Aqui estão seis máquinas da API de pedidos da loja num conjunto de dois
domínios de falha e cinco domínios de atualização, e as duas coisas diferentes que podem acontecer
com elas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 206\" role=\"img\" aria-label=\"Duas grades do mesmo conjunto de disponibilidade, dois domínios de falha como linhas e cinco domínios de atualização como colunas, com seis máquinas: web-1, web-3 e web-5 no domínio de falha 0, sob os domínios de atualização 0, 2 e 4; web-2, web-4 e web-6 no domínio de falha 1, sob os domínios de atualização 1, 3 e 0. À esquerda: o domínio de falha 1 perde a energia e as suas três máquinas caem. À direita: a manutenção reinicia o domínio de atualização 2 e só web-3 cai.\"><text x=\"182\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">um rack perde a energia</text><text x=\"225.0\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">domínio de atualização</text><text x=\"129.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"177.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"225.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"273.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"321.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"14\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">domínio de falha 0</text><rect x=\"108\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"129.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-1</text><rect x=\"156\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"204\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-3</text><rect x=\"252\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"300\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"321.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-5</text><text x=\"14\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">domínio de falha 1</text><rect x=\"108\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"129.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">web-6</text><rect x=\"156\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"177.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">web-2</text><rect x=\"204\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"252\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"273.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">web-4</text><rect x=\"300\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"104\" y=\"116\" width=\"242\" height=\"44\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"182\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a linha cai: web-2, web-4 e web-6, três de seis</text><text x=\"538\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">a manutenção reinicia um domínio de atualização</text><text x=\"581.0\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">domínio de atualização</text><text x=\"485.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"533.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"581.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"629.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"677.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"370\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">domínio de falha 0</text><rect x=\"464\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-1</text><rect x=\"512\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"560\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"581.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">web-3</text><rect x=\"608\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"656\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"677.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-5</text><text x=\"370\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">domínio de falha 1</text><rect x=\"464\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-6</text><rect x=\"512\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"533.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-2</text><rect x=\"560\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"608\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"629.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-4</text><rect x=\"656\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"556\" y=\"70\" width=\"50\" height=\"90\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"538\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma coluna por vez: só web-3, cinco de seis respondem</text><path d=\"M360 36 L360 196\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "Seis máquinas da loja num conjunto de disponibilidade com dois domínios de falha e cinco domínios de atualização. Uma falha não planejada leva uma linha, e uma reinicialização planejada leva uma coluna. A sexta máquina divide o domínio de atualização 0 com a primeira, como a documentação diz que fará; em que domínio de falha cada uma cai é escolha do Azure, e esta é uma disposição que ele poderia fazer."}
```

A figura é o motivo de existirem os dois números. **Uma falha de rack leva uma linha, e uma
reinicialização de manutenção leva uma coluna**: metade da loja cai no primeiro caso, e cinco de
seis máquinas continuam respondendo no segundo. Qual máquina cai em qual domínio de falha é decisão
do Azure, então a figura é uma disposição que ele poderia fazer; a volta dos domínios de atualização
é a parte documentada.

A reinicialização é mais rara do que a figura faz parecer. A página da Microsoft sobre manutenção
diz que a maioria das atualizações da plataforma nem toca as máquinas. Quando uma precisa tocar,
quase sempre é uma pausa de menos de dez segundos, ou uma migração ao vivo da máquina em execução
para um host já atualizado, e esse tipo é aplicado um domínio de falha por vez. Uma manutenção que
precisa de reinicialização é anunciada antes, com uma fase de autoatendimento que costuma durar
quatro semanas, na qual você mesmo pode iniciá-la na hora que lhe convier. Os Scheduled Events da
lição 5 são como uma máquina fica sabendo de qualquer um dos dois tipos antes que aconteça.

## Os discos também se espalham

Os discos gerenciados de uma máquina ficam alinhados com o domínio de falha dela, então uma máquina
e os seus discos falham juntos ou não falham. Um conjunto cujo `sku` é `Aligned` é um conjunto
gerenciado, e só máquinas com discos gerenciados podem ser criadas num deles. **O número de domínios
de falha de disco varia por região: cada uma tem dois ou três.** A Microsoft documenta um comando
que lista, região por região, a maior contagem de domínios de falha que um conjunto alinhado pode
ter. Ele precisa de uma assinatura e não foi executado neste curso:

```sh
az vm list-skus --resource-type availabilitySets --query '[?name==`Aligned`].{Location:locationInfo[0].location, MaximumFaultDomainCount:capabilities[0].value}' -o Table
```

Uma sequência põe duas máquinas no mesmo domínio de falha mesmo assim: criar a primeira máquina,
pará-la e desalocá-la, e então criar a segunda. O disco da segunda máquina pode cair no domínio de
falha em que estava a primeira. O conselho documentado é deixar a primeira rodando até a segunda
existir.

## O conjunto, em Bicep

Duas máquinas da API de pedidos da loja, `shop-web-1` e `shop-web-2`, num conjunto. O load balancer
da lição 22 de `azure-foundations` ficaria na frente delas, e o arquivo o deixa de fora para ficar no
assunto desta lição. Salve-o como `shop-avset.bicep`:

```schooling-example
{"language": "bicep", "file": "shop-avset.bicep", "parts": [{"code": "// shop-avset.bicep\nparam location string = 'brazilsouth'\nparam adminUsername string = 'ana'\nparam sshPublicKey string\n\nresource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {\n  name: 'shop-vnet'\n}\n\nresource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {\n  parent: vnet\n  name: 'app'\n}\n\n", "note": "Aquilo sobre o que as máquinas se apoiam, nomeado e não criado: a rede da lição 16 de `azure-foundations` e a sua sub-rede `app`. `sshPublicKey` não tem valor padrão, então quem implanta o arquivo fornece uma chave."}, {"code": "resource avset 'Microsoft.Compute/availabilitySets@2024-07-01' = {\n  name: 'shop-avset'\n  location: location\n  sku: {\n    name: 'Aligned'\n  }\n  properties: {\n    platformFaultDomainCount: 2\n    platformUpdateDomainCount: 5\n  }\n}\n\n", "note": "**O próprio conjunto.** `Aligned` faz dele um conjunto gerenciado, o tipo em que entram máquinas com discos gerenciados. As duas contagens ficam fixas pela vida do conjunto: dois domínios de falha, que os discos de toda região conseguem acompanhar, e cinco domínios de atualização."}, {"code": "resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = [for i in range(1, 2): {\n  name: 'shop-web-${i}-nic'\n  location: location\n  properties: {\n    ipConfigurations: [\n      {\n        name: 'ipconfig'\n        properties: {\n          subnet: {\n            id: subnet.id\n          }\n        }\n      }\n    ]\n  }\n}]\n\n", "note": "Uma interface de rede por máquina. `range(1, 2)` são dois números a partir de 1, então o laço cria `shop-web-1-nic` e `shop-web-2-nic`."}, {"code": "resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = [for i in range(1, 2): {\n  name: 'shop-web-${i}'\n  location: location\n  properties: {\n    availabilitySet: {\n      id: avset.id\n    }\n    hardwareProfile: {\n      vmSize: 'Standard_D2s_v5'\n    }\n", "note": "**A linha que põe cada máquina no conjunto.** Ela é escrita na máquina, e só na criação. O tamanho é o padrão da lição 1, `Standard_D2s_v5`."}, {"code": "    storageProfile: {\n      imageReference: {\n        publisher: 'Canonical'\n        offer: 'ubuntu-24_04-lts'\n        sku: 'server'\n        version: 'latest'\n      }\n      osDisk: {\n        createOption: 'FromImage'\n        managedDisk: {\n          storageAccountType: 'Premium_LRS'\n        }\n      }\n    }\n    osProfile: {\n      computerName: 'shop-web-${i}'\n      adminUsername: adminUsername\n      linuxConfiguration: {\n        disablePasswordAuthentication: true\n        ssh: {\n          publicKeys: [\n            {\n              path: '/home/${adminUsername}/.ssh/authorized_keys'\n              keyData: sshPublicKey\n            }\n          ]\n        }\n      }\n    }\n    networkProfile: {\n      networkInterfaces: [\n        {\n          id: nic[i - 1].id\n        }\n      ]\n    }\n  }\n}]\n", "note": "O resto é uma máquina Linux qualquer, como a lição 2 a escreveu. `Premium_LRS` é o tipo de disco de que depende o número de uma máquina sozinha, na próxima seção; num conjunto, vale o número do conjunto. `nic[i - 1]` é a interface desta máquina, porque o laço conta a partir de 1 e a lista a partir de 0."}]}
```

Compile-o, e veja o que o template guarda:

```
ana@laptop:~/azure$ bicep build shop-avset.bicep
ana@laptop:~/azure$ jq -c ".resources[] | {type, name, copy: .copy.count}" shop-avset.json
{"type":"Microsoft.Compute/availabilitySets","name":"shop-avset","copy":null}
{"type":"Microsoft.Network/networkInterfaces","name":"[format('shop-web-{0}-nic', range(1, 2)[copyIndex()])]","copy":"[length(range(1, 2))]"}
{"type":"Microsoft.Compute/virtualMachines","name":"[format('shop-web-{0}', range(1, 2)[copyIndex()])]","copy":"[length(range(1, 2))]"}
ana@laptop:~/azure$ jq ".resources[0].properties" shop-avset.json
{
  "platformFaultDomainCount": 2,
  "platformUpdateDomainCount": 5
}
```

Três recursos, dois deles escritos uma vez e criados duas: `copy` é como o template diz "esta
quantidade", e o laço virou um. As duas contagens entraram no template como os números escritos.
Eis o que a linha de comando faz quando ninguém as escreve:

```
ana@laptop:~/azure$ az vm availability-set create --help | tr -s "[:space:]" " " | grep -o "\-\-platform-[a-z-]*-count : [^.]*\.[^.]*\."
--platform-fault-domain-count : Fault Domain count. Default: 2.
--platform-update-domain-count : Update Domain count. If unspecified, the server will pick the most optimal number like 5.
```

Então um conjunto criado pela CLI sem contagens recebe dois domínios de falha, e o servidor escolhe
os domínios de atualização. O arquivo da loja escreve as duas. **Dois é uma contagem de domínios de
falha que os discos de toda região conseguem acompanhar.** Com dois domínios de falha e cinco de
atualização, as duas máquinas ficam em domínios de atualização diferentes, porque a volta só começa
na sexta, e o conjunto as separa entre os seus domínios de falha. Uma falha de rack leva no máximo
uma delas, e uma reinicialização de manutenção também.

## Uma máquina entra num conjunto quando é criada, ou nunca

O conjunto é nomeado dentro da máquina, em `properties.availabilitySet`, e não o contrário. Essa
direção tem uma consequência que o SDK instalado com a CLI escreve na sua própria descrição da
propriedade:

```
ana@laptop:~/azure$ grep -m1 -A10 ':ivar availability_set:' venv/lib/python3.12/site-packages/azure/mgmt/compute/v2024_11_01/models/_models_py3.py
    :ivar availability_set: Specifies information about the availability set that the virtual
     machine should be assigned to. Virtual machines specified in the same availability set are
     allocated to different nodes to maximize availability. For more information about availability
     sets, see `Availability sets overview
     <https://docs.microsoft.com/azure/virtual-machines/availability-set-overview>`_. For more
     information on Azure planned maintenance, see `Maintenance and updates for Virtual Machines in
     Azure <https://docs.microsoft.com/azure/virtual-machines/maintenance-and-updates>`_. Currently,
     a VM can only be added to availability set at creation time. The availability set to which the
     VM is being added should be under the same resource group as the availability set resource. An
     existing VM cannot be added to an availability set. This property cannot exist along with a
     non-null properties.virtualMachineScaleSet reference.
```

**Uma máquina em execução não pode ser movida para um conjunto.** Se `shop-web-1` já roda sozinha, o
caminho para um conjunto é uma máquina nova criada nele, então o conjunto é decidido antes da
primeira implantação. Implantar o arquivo seria o comando abaixo, não executado neste curso, porque
precisa de uma assinatura e de duas máquinas que são cobradas:

```sh
az deployment group create --resource-group shop --template-file shop-avset.bicep --parameters sshPublicKey="$(cat ~/.ssh/id_ed25519.pub)"
```

## O que o compilador confere aqui

Uma cópia do arquivo com dois erros: quatro domínios de falha, quando um conjunto tem no máximo
três, e a contagem de domínios de atualização escrita como texto:

```
ana@laptop:~/azure$ sed -e 's/platformFaultDomainCount: 2/platformFaultDomainCount: 4/' -e "s/platformUpdateDomainCount: 5/platformUpdateDomainCount: '5'/" shop-avset.bicep > avset-wrong.bicep
ana@laptop:~/azure$ diff shop-avset.bicep avset-wrong.bicep
22,23c22,23
<     platformFaultDomainCount: 2
<     platformUpdateDomainCount: 5
---
>     platformFaultDomainCount: 4
>     platformUpdateDomainCount: '5'
ana@laptop:~/azure$ bicep build avset-wrong.bicep
/home/ana/azure/avset-wrong.bicep(23,32) : Warning BCP036: The property "platformUpdateDomainCount" expected a value of type "int | null" but the provided value is of type "'5'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

**Um aviso, para dois erros.** Texto onde cabe um número é um erro de tipo, e o compilador conhece o
tipo. Quatro é um número. Que um conjunto pare em três domínios de falha, e nos dois ou três que os
discos da sua região têm, está escrito na documentação da Microsoft e não no tipo, então só o
Resource Manager recusaria, na implantação. A regra da lição 1 outra vez: nenhum aviso quer dizer que
a forma está certa, não os valores.

## Perto de propósito

Espalhar máquinas custa distância, e algumas cargas preferem pagar do outro jeito. Um **grupo de
posicionamento por proximidade** (proximity placement group) é um recurso que mantém fisicamente
perto as máquinas nomeadas nele, para a menor latência de rede entre elas. Ele é uma restrição de
colocação: o primeiro recurso implantado nele o prende a um datacenter, e ele fica solto de novo
quando todos foram desalocados ou excluídos. Um conjunto de disponibilidade ou um scale set entra num
deles inteiro, no nível do conjunto e não máquina por máquina. **Ele anda na direção
oposta a tudo o mais nesta lição**, trocando a proteção da distância por velocidade, e a seção 05
diz quando essa troca vale a pena.
