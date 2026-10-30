---
title: A Compute Gallery, da definição à versão
version: 1
---

Uma galeria parece uma pasta onde se jogam imagens. **Uma Azure Compute Gallery são três tipos de
recurso, aninhados**: a galeria, um contêiner cujo acesso você controla; dentro dela uma *definição
de imagem*, que diz que tipo de imagem uma coisa é; e dentro de cada definição as *versões de
imagem*, que são as imagens. Uma máquina nunca é criada a partir de uma definição. Ela é criada a
partir de uma versão, a que você nomeia ou a que a definição chama de `latest` naquele momento.

```schooling-figure
{"svg": "<svg id=\"fig-gallery-nesting\" viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Aninhamento: a galeria shopgallery em brazilsouth guarda a definição de imagem shop-web, com publisher shop, offer shop-web, sku ubuntu-24_04, osState Generalized e hyperVGeneration V2. A definição guarda três versões de imagem. A 1.0.0 está replicada três vezes em brazilsouth e uma em southcentralus. A 1.1.0 está replicada três vezes em brazilsouth e é o que latest resolve. A 1.2.0 está marcada excludeFromLatest, então uma VM que nomeia só a definição recebe a 1.1.0.\"><defs><marker id=\"gallery-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"688\" height=\"312\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"30\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">galeria: shopgallery, brazilsouth</text><rect x=\"34\" y=\"48\" width=\"652\" height=\"196\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"48\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">definição de imagem: shop-web</text><rect x=\"48\" y=\"82\" width=\"196\" height=\"146\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">publisher: shop</text><text x=\"60\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">offer: shop-web</text><text x=\"60\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sku: ubuntu-24_04</text><text x=\"60\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">osState: Generalized</text><text x=\"60\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">hyperVGeneration: V2</text><text x=\"270\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">versões de imagem</text><rect x=\"270\" y=\"82\" width=\"126\" height=\"146\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"333\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">1.0.0</text><text x=\"333\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">brazilsouth ×3,</text><text x=\"333\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">southcentralus ×1</text><rect x=\"410\" y=\"82\" width=\"126\" height=\"146\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"473\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">1.1.0</text><text x=\"473\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">brazilsouth ×3</text><text x=\"473\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o que latest resolve</text><rect x=\"550\" y=\"82\" width=\"126\" height=\"146\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"613\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">1.2.0</text><text x=\"613\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">brazilsouth ×1,</text><text x=\"613\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">para testes</text><text x=\"613\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">excluída do latest</text><rect x=\"200\" y=\"268\" width=\"320\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"360\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma VM que nomeia só a definição</text><text x=\"360\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">é criada a partir da 1.1.0</text><line x1=\"473\" y1=\"228\" x2=\"420\" y2=\"266\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#gallery-ah)\"></line></svg>", "caption": "A definição diz que tipo de imagem é e não muda; as versões são as imagens. latest é o maior número de versão que não foi excluído."}
```

## A definição: que tipo de imagem é esta

Uma definição tem os seus próprios três nomes, um publisher, uma offer e um SKU, escolhidos por você
e no formato dos de uma imagem do Marketplace. Duas definições podem dividir um ou dois deles, mas
nunca os três, e a documentação da Microsoft sugere copiar os nomes da própria imagem do Marketplace
quando a sua é uma versão customizada de uma delas, para que o sistema operacional seja legível de
relance. Além dos nomes, a definição declara o que toda versão dentro dela precisa ser:

- `osType`, `Linux` ou `Windows`;
- `osState`, `Generalized` ou `Specialized`, que é a escolha da seção anterior: uma versão capturada
  de uma máquina desprovisionada vai para uma definição generalizada;
- `hyperVGeneration`, `V1` ou `V2`, a geração da primeira seção desta lição;
- `architecture`, `x64` ou `Arm64`;
- `features`, entre elas os tipos de segurança que uma versão suporta, como
  `TrustedLaunchSupported`: uma imagem de geração 2 a partir da qual se criam máquinas com ou sem
  Trusted Launch.

**Isso é fixado quando a definição é criada.** A documentação lista o que pode mudar depois, e para
uma definição é a descrição, as quantidades recomendadas de processador e memória, as notas de
versão e uma data de fim de vida. Uma definição declarada com a geração errada é substituída, não
editada.

## A versão: a imagem em si

O nome de uma versão é o número dela, `MAJOR.MINOR.PATCH`, três números inteiros e mais nada:
`1.0.0`, `1.1.0`, `1.10.2`. A origem é uma máquina capturada, um disco, um snapshot, uma imagem
gerenciada ou outra versão. E o *publishing profile* dela diz onde ficam as cópias:

- **regiões de destino**, cada uma com um número de *réplicas*. Uma réplica é uma cópia, e as
  criações de máquina de uma região são repartidas entre as réplicas dela. Cada região também recebe
  um tipo de armazenamento, com redundância local (`Standard_LRS`) ou entre zonas (`Standard_ZRS`)
  numa região com zonas de disponibilidade;
- **`excludeFromLatest`**, que deixa a versão fora do `latest` e ainda utilizável pelo número;
- **`endOfLifeDate`**, uma data a partir da qual a versão não deveria mais ser usada.

**`latest` é o maior número de versão que não foi excluído**, comparado como números, primeiro o
major, depois o minor, depois o patch. Então `1.10.0` é mais nova que `1.9.4`, o que não seria numa
ordem alfabética, e na figura a `1.2.0` existe e mesmo assim não é o `latest`, porque foi publicada
excluída enquanto está sendo testada. Uma declaração de máquina que nomeia o id da definição recebe o
`latest` na criação; uma que nomeia o id de uma versão, terminado em `/versions/1.1.0`, recebe
exatamente essa versão. A Microsoft recomenda o id da definição, a não ser que uma versão específica
seja necessária, porque uma versão nomeada que foi apagada ou nunca replicada numa região faz o
deploy falhar. É o `latest` do Marketplace de novo, com uma diferença: **aqui quem decide o que
`latest` quer dizer é você**, ao publicar, excluir e numerar.

Uma data de fim de vida é uma declaração e nada mais. Nas palavras da documentação, ela é
informativa, e ainda se criam máquinas a partir de uma versão que já passou dela. O que avisa as
pessoas para sair de uma versão antiga precisa ser algo que você constrói.

A regra da documentação para dimensionar réplicas é uma réplica para cada vinte máquinas criadas no
mesmo instante a partir da versão, uma por scale set criado ao mesmo tempo, e pelo menos três para
imagens de produção. Uma região que vai criar sessenta máquinas de uma vez quer três réplicas.

O que uma versão custa são as cópias. Cada réplica é guardada e cobrada como um snapshot do tamanho
**ocupado** da imagem, não do tamanho do disco: o exemplo da documentação é um disco do sistema de
127 GB guardando 10 GB, replicado em três regiões com duas réplicas em cada, o que dá seis snapshots
de 10 GB. Copiar a primeira réplica para cada outra região é cobrado como tráfego de saída; as
réplicas extras dentro de uma região não são.

## Declarando uma

Aqui estão a galeria da loja, uma definição para as máquinas web e uma primeira versão capturada de
uma máquina generalizada cujo id é um parâmetro. Salve como `gallery.bicep`:

```bicep
// gallery.bicep
param location string = 'brazilsouth'
@description('The generalised VM the version is captured from')
param sourceVmId string

resource gallery 'Microsoft.Compute/galleries@2024-03-03' = {
  name: 'shopgallery'
  location: location
  properties: {
    description: 'Images for the shop'
  }
}

resource web 'Microsoft.Compute/galleries/images@2024-03-03' = {
  parent: gallery
  name: 'shop-web'
  location: location
  properties: {
    osType: 'Linux'
    osState: 'Generalized'
    hyperVGeneration: 'V2'
    architecture: 'x64'
    identifier: {
      publisher: 'shop'
      offer: 'shop-web'
      sku: 'ubuntu-24_04'
    }
    features: [
      {
        name: 'SecurityType'
        value: 'TrustedLaunchSupported'
      }
    ]
  }
}

resource v100 'Microsoft.Compute/galleries/images/versions@2024-03-03' = {
  parent: web
  name: '1.0.0'
  location: location
  properties: {
    storageProfile: {
      source: {
        virtualMachineId: sourceVmId
      }
    }
    publishingProfile: {
      replicaCount: 1
      excludeFromLatest: false
      endOfLifeDate: '2027-10-30T00:00:00Z'
      targetRegions: [
        {
          name: 'brazilsouth'
          regionalReplicaCount: 3
          storageAccountType: 'Standard_ZRS'
        }
        {
          name: 'southcentralus'
          regionalReplicaCount: 1
          storageAccountType: 'Standard_LRS'
        }
      ]
    }
  }
}
```

A versão mantém três réplicas em São Paulo em armazenamento com redundância entre zonas e uma em
South Central US, a região onde a loja recriaria as máquinas se São Paulo ficasse indisponível. A
lição 6 trata do que isso protege e do que não protege. O `replicaCount` padrão de 1 só vale para uma
região de destino que não informa o seu. E toda propriedade cujo padrão mudou entre versões da API
está escrita: a documentação diz que uma definição criada pela versão `2025-03-03` da API ou
posterior tem como padrão `V2` e `TrustedLaunchSupported`, enquanto este arquivo usa a `2024-03-03`,
em que uma definição sem geração é `V1`. Compile:

```
ana@laptop:~/azure$ bicep build gallery.bicep
ana@laptop:~/azure$ jq -r ".resources[] | [.type, .name] | @tsv" gallery.json
Microsoft.Compute/galleries	shopgallery
Microsoft.Compute/galleries/images	[format('{0}/{1}', 'shopgallery', 'shop-web')]
Microsoft.Compute/galleries/images/versions	[format('{0}/{1}/{2}', 'shopgallery', 'shop-web', '1.0.0')]
```

O aninhamento está nos nomes: `shop-web` está dentro de `shopgallery`, e `1.0.0` dentro das duas.
Agora dois erros que uma pessoa com ortografia britânica e mania de minúscula poderia cometer:

```
ana@laptop:~/azure$ sed -i "s/Generalized/Generalised/; s/V2/v2/" gallery.bicep
ana@laptop:~/azure$ bicep build gallery.bicep
/home/ana/azure/gallery.bicep(20,14) : Warning BCP088: The property "osState" expected a value of type "'Generalized' | 'Specialized'" but the provided value is of type "'Generalised'". Did you mean "'Generalized'"? [https://aka.ms/bicep/core-diagnostics#BCP088]
ana@laptop:~/azure$ sed -i "s/Generalised/Generalized/; s/v2/V2/" gallery.bicep
```

O `osState` é um entre exatamente dois valores para o compilador, então o britânico `Generalised` é
recusado, com a grafia certa sugerida. O `v2` no lugar de `V2` passou sem uma palavra: o
`hyperVGeneration`, como o tipo de segurança da seção anterior, é uma string que o compilador não
consegue verificar. **O que um aviso pega é o que os tipos da Microsoft por acaso tornam estrito, e
nada mais.** O último comando desfez os dois.

## Quem pode usá-la

Uma galeria é privada da sua assinatura até ser compartilhada, e há três jeitos de compartilhar,
cada um mais amplo que o anterior:

| compartilhada com | como | o que o outro lado vê |
|---|---|---|
| pessoas, grupos, service principals | Azure RBAC, um papel na galeria | nada até você mandar o id da imagem; não conseguem listá-la |
| todos os usuários de assinaturas ou tenants escolhidos | uma direct shared gallery, em preview | uma galeria só de leitura; até 30 assinaturas e 5 tenants |
| todo cliente do Azure | uma galeria comunitária | imagens públicas sob um nome feito a partir do seu prefixo |

O RBAC são as atribuições de papel da lição 9 de `azure-foundations`, dadas na galeria para que uma
definição nova fique coberta no dia em que é criada; a documentação recomenda compartilhar a galeria
inteira em vez de versões avulsas. Uma direct shared gallery não pode guardar versões criptografadas.
Uma galeria comunitária publica os nomes da definição junto com as imagens, não pode ser feita a
partir de uma galeria privada que já existe, e não tem suporte da Microsoft para o que está nela.
**Um segredo assado numa imagem vai para onde a imagem for compartilhada**, que é o motivo mais forte
para a seção anterior ter configurado os ajustes no boot.

Duas regras da própria lista de boas práticas da Microsoft completam o quadro. A galeria é um recurso
numa região, então uma segunda galeria em outra região é o que mantém versões novas possíveis se a
primeira região cair. E imagens de produção e de teste ficam em galerias separadas, para que um papel
dado a quem testa nunca alcance aquilo de onde as máquinas da loja são feitas.

Esse é o terceiro motivo para as suas imagens morarem na galeria, depois do Trusted Launch e de um
`latest` que você decide: é o único tipo de imagem sua que pode sair da sua região e da sua
assinatura.
