---
title: Geo-replicação, a declaração, e o scan
version: 1
---

Uma réplica parece um segundo registry, um backup com nome próprio para onde alguém copia imagens.
**A geo-replicação mantém um registry, com um login server, e guarda o conteúdo dele em várias
regiões.** Você faz push uma vez, para `shopregistry.azurecr.io`; o registry copia o push para cada
réplica; e cada pull é atendido pela réplica que o Azure julga mais próxima de quem pede.
Credenciais, papéis e regras de rede são do registry, então são os mesmos em todo lugar. Ela exige
Premium, e nada nela roda num laptop, então esta seção é lida, fora uma declaração que o compilador
do Bicep confere.

## Um nome, várias regiões

A loja roda em São Paulo. A lição 6 disse que sobreviver à perda de uma região exige uma cópia numa
segunda, e a lição 2 guardou uma réplica da imagem de máquina da loja em `southcentralus` para esse
dia. A imagem de contêiner precisa do mesmo. Sem replicação, as máquinas em `southcentralus` baixam
de `brazilsouth`, atravessando um continente, e não conseguem baixar nada enquanto a região de
origem estiver fora. Com uma réplica, elas baixam na própria região, com o mesmo nome. O comando, não
executado:

```sh
az acr replication create --registry shopregistry --location southcentralus
```

A opção que decide se essa réplica é usada está na ajuda:

```
ana@laptop:~/azure$ az acr replication create --help | awk '/^    --/{p=0} /^    --(location|global-endpoint-routing) /{p=1} p'
    --global-endpoint-routing   : Allow routing to this replication via the registry global
                                  endpoint. If disabled, requests to the global endpoint will not be
                                  routed to the replica. Data syncing to the replica will continue
                                  regardless of the global endpoint routing status. Default: true.
                                  Allowed values: false, true.
    --location -l               : Location. Values from: `az account list-locations`. You can
                                  configure the default location using `az configure --defaults
                                  location=<location>`.  Config: brazilsouth.
```

A documentação da Microsoft, lida em 30 de outubro de 2026, descreve o arranjo em detalhe, e quatro
pontos dela mudam o planejamento:

- **Toda réplica aceita escrita.** O modelo é ativo-ativo: um push, um pull ou uma exclusão podem
  cair em qualquer região, não só na de origem.
- **A região de origem fica com o plano de controle.** Se `brazilsouth` cair, pushes e pulls
  continuam pelas réplicas, mas as configurações do registry não mudam até ela voltar, e **as ACR
  Tasks não rodam**, porque as tasks pertencem à região de origem.
- **O armazenamento é cobrado por réplica.** Um gigabyte em duas regiões é cobrado como dois, embora
  o limite de armazenamento do tier conte uma vez só, e copiar um push para uma réplica é cobrado
  como transferência de dados entre regiões.
- **As réplicas são redundantes entre zonas** nas regiões que têm zonas, como o próprio registry.

## Consistente com o tempo

**Um push chega às outras réplicas depois, não na hora.** Quanto depois depende do tamanho da
imagem, e a documentação lista o que esse atraso quebra:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas regiões de um registry com geo-replicação, numa linha do tempo. Um pipeline faz push de shop:1.2, que chega em brazilsouth. Ela é copiada para a réplica em southcentralus em segundo plano. Um pod em southcentralus que baixa a 1.2 antes de a cópia chegar recebe manifest unknown; um pull depois da chegada funciona. Os dois pulls usaram o mesmo login server.\"><defs><marker id=\"acr-geo-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"acr-geo-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">shopregistry.azurecr.io</text><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um login server; cada pedido vai para a réplica que o Azure escolhe para o cliente</text><path d=\"M150 100 L170 100\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M320 100 L700 100\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">brazilsouth</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">região de origem</text><path d=\"M150 200 L340 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M490 200 L550 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">southcentralus</text><text x=\"20\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">réplica</text><rect x=\"170\" y=\"78\" width=\"150\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"245\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">um pipeline envia a 1.2</text><text x=\"245\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ela chega aqui primeiro</text><path d=\"M320 112 L548 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#acr-geo-ah)\"></path><text x=\"470\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">copiada em segundo plano</text><rect x=\"340\" y=\"178\" width=\"150\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"415\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">um pod aqui baixa a 1.2</text><text x=\"415\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">manifest unknown</text><rect x=\"550\" y=\"178\" width=\"150\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"625\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o mesmo pull, depois</text><text x=\"625\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a cópia já chegou</text><path d=\"M150 262 L700 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-geo-ah)\"></path><text x=\"700\" y=\"280\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "Um registry com geo-replicação fica consistente com o tempo, não na hora. Entre o push e a cópia, o mesmo nome responde diferente nas duas regiões."}
```

A figura é o caso em que os pipelines tropeçam: uma imagem recebe push, e pods em outra região a
baixam logo em seguida e ouvem `manifest unknown`. O segundo caso é a seção 03 de novo, pior. Faça
push de `shop:1.2`, depois push de outro build com a mesma tag um minuto mais tarde, e por um tempo
as duas regiões podem resolver `1.2` para dois digests diferentes. Um deploy que nomeia o digest não
cai nessa, porque uma réplica ou tem exatamente aqueles bytes ou responde que não tem. Os remédios
da documentação são repetir com espera crescente depois de um push entre regiões, e os webhooks do
registry, que enviam um evento quando cada réplica termina de copiar uma imagem.

Um **endpoint regional**, em preview, nomeia uma réplica diretamente,
`shopregistry.southcentralus.geo.azurecr.io`, para um pipeline que quer fazer push e pull no mesmo
lugar. Ele abre mão do failover automático que o nome global tem, então é o cliente que escolhe
outra região.

Um recurso que todo tier tem cabe ao lado da replicação, porque também mantém a loja baixando
imagens quando o serviço de outra pessoa está num dia ruim. Uma regra de **artifact cache** manda o
registry buscar uma imagem num registry de origem, como o Docker Hub, na primeira vez em que ela é
pedida, e guardá-la. `FROM shopregistry.azurecr.io/python:3.12-slim` passa então a baixar do seu
próprio registry. Uma regra só guarda o que já passou por ela uma vez, não busca tags novas sozinha,
e o Docker Hub só é suportado com credenciais suas, que a regra lê do Key Vault.

## O registry, declarado

Aqui está o registry inteiro em Bicep: Premium, o usuário admin desligado, manifests sem tag
mantidos por sete dias e uma réplica em `southcentralus`. Salve-o como `~/azure/acr.bicep`:

```bicep
// acr.bicep
param location string = 'brazilsouth'

resource registry 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: 'shopregistry'
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    policies: {
      retentionPolicy: {
        status: 'enabled'
        days: 7
      }
    }
  }
}

resource replica 'Microsoft.ContainerRegistry/registries/replications@2025-11-01' = {
  parent: registry
  name: 'southcentralus'
  location: 'southcentralus'
}
```

Uma replicação é um recurso próprio sob o registry, que é o que o `parent` diz, e o nome dela é, por
convenção, a região onde fica. O `zoneRedundancy` ficou de fora de propósito, pelo motivo que a
seção 02 deu. Compilado:

```
ana@laptop:~/azure$ bicep build acr.bicep
ana@laptop:~/azure$ ls acr.*
acr.bicep
acr.json
ana@laptop:~/azure$ jq -c ".resources[] | {type, name, location}" acr.json
{"type":"Microsoft.ContainerRegistry/registries","name":"shopregistry","location":"[parameters('location')]"}
{"type":"Microsoft.ContainerRegistry/registries/replications","name":"[format('{0}/{1}', 'shopregistry', 'southcentralus')]","location":"southcentralus"}
```

Sem avisos, então pela regra da lição 1 está pronto. O nome do segundo recurso virou
`shopregistry/southcentralus`, o nome completo de um recurso filho. A seção 04 é o motivo de a
política de retenção ser uma rede de segurança menor do que parece: as imagens OCI da loja ficam
fora dela.

Agora o mesmo registry com cinco erros, do tipo que uma edição apressada faz. Salve-o como
`~/azure/wrong.bicep`:

```bicep
// wrong.bicep
param location string = 'brazilsouth'

resource registry 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: 'shop-registry'
  location: location
  sku: {
    name: 'Premuim'
  }
  properties: {
    adminUserEnabled: 'false'
    policies: {
      retentionPolicy: {
        stauts: 'enabled'
        days: 400
      }
    }
  }
}
```

```
ana@laptop:~/azure$ bicep build wrong.bicep
/home/ana/azure/wrong.bicep(5,9) : Warning BCP416: The supplied string does not match the expected pattern of /$^[a-zA-Z0-9]*$/. [https://aka.ms/bicep/core-diagnostics#BCP416]
/home/ana/azure/wrong.bicep(11,23) : Warning BCP036: The property "adminUserEnabled" expected a value of type "bool | null" but the provided value is of type "'false'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
/home/ana/azure/wrong.bicep(14,9) : Warning BCP089: The property "stauts" is not allowed on objects of type "RetentionPolicy". Did you mean "status"? [https://aka.ms/bicep/core-diagnostics#BCP089]
ana@laptop:~/azure$ ls wrong.*
wrong.bicep
wrong.json
```

**Três foram pegos e dois não.** O hífen em `shop-registry` quebrou o padrão de nome; o padrão sai
estranho na mensagem, e o que ele quer dizer é só letras e dígitos. O `'false'` entre aspas é texto
onde a API espera um booleano, e `stauts` é uma propriedade com erro de grafia, com a grafia certa
sugerida. Mas `'Premuim'` passou, porque o compilador tipa o nome de um SKU como um dos três tiers
**ou qualquer string**, então um erro de digitação ali compila em silêncio e fica para o Azure
recusar. E `days: 400` passou, embora a ajuda da CLI na seção 04 tenha dado o intervalo de 0 a 365:
o tipo só diz que é um número. Trate os avisos como recusas, e leia você mesmo os valores que o
compilador não consegue julgar.

## O scan, e o que um resultado limpo quer dizer

Um scan de vulnerabilidades compara os pacotes que consegue identificar numa imagem com as
vulnerabilidades publicadas para eles. **Ele acha problemas conhecidos em pacotes conhecidos, e nada
mais**: nem um bug no `app.py`, nem um token que alguém copiou para uma camada, nem uma
vulnerabilidade publicada amanhã. Um resultado limpo descreve aqueles pacotes naquele dia.

O scanner da própria Microsoft para o ACR é o Defender for Cloud, pelo plano dele para contêineres,
e ele é ligado para a **assinatura** no Defender for Cloud, não no registry. A documentação do
container registry da Microsoft diz o que ele faz então. Ele escaneia as imagens que recebem push ou
são importadas, e as imagens **baixadas nos últimos 30 dias**. Os achados aparecem no **Defender for
Cloud como recomendações**, não no registry, com os passos para corrigir cada um. Uma imagem
corrigida recebe push no lugar da antiga, e o Defender a escaneia de novo para confirmar. O scanner
entra e baixa como qualquer cliente, então os pulls dele aparecem nos logs do registry; atrás de um
private endpoint, o registry precisa permitir os serviços confiáveis da Microsoft, o que um registry
novo já faz.

As páginas do Defender que listam exatamente quais sistemas operacionais e gerenciadores de pacotes
ele lê não puderam ser lidas para este curso. Confira-as antes de contar com um scan para cobrir uma
imagem base ou os pacotes de uma linguagem em particular. O resto da decisão é o mesmo de sempre: um
achado é um motivo para refazer o build sobre uma base corrigida, que é o gatilho de imagem base da
seção 04 fazendo aquilo para que existe.

## Limpando

O registry local e o volume dele são as únicas coisas que esta lição deixou rodando:

```
ana@laptop:~/azure$ docker rm -f registry
registry
ana@laptop:~/azure$ docker volume rm shop-registry
shop-registry
```
