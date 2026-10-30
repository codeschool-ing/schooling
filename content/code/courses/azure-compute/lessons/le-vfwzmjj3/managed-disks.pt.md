---
title: Um disco é um recurso por si só
version: 1
---

Num laptop o disco fica dentro da máquina, e é fácil imaginar uma máquina virtual do Azure do
mesmo jeito. **Um disco gerenciado é um recurso por si só, ao lado da máquina virtual e não dentro
dela.** Ele tem nome, tipo, tamanho e uma linha própria na fatura, e mora no Azure Storage,
alcançado pela rede. A máquina se liga aos discos do mesmo jeito que se liga à interface de rede, e
um disco pode sobreviver à máquina, passar para outra ou ser copiado enquanto a máquina segue
rodando. A Microsoft o descreve como um volume de blocos em que você escolhe o tipo e o tamanho e o
Azure cuida do resto.

## Três papéis, e um deles não é um disco gerenciado

Toda máquina tem um **disco do SO**, feito a partir da imagem quando a máquina é criada, que foi o
assunto da lição 2. Ele guarda o volume de boot e pode ter até 4.095 GiB, embora uma imagem
particionada com master boot record, como muitas são, só consiga usar 2 TiB dele.

Os **discos de dados** são os que você acrescenta, e o tamanho da máquina decide quantos: a tabela
da lição 1 dava quatro a um `Standard_D2s_v5` e dezesseis a um `Standard_D8s_v5`. Cada um é ligado
num *LUN*, um número de unidade lógica a partir de 0, que é como o sistema operacional e a
declaração distinguem um do outro. O conselho da Microsoft é deixar a aplicação e seus dados nos
discos de dados e só o sistema operacional no disco do SO, para que cada um possa ter backup, ser
redimensionado e trocado por conta própria.

O terceiro é o **disco temporário**, que os tamanhos com `d` no nome trazem. Ele não é um disco
gerenciado. Fica no host onde a máquina roda, aparece no Linux como `/dev/disk/azure/resource` e
sobrevive a um reinício comum. A documentação da Microsoft diz que os dados dele podem se perder
num evento de manutenção, quando a máquina é reimplantada ou quando ela é parada, e que ele serve
para arquivos de paginação, swap e os arquivos de rascunho de um banco de dados, como o `tempdb` do
SQL Server.

```schooling-figure
{"svg": "<svg id=\"fig-disk-roles\" viewBox=\"0 0 720 332\" role=\"img\" aria-label=\"Duas caixas lado a lado. À esquerda, o host onde a máquina roda: a máquina virtual, um cache do host feito de memória e SSD local, e o disco temporário, /dev/disk/azure/resource. À direita, o Azure Storage, alcançado pela rede: o disco de log no LUN 1 com caching None, alcançado direto pela máquina; o disco do SO com caching ReadWrite e o disco de dados no LUN 0 com caching ReadOnly, os dois alcançados pelo cache do host. Cada disco gerenciado é três cópias. Uma nota embaixo: depois de uma desalocação a máquina pode voltar em outro host, onde o disco temporário pode estar vazio e os discos gerenciados não mudaram.\"><defs><marker id=\"disks-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"12\" y=\"12\" width=\"330\" height=\"252\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o host onde a máquina roda</text><rect x=\"32\" y=\"44\" width=\"290\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"177\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">a máquina virtual</text><rect x=\"110\" y=\"122\" width=\"212\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"216\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cache do host: memória e SSD local</text><rect x=\"32\" y=\"196\" width=\"290\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"177\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">disco temporário</text><text x=\"177\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/dev/disk/azure/resource</text><line x1=\"177\" y1=\"88\" x2=\"177\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#disks-ah)\"></line><line x1=\"60\" y1=\"88\" x2=\"60\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#disks-ah)\"></line><rect x=\"378\" y=\"12\" width=\"330\" height=\"252\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"392\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Azure Storage, pela rede</text><rect x=\"398\" y=\"44\" width=\"290\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"543\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">disco de log, LUN 1</text><text x=\"543\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">caching: None</text><rect x=\"398\" y=\"104\" width=\"290\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"543\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">disco do SO</text><text x=\"543\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">caching: ReadWrite</text><rect x=\"398\" y=\"164\" width=\"290\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"543\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">disco de dados, LUN 0</text><text x=\"543\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">caching: ReadOnly</text><text x=\"543\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cada disco gerenciado é três cópias, LRS ou ZRS</text><line x1=\"322\" y1=\"66\" x2=\"396\" y2=\"66\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#disks-ah)\"></line><line x1=\"322\" y1=\"136\" x2=\"396\" y2=\"129\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#disks-ah)\"></line><line x1=\"322\" y1=\"152\" x2=\"396\" y2=\"189\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#disks-ah)\"></line><rect x=\"12\" y=\"280\" width=\"696\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Desalocada, a máquina pode voltar em outro host: disco temporário vazio, os mesmos discos gerenciados.</text></svg>", "caption": "O que está à esquerda é do host, e fica para trás quando a máquina se muda; o que está à direita é alcançado pela rede de onde quer que a máquina rode. O valor de caching de cada disco decide se as operações dele passam pelo host no caminho."}
```

## Três cópias, num datacenter ou em três zonas

Um disco gerenciado são três cópias, e a opção de redundância diz onde elas ficam. **LRS**, o
armazenamento com redundância local, grava as três de forma síncrona num único datacenter, o que a
Microsoft classifica em onze noves de durabilidade por ano. **ZRS**, o armazenamento com
redundância de zona, grava em três zonas de disponibilidade da região e chega a doze noves; as
gravações demoram mais, porque atravessam zonas, e a Microsoft só o oferece em Premium SSD e
Standard SSD. A lição 6 é sobre zonas.

Nenhum dos dois é backup. Um arquivo apagado por engano some das três cópias no mesmo instante, e é
para isso que servem os snapshots, no fim desta etapa.

## Declarando dois discos e ligando os dois

O banco de pedidos da loja pediria dois discos de dados: um para os arquivos de dados e outro para
o log de escrita, que os bancos de dados mantêm separados porque os dois são usados de jeitos
opostos. Salve isto como `db.bicep`. A interface de rede e a chave são parâmetros, como na lição 2:

```bicep
// db.bicep
param location string = 'brazilsouth'
param adminUsername string = 'ana'
param sshPublicKey string
param nicId string

resource data 'Microsoft.Compute/disks@2024-03-02' = {
  name: 'shop-db-data'
  location: location
  zones: [
    '1'
  ]
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 1024
  }
}

resource log 'Microsoft.Compute/disks@2024-03-02' = {
  name: 'shop-db-log'
  location: location
  zones: [
    '1'
  ]
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 128
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'shop-db-1'
  location: location
  zones: [
    '1'
  ]
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4ds_v5'
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
        caching: 'ReadWrite'
        deleteOption: 'Delete'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Attach'
          caching: 'ReadOnly'
          deleteOption: 'Detach'
          managedDisk: {
            id: data.id
          }
        }
        {
          lun: 1
          createOption: 'Attach'
          caching: 'None'
          deleteOption: 'Detach'
          managedDisk: {
            id: log.id
          }
        }
      ]
    }
    osProfile: {
      computerName: 'shop-db-1'
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

Os dois discos são recursos declarados antes da máquina, criados `Empty`, e a máquina os nomeia por
`data.id` e `log.id`. Os tamanhos não são arbitrários: o Premium SSD é vendido em faixas, e 1.024
GiB e 128 GiB são exatamente as faixas chamadas P30 e P10, que a próxima etapa põe em números. O
`deleteOption` de cada um diz o que apagar a máquina faz com ele. Ele está escrito porque os padrões
mudam de ferramenta para ferramenta: a documentação da Microsoft diz que a CLI desanexa o disco do
SO quando a máquina é apagada, e o portal o apaga. **Um disco desanexado continua sendo cobrado**,
hora após hora, ligado a nada. Aqui o disco do SO vai junto com a máquina e os dois discos de dados
ficam, porque guardam os pedidos.

Os valores que a CLI oferece para as duas configurações de disco, sem conta:

```
ana@laptop:~/azure$ az disk create --help | tr -s "[:space:]" " " | grep -o "\-\-sku : [^.]*\. Allowed values: [A-Za-z0-9_, ]*"
--sku : Underlying storage SKU. Allowed values: PremiumV2_LRS, Premium_LRS, Premium_ZRS, StandardSSD_LRS, StandardSSD_ZRS, Standard_LRS, UltraSSD_LRS
ana@laptop:~/azure$ az vm disk attach --help | tr -s "[:space:]" " " | grep -o "\-\-caching : [^.]*\. Allowed values: [A-Za-z, ]*"
--caching : Disk caching policy. Allowed values: None, ReadOnly, ReadWrite
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-os-disk-caching : [^.]*\. Default: [A-Za-z]*\. Allowed values: [A-Za-z, ]*"
--os-disk-caching : Storage caching type for the VM OS disk. Default: ReadWrite. Allowed values: None, ReadOnly, ReadWrite
```

Sete SKUs, e a redundância faz parte do nome: `Premium_ZRS` é Premium SSD com redundância de zona.
Compile o arquivo:

```
ana@laptop:~/azure$ bicep build db.bicep
ana@laptop:~/azure$ jq -c ".resources[] | {type, name, zones, sku: .sku.name, size: .properties.diskSizeGB}" db.json
{"type":"Microsoft.Compute/disks","name":"shop-db-data","zones":["1"],"sku":"Premium_LRS","size":1024}
{"type":"Microsoft.Compute/disks","name":"shop-db-log","zones":["1"],"sku":"Premium_LRS","size":128}
{"type":"Microsoft.Compute/virtualMachines","name":"shop-db-1","zones":["1"],"sku":null,"size":null}
ana@laptop:~/azure$ jq ".resources[2].properties.storageProfile.dataDisks" db.json
[
  {
    "lun": 0,
    "createOption": "Attach",
    "caching": "ReadOnly",
    "deleteOption": "Detach",
    "managedDisk": {
      "id": "[resourceId('Microsoft.Compute/disks', 'shop-db-data')]"
    }
  },
  {
    "lun": 1,
    "createOption": "Attach",
    "caching": "None",
    "deleteOption": "Detach",
    "managedDisk": {
      "id": "[resourceId('Microsoft.Compute/disks', 'shop-db-log')]"
    }
  }
]
ana@laptop:~/azure$ jq -c ".resources[2].dependsOn" db.json
["[resourceId('Microsoft.Compute/disks', 'shop-db-data')]","[resourceId('Microsoft.Compute/disks', 'shop-db-log')]"]
```

Nenhum aviso. O Bicep viu `data.id` e `log.id` e escreveu no template um `dependsOn` da máquina
nos dois discos, então o Resource Manager cria os discos primeiro.

## Cache do host, escolhido disco a disco

Cada ligação carrega um valor de `caching`, e ele decide se o host onde a máquina roda guarda uma
cópia dos blocos do disco na própria memória e no SSD local. **`ReadOnly` atende as leituras
repetidas pelo host**, e as leituras atendidas pelo cache não contam nos limites do disco; as
gravações seguem para o disco como antes. **`ReadWrite` também segura as gravações no host** e as
grava no disco depois. Isso é rápido, e só é seguro para um software que descarrega o que precisa
guardar, como o SQL Server; qualquer outro pode perder as gravações que ainda estão no cache se a
máquina cair. **`None`** manda toda operação para o disco.

A orientação da Microsoft para um banco de dados é o par que está no arquivo: `ReadOnly` no disco
dos arquivos de dados, que são muito mais lidos do que gravados, e `None` no log, que é gravado em
sequência e quase nunca lido. O disco do SO tem `ReadWrite` como padrão, e `None` não é aceito
nele. Para discos de dados, duas páginas da Microsoft discordam sobre o padrão, uma dizendo
`ReadOnly` e a outra sem cache, o que é um bom motivo para escrever o valor sempre. Mais dois fatos
cabem aqui: o cache não está disponível num disco de 4 TiB ou mais, e mudar o cache de um disco o
desanexa e anexa de novo, o que no disco do SO reinicia a máquina.

O compilador conhece os três valores exatamente, e recusa um quarto:

```
ana@laptop:~/azure$ bicep build db-typo.bicep
/home/ana/azure/db-typo.bicep(79,20) : Warning BCP036: The property "caching" expected a value of type "'None' | 'ReadOnly' | 'ReadWrite' | null" but the provided value is of type "'none'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
ana@laptop:~/azure$ bicep build db-zone.bicep
ana@laptop:~/azure$ jq -c ".resources[] | [.name, .zones]" db-zone.json
["shop-db-data",["2"]]
["shop-db-log",["1"]]
["shop-db-1",["1"]]
```

O `none` escrito errado foi pego. A segunda cópia mudou o disco de dados para a zona 2 e deixou a
máquina na zona 1, e isso compilou sem nada. Um disco LRS mora numa zona, e a Microsoft só
documenta ligar um disco a máquinas de outra zona para discos ZRS; **essa diferença é o Azure quem
recusa, e o compilador não a enxerga.**

## Desanexando, e snapshots

Levar um disco de dados para outra máquina segue esta ordem: dentro da máquina, desmonte o sistema
de arquivos e tire a linha dele do `/etc/fstab`, onde o guia da Microsoft o nomeia pelo UUID com a
opção `nofail`; depois `az vm disk detach`; depois ligue o disco em outra máquina da mesma zona. Os
comandos precisam de uma assinatura e não foram rodados aqui.

Um **snapshot** é uma cópia somente leitura, consistente como depois de uma queda, de um disco num
instante, guardada como recurso próprio e usada para criar discos novos. Um snapshot completo copia
o disco inteiro. Um snapshot **incremental** guarda só o que mudou desde o anterior, e o primeiro é
uma cópia completa. A Microsoft guarda snapshots incrementais em Standard HDD, em ZRS onde a região
tem, e cobra pelo espaço usado:

```
ana@laptop:~/azure$ az snapshot create --help | tr -s "[:space:]" " " | grep -o "\-\-incremental : [^.]*\.[^-]*"
--incremental : Whether a snapshot is incremental. Incremental snapshots on the same disk occupy less space than full snapshots and can be diffed. Allowed values: false, true. 
```

Um limite importa para o banco acima. Um snapshot cobre um disco, e dois snapshots de dois discos
não são tirados no mesmo instante, então nada garante que os dados e o log concordem entre si. A
resposta da Microsoft para vários discos de uma vez é um *ponto de restauração* da máquina, que
captura todos os discos dela numa ordem consistente; ele também precisa de uma assinatura.
