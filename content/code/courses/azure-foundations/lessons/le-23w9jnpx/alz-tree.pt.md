---
title: A árvore de referência, e por que ela não é a da lição 2
version: 1
---

**O CAF publica uma árvore de grupos de gerenciamento, e ela não é dividida por ambiente.** A lição 2
desenhou a árvore da loja do jeito que a maioria das equipes a desenha primeiro: produção num ramo,
não produção em outro. O CAF diz, com essas palavras, para não criar grupos de gerenciamento para
produção, teste e desenvolvimento. O motivo é a razão de ser de um ambiente de teste: **o staging
deve ser governado exatamente como a produção**, para que o que passa no staging passe na produção.
Dois ramos com dois conjuntos de políticas fazem o teste medir outra coisa. Ambientes se separam por
**assinatura**, `shop-prod` ao lado de `shop-staging`, dentro do mesmo grupo de gerenciamento.

O que o CAF usa para dividir é **o que uma carga de trabalho precisa da plataforma**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l05-alz-tree\" aria-label=\"A árvore de grupos de gerenciamento do Cloud Adoption Framework, com os nomes da loja. Debaixo do grupo raiz do tenant fica a raiz intermediária, shop. Debaixo dela: shop-platform, com shop-security, shop-management, shop-connectivity e shop-identity; shop-landingzones, com shop-corp e shop-online; shop-sandbox; e shop-decommissioned. A assinatura shop-shared fica debaixo de shop-connectivity; shop-prod e shop-staging ficam lado a lado debaixo de shop-online.\"><rect x=\"280.0\" y=\"14.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">grupo raiz do tenant</text><path d=\"M360.0 42.0 L360.0 54.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"310.0\" y=\"54.0\" width=\"100.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop</text><path d=\"M360.0 82.0 L360.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110.0 96.0 L640.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110.0 96.0 L110.0 108.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"62.9\" y=\"108.0\" width=\"94.1\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-platform</text><path d=\"M330.0 96.0 L330.0 108.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"271.6\" y=\"108.0\" width=\"116.9\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-landingzones</text><path d=\"M510.0 96.0 L510.0 108.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"465.8\" y=\"108.0\" width=\"88.4\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-sandbox</text><path d=\"M640.0 96.0 L640.0 108.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"575.9\" y=\"108.0\" width=\"128.3\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-decommissioned</text><path d=\"M40.0 150.0 L40.0 278.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110.0 136.0 L110.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M40.0 150.0 L110.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M40.0 164.0 L56.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"56.0\" y=\"151.0\" width=\"130.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"121.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-security</text><path d=\"M40.0 202.0 L56.0 202.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"56.0\" y=\"189.0\" width=\"130.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"121.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-management</text><path d=\"M40.0 240.0 L56.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"56.0\" y=\"227.0\" width=\"130.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"121.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-connectivity</text><path d=\"M40.0 278.0 L56.0 278.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"56.0\" y=\"265.0\" width=\"130.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"121.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-identity</text><rect x=\"196.0\" y=\"227.0\" width=\"100.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"246.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-shared</text><path d=\"M187.0 240.0 L195.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M330.0 136.0 L330.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M290.0 150.0 L390.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M290.0 150.0 L290.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"245.0\" y=\"164.0\" width=\"90.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-corp</text><path d=\"M330.0 136.0 L330.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M290.0 150.0 L390.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M390.0 150.0 L390.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"345.0\" y=\"164.0\" width=\"90.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-online</text><path d=\"M390.0 190.0 L390.0 216.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"320.0\" y=\"216.0\" width=\"140.0\" height=\"64.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"330.0\" y=\"224.0\" width=\"120.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-prod</text><rect x=\"330.0\" y=\"250.0\" width=\"120.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-staging</text><text x=\"590.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">produção e staging:</text><text x=\"590.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um grupo, as mesmas regras</text></svg>", "caption": "Dividida pelo que uma carga de trabalho precisa da plataforma, nunca por ambiente."}
```

| grupo de gerenciamento | guarda |
|---|---|
| a **raiz intermediária**, `shop` | tudo o que é da organização, para que nada precise ser atribuído na própria raiz do tenant |
| **platform**, e debaixo dele **security**, **management**, **connectivity** e **identity** | as assinaturas da equipe de plataforma: ferramentas de segurança, logs e monitoramento, a rede hub e o DNS, servidores de diretório |
| **landing zones**, e debaixo dele **corp** e **online** | as cargas de trabalho. *Corp* para as que alcançam a rede do escritório pelo hub; *online* para as que encaram a internet diretamente |
| **sandbox** | experimentos, com políticas mais leves, isolados dos dois tipos de landing zone |
| **decommissioned** | assinaturas sendo desativadas, até serem apagadas |

As três assinaturas da loja cabem nela sem esforço: `shop-shared` debaixo de connectivity,
`shop-prod` e `shop-staging` juntas debaixo de online, já que a loja atende a internet. A política que
mantém o staging honesto é atribuída uma vez, em online, e as duas a recebem.

O CAF acrescenta dois conselhos sobre profundidade: manter a árvore com **três a quatro níveis**, bem
dentro do limite de seis da lição 2, e **não dar papéis às equipes de carga de trabalho no escopo de
um grupo de gerenciamento**, só nas assinaturas e nos grupos delas. Uma permissão num grupo de
gerenciamento alcança toda assinatura debaixo dele, inclusive a da equipe ao lado.

## A árvore, em Bicep

Crie o diretório da lição e salve isto como `alz.bicep`:

```sh
mkdir -p ~/azure/alz && cd ~/azure/alz
```

```bicep
targetScope = 'tenant'

@description('The intermediate root: every management group of the shop hangs under it.')
param prefix string = 'shop'

var children = [
  { name: '${prefix}-platform', parent: prefix }
  { name: '${prefix}-security', parent: '${prefix}-platform' }
  { name: '${prefix}-management', parent: '${prefix}-platform' }
  { name: '${prefix}-connectivity', parent: '${prefix}-platform' }
  { name: '${prefix}-identity', parent: '${prefix}-platform' }
  { name: '${prefix}-landingzones', parent: prefix }
  { name: '${prefix}-corp', parent: '${prefix}-landingzones' }
  { name: '${prefix}-online', parent: '${prefix}-landingzones' }
  { name: '${prefix}-sandbox', parent: prefix }
  { name: '${prefix}-decommissioned', parent: prefix }
]

resource root 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: prefix
  properties: {
    displayName: prefix
    details: {
      parent: {
        id: tenantResourceId('Microsoft.Management/managementGroups', tenant().tenantId)
      }
    }
  }
}

@batchSize(1)
resource groups 'Microsoft.Management/managementGroups@2023-04-01' = [
  for g in children: {
    name: g.name
    properties: {
      displayName: g.name
      details: {
        parent: {
          id: tenantResourceId('Microsoft.Management/managementGroups', g.parent)
        }
      }
    }
    dependsOn: [
      root
    ]
  }
]
```

A raiz intermediária é um recurso e os dez grupos debaixo dela são um **laço**: `for g in children`
cria um grupo de gerenciamento para cada item da lista. Cada filho cita o pai pelo nome, e o
`tenantResourceId` transforma o nome no id do pai. Compile e veja como o laço chega ao template:

```
ana@laptop:~/azure/alz$ az bicep build --file alz.bicep --stdout | jq -c '."$schema", (.resources | map({type, name, copy}))'
"https://schema.management.azure.com/schemas/2019-08-01/tenantDeploymentTemplate.json#"
[{"type":"Microsoft.Management/managementGroups","name":"[parameters('prefix')]","copy":null},{"type":"Microsoft.Management/managementGroups","name":"[variables('children')[copyIndex()].name]","copy":{"name":"groups","count":"[length(variables('children'))]","mode":"serial","batchSize":1}}]
```

O laço virou um elemento **`copy`**: o laço do próprio Resource Manager, que ele vai expandir quando
o template chegar, `length(variables('children'))` vezes. O `mode` é `serial` e o `batchSize` é 1 por
causa do **`@batchSize(1)`**, a linha acima do laço, e essa linha não é enfeite. Um laço copy roda as
iterações **em paralelo** se ninguém disser o contrário, e `shop-management` não pode ser criado antes
de `shop-platform`, o pai dele, existir. Em série, um de cada vez, na ordem da lista, todo pai vem
antes dos filhos, porque a lista foi escrita assim.

Essa é uma dependência que o compilador não enxerga: dentro de um laço, o Bicep não sabe que o
`parent` de um item é o `name` de outro. **Compilou limpo com a linha e sem ela**, e sem ela uma
implantação falharia, às vezes, dependendo de qual pedido o Resource Manager rodasse primeiro.
Implantá-la é `az deployment tenant create`, que precisa de direitos na raiz de um tenant e não foi
executado.
