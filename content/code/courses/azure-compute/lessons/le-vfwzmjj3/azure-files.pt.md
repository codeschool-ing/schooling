---
title: Azure Files, um compartilhamento para muitas máquinas
version: 1
---

Quando os servidores web da loja precisam das mesmas fotos de produto enviadas, a primeira ideia é
um disco gerenciado ligado a todos eles. O Azure deixa sim um disco ser ligado a várias máquinas ao
mesmo tempo, mas a Microsoft documenta isso para clusters, com um gerenciador de cluster como o
Pacemaker ou o Windows Server Failover Clustering decidindo quem pode gravar. Um sistema de
arquivos comum nunca foi feito para duas máquinas gravando nele ao mesmo tempo. **Um disco
gerenciado é um dispositivo de blocos para uma máquina; o Azure Files é um compartilhamento de
arquivos para muitas.** É um serviço gerenciado que serve compartilhamentos por SMB e NFS, os dois
protocolos que Windows e Linux já falam, e uma máquina monta um compartilhamento do jeito que
montaria um de um servidor de arquivos.

## O que roda aqui: nada dele

O laboratório da lição 1 tem o Azurite, o emulador de armazenamento da Microsoft, e seria natural
esperar compartilhamentos de arquivos dele. A própria ajuda dele lista o que ele serve:

```
ana@laptop:~/azure$ docker run --rm mcr.microsoft.com/azure-storage/azurite:3.37.0 azurite --help | grep -o -- "--[a-z]*Port <n> .*"
--blobPort <n>               Optional. Customize listening port for blob (defaults to 10000)
--queuePort <n>              Optional. Customize listening port for queue (defaults to 10001)
--tablePort <n>              Optional. Customize listening port for table (defaults to 10002)
```

**Blob, fila e tabela, nas portas 10000 a 10002, e nenhum serviço de arquivos.** O Azurite não emula
o Azure Files, então esta etapa é lida: os protocolos, as camadas e os comandos de montagem vêm da
documentação da Microsoft, lida em 2026-10-30, e a única coisa rodada é o compilador.

## Um compartilhamento, um protocolo, uma camada

Um compartilhamento mora num de dois lugares. O tipo clássico é criado dentro de uma **conta de
armazenamento**, o recurso `Microsoft.Storage` que também guarda blobs e filas; um tipo de recurso
mais novo, `Microsoft.FileShares`, faz do compartilhamento um recurso de primeiro nível sem conta em
volta, por enquanto só para NFS. Este curso usa o tipo clássico, que suporta tudo.

Cada compartilhamento fala um protocolo, escolhido quando ele é criado:

| | SMB | NFS |
| --- | --- | --- |
| clientes | Windows, Linux, macOS | Linux |
| versão | 3.1.1, 3.0, 2.1 | 4.1 |
| mídia | SSD ou HDD | só SSD |
| redundância | LRS, ZRS, GRS, GZRS | LRS, ZRS |
| quem pode se conectar | uma identidade, ou a chave da conta | a rede: um endpoint privado ou de serviço |
| permissões | ACLs do Windows | permissões UNIX |

A camada de mídia é SSD, que a CLI e páginas mais antigas chamam de *premium*, ou HDD, a camada
*standard*. Um compartilhamento SSD precisa de uma conta de armazenamento do tipo `FileStorage`; um
compartilhamento HDD também fica numa dessas no provisionado v2, e numa conta `StorageV2` comum no
pagamento por uso. Essas são as três formas de pagar:

- **provisionado v2**, em que armazenamento, IOPS e vazão são definidos à parte, como os discos da
  penúltima etapa; a Microsoft o recomenda para todo compartilhamento novo;
- **provisionado v1**, só SSD, em que os IOPS e a vazão decorrem do tamanho;
- **pagamento por uso**, só HDD, cobrado pelos bytes guardados e por cada transação.

**O provisionado v2 vem com uma recomendação**, e no SSD ela é uma conta que a Microsoft publica:
3.000 IOPS mais um por GiB provisionado, e 100 MiB/s mais um décimo de MiB/s por GiB, arredondado
para cima. O menor compartilhamento tem 32 GiB. Um compartilhamento pode receber até cinco vezes a
recomendação, ou tão pouco quanto o mínimo, 3.000 IOPS e 100 MiB/s.

## Declarando um

Um compartilhamento NFS para os uploads, 100 GiB em SSD provisionado v2. Salve como `files.bicep`:

```bicep
// files.bicep
param location string = 'brazilsouth'

resource account 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: 'shopfiles2026'
  location: location
  kind: 'FileStorage'
  sku: {
    name: 'PremiumV2_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Disabled'
  }
}

resource files 'Microsoft.Storage/storageAccounts/fileServices@2025-01-01' = {
  parent: account
  name: 'default'
}

resource uploads 'Microsoft.Storage/storageAccounts/fileServices/shares@2025-01-01' = {
  parent: files
  name: 'uploads'
  properties: {
    enabledProtocols: 'NFS'
    rootSquash: 'RootSquash'
    shareQuota: 100
    provisionedIops: 3100
    provisionedBandwidthMibps: 110
  }
}
```

`FileStorage` com `PremiumV2_LRS` é como a documentação escreve *SSD, provisionado v2, com
redundância local*. O nome da conta é um nome de host na internet, então tem de ser único em todo o
Azure, e `shopfiles2026` é só um exemplo. `shareQuota` é o tamanho provisionado em GiB, e os dois
números abaixo dele são a recomendação para 100 GiB: 3.000 + 100 = 3.100 IOPS, e 100 + 10 = 110
MiB/s. `RootSquash` mapeia o usuário root do cliente para um anônimo no compartilhamento, para que
o root de um servidor web comprometido não consiga reescrever todos os arquivos; não é o padrão de um
compartilhamento novo no Azure, e por isso está escrito.

A ajuda da CLI diz de que contas o NFS precisa:

```
ana@laptop:~/azure$ az storage share-rm create --help | tr -s "[:space:]" " " | grep -o "\-\-enabled-protocols : [^.]*\.[^.]*\.[^-]*"
--enabled-protocols : The authentication protocol that is used for the file share. NFS protocol will be only available for premium file shares (file shares in the FileStorage account type). Can only be specified when creating a share. Allowed values: NFS, SMB. 
```

E o compilador aceita os três recursos:

```
ana@laptop:~/azure$ bicep build files.bicep
ana@laptop:~/azure$ jq -c ".resources[] | {type, kind, sku: .sku.name}" files.json
{"type":"Microsoft.Storage/storageAccounts","kind":"FileStorage","sku":"PremiumV2_LRS"}
{"type":"Microsoft.Storage/storageAccounts/fileServices","kind":null,"sku":null}
{"type":"Microsoft.Storage/storageAccounts/fileServices/shares","kind":null,"sku":null}
ana@laptop:~/azure$ jq ".resources[2].properties" files.json
{
  "enabledProtocols": "NFS",
  "rootSquash": "RootSquash",
  "shareQuota": 100,
  "provisionedIops": 3100,
  "provisionedBandwidthMibps": 110
}
```

Como nos discos, o protocolo é um texto para ele:

```
ana@laptop:~/azure$ bicep build files-proto.bicep
ana@laptop:~/azure$ jq -r ".resources[2].properties.enabledProtocols" files-proto.json
NFSv4
```

`NFSv4` chegou ao template, e o Azure o recusaria. O mesmo valeria para `NFS` numa conta HDD, que a
ajuda acima exclui e que o compilador não tem como ver.

## Chegando até ele

**O NFS não tem login de usuário**, então a rede é a autenticação. O compartilhamento só é alcançável
por um endpoint privado, um endereço na rede virtual da lição 16 do `azure-foundations`, ou por um
endpoint de serviço na sub-rede do cliente. Este arquivo desliga o endpoint público e não declara
endpoint privado, que é um recurso à parte: implantado como está, o compartilhamento não seria
alcançável por ninguém.

Numa máquina Linux com rota até ele, o guia da Microsoft instala o auxiliar de montagem dela, o
`aznfs`, do repositório de pacotes da Microsoft, e monta com criptografia em trânsito:

```sh
sudo mkdir -p /mnt/uploads
sudo mount -t aznfs \
    shopfiles2026.file.core.windows.net:/shopfiles2026/uploads \
    /mnt/uploads \
    -o vers=4,minorversion=1,sec=sys,nconnect=4
```

**O SMB** usa a porta TCP 445, que muitas redes e provedores de internet bloqueiam na saída. No Linux
ele precisa do pacote `cifs-utils`, de um arquivo de credenciais que só o root lê, e de `mount -t
cifs`. A Microsoft recomenda entrar com uma identidade em vez da chave da conta, porque um
compartilhamento montado com a chave dá permissão total em todos os arquivos e pastas, digam o que
disserem as ACLs deles.

Nenhum dos comandos foi rodado: não há compartilhamento para montar, e nada neste laptop finge ser
um.

## Para que serve, e para que não serve

Ele combina com **arquivos que várias máquinas leem e gravam**. Na loja, são as fotos enviadas,
servidas por todos os servidores web, e o relatório de vendas noturno, gravado por uma máquina e
lido pela exportação financeira em outra. Em outros lugares, são as ferramentas compartilhadas de
uma equipe, ou o volume persistente
de um contêiner que pode rodar em qualquer nó, no Container Apps ou no AKS. Os snapshots de um
compartilhamento são incrementais, até 200 por compartilhamento.

Ele combina mal com um banco de dados. Cada operação atravessa a rede até um serviço de
armazenamento, e o log de um banco espera exatamente por essa latência. O banco fica com os discos
gerenciados das duas primeiras etapas, e o compartilhamento guarda o que é compartilhado.
