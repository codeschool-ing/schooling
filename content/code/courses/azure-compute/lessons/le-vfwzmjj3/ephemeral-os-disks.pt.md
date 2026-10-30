---
title: Discos do SO efêmeros, para máquinas que não guardam nada
version: 1
---

O disco do SO parece ser o único disco que tem de estar a salvo, já que a máquina não dá boot sem
ele. Para uma máquina que não guarda nada de seu, essa segurança é paga e nunca usada. **Um disco do
SO efêmero é gravado no armazenamento local do host em vez do Azure Storage**. A máquina dá boot
nele e lê e grava nele na velocidade local, e o que ela gravou se perde quando ela é levada para
outro host por um redimensionamento, uma reimplantação ou um reparo. O que você ganha em troca é latência menor no
disco do SO e uma reimagem rápida, porque uma cópia nova da imagem é tudo o que há para restaurar.

## Onde ele fica

O disco vai para o armazenamento local que o tamanho tiver, e o `diffDiskSettings` da declaração diz
qual:

| posição | o armazenamento local | tamanhos que têm |
| --- | --- | --- |
| `CacheDisk` | o cache do host dos tamanhos antigos | Dsv2, Dsv3 |
| `ResourceDisk` | o disco temporário | tamanhos que têm um, como Ddsv5 e Dadsv5 |
| `NvmeDisk` | discos NVMe locais | v6 em diante, como Ddsv6 e Dadsv6 |

A Microsoft recomenda as séries atuais com `ResourceDisk` ou `NvmeDisk`. A posição muda onde o disco
fica e nada no custo nem na velocidade, que vêm desse armazenamento. A imagem tem de caber: a
Microsoft dá a imagem do Ubuntu Server como cerca de 30 GiB, então um disco temporário de 30 GiB ou
mais a recebe, e **o disco temporário encolhe então do tamanho da imagem**. Um `Standard_D2ds_v5`
tem um disco temporário de 75 GiB, que fica com 45 depois que o disco do SO vai para ele. O Trusted
Launch reserva mais 1 GiB para o estado de convidado da máquina. A Microsoft cita a recusa para
uma imagem de 75 GiB num `Standard_D2ads_v5`, cujo disco temporário também tem 75 GiB: *OS disk of
Ephemeral VM with size greater than 74 GB is not allowed*.

Por padrão o disco tem **cache parcial**: as gravações vão para o host e os blocos originais da
imagem são lidos de um disco gerenciado por trás, cujo tipo você escolhe: Standard HDD, Standard
SSD ou Premium SSD. **O cache completo** põe o disco do SO inteiro no host, então a máquina deixa
de precisar do armazenamento remoto depois que está rodando. Ele ocupa o dobro do tamanho do disco
do SO mais 1 GiB de armazenamento local, e a Microsoft só o oferece em tamanhos de oito vCPUs ou
mais.

## Do que você abre mão

A comparação da Microsoft, com as linhas que decidem se uma máquina pode ter um:

| | disco do SO persistente | disco do SO efêmero |
| --- | --- | --- |
| parar e desalocar | suportado | **não suportado** |
| mudar para outro tamanho | disco do SO mantido | disco do SO apagado, SO provisionado de novo |
| reimplantar em outro host | disco do SO mantido | disco do SO apagado, SO provisionado de novo |
| uma falha de host que o Azure repara | disco do SO mantido | **não mantido** |
| migração ao vivo durante manutenção | disco do SO mantido | mantido |
| redimensionar o disco do SO | na criação, ou desalocada | só na criação |

**Não existe parar e desalocar**, e é a linha que surpreende: uma máquina com disco do SO efêmero
que não é necessária esta noite é apagada, não parada, e criada de novo amanhã. As perguntas
frequentes da Microsoft dizem o mesmo para máquinas Spot, lição 5. O disco também não aceita
snapshot nem captura como imagem, e Azure Backup, Azure Site Recovery e Azure Disk Encryption não se
aplicam a ele. Discos de dados continuam aceitando: uma máquina com disco do SO efêmero pode ter
discos de dados gerenciados ligados, e eles se comportam exatamente como na primeira etapa.

## Por que um scale set os quer

Imagine a API de pedidos da loja em seis servidores web atrás de um balanceador de carga. Cada byte
nos discos do SO deles veio da imagem da lição 2 e do arquivo cloud-init dela; os pedidos moram no
banco de dados, e os logs são mandados para outro lugar. Um servidor web que falha é substituído,
não consertado. **Para uma máquina assim, um disco do SO persistente é uma cópia que ninguém nunca
vai ler**, e reimagem a partir da imagem é o conserto. Os scale sets da lição 4 fazem exatamente
isso, substituindo ou reimageando uma instância como o jeito normal de lidar com ela, e criam muitas
de uma vez, onde uma implantação mais rápida faz diferença.

O banco de dados da loja é o caso oposto, e fica com os discos persistentes da primeira etapa.

## Declarando um

O servidor web da lição 2, num tamanho com disco temporário e com o disco do SO efêmero. Salve como
`web.bicep`:

```bicep
// web.bicep
param location string = 'brazilsouth'
param adminUsername string = 'ana'
param sshPublicKey string
param nicId string

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'shop-web-1'
  location: location
  zones: [
    '1'
  ]
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2ds_v5'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadOnly'
        diffDiskSettings: {
          option: 'Local'
          placement: 'ResourceDisk'
        }
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    osProfile: {
      computerName: 'shop-web-1'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId
        }
      ]
    }
  }
}
```

Três linhas fazem a diferença. `option: 'Local'` é o que torna o disco efêmero, `placement:
'ResourceDisk'` o põe no disco temporário do `D2ds_v5`, e o cache é `ReadOnly`, que o guia de
implantação da Microsoft exige para um disco do SO efêmero. A CLI oferece a mesma escolha como duas
opções do `az vm create`:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-ephemeral-os-disk : [^.]*\.[^-]*"
--ephemeral-os-disk : Allows you to create an OS disk directly on the host node, providing local disk performance and faster VM/VMSS reimage time. Allowed values: false, true. 
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-ephemeral-os-disk-placement --ephemeral-placement : [^.]*\.[^.]*\.[^-]*"
--ephemeral-os-disk-placement --ephemeral-placement : Only applicable when used with `--ephemeral-os- disk`. Allows you to choose the Ephemeral OS disk provisioning location. Allowed values: CacheDisk, NvmeDisk, ResourceDisk. 
```

E o compilador:

```
ana@laptop:~/azure$ bicep build web.bicep
ana@laptop:~/azure$ jq ".resources[0].properties.storageProfile.osDisk" web.json
{
  "createOption": "FromImage",
  "caching": "ReadOnly",
  "diffDiskSettings": {
    "option": "Local",
    "placement": "ResourceDisk"
  }
}
```

Agora os dois erros que mais importam aqui, feitos juntos numa cópia: cache `ReadWrite`, que o guia
não permite, e uma posição chamada `TempDisk`, que é como as páginas da Microsoft chamam a posição
cujo valor é `ResourceDisk`:

```
ana@laptop:~/azure$ bicep build web-wrong.bicep
ana@laptop:~/azure$ jq -c ".resources[0].properties.storageProfile.osDisk | {caching, diffDiskSettings}" web-wrong.json
{"caching":"ReadWrite","diffDiskSettings":{"option":"Local","placement":"TempDisk"}}
ana@laptop:~/azure$ grep -n -A1 "placement" web-full.bicep
29:          placement: 'ResourceDisk'
30-          enableFullCaching: true
ana@laptop:~/azure$ bicep build web-full.bicep
/home/ana/azure/web-full.bicep(30,11) : Warning BCP037: The property "enableFullCaching" is not allowed on objects of type "DiffDiskSettings". No other properties are allowed. If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP037]
ana@laptop:~/azure$ bicep build web-full-2504.bicep
/home/ana/azure/web-full-2504.bicep(30,11) : Warning BCP037: The property "enableFullCaching" is not allowed on objects of type "DiffDiskSettings". No other properties are allowed. If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP037]
ana@laptop:~/azure$ bicep build web-full-2511.bicep
```

**Nenhum dos dois foi pego.** A posição é um texto que o compilador só confere como texto, e
`ReadWrite` é um dos três valores que ele conhece; se um disco do SO efêmero pode tê-lo é uma regra
do serviço. Os dois entraram no template como escritos, e os dois ficam para o Azure julgar quando o
pedido chegar.

Os três últimos builds pediram cache completo, `enableFullCaching`. Na `2024-07-01`, a versão de API
que este curso usa para máquinas, e na `2025-04-01`, o compilador não conhecia a propriedade; na
`2025-11-01` compilou sem nada. O guia da Microsoft diz `2025-04-01` ou posterior, então os tipos
do compilador e a documentação discordam sobre uma versão, que é o tipo de caso para o qual existe a
frase do aviso sobre definições de tipo imprecisas. Isso não importa para o `shop-web-1`: com duas
vCPUs, o `D2ds_v5` fica abaixo das oito que o cache completo pede, e as cópias foram um teste do
compilador, não uma mudança no arquivo.
