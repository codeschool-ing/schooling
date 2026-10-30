---
title: Copiando as tags de um grupo para os seus recursos
version: 1
---

**As tags de um grupo de recursos ficam no grupo.** Ponha `cost-centre: cc-410` em `rg-shop-prod-app`,
e toda máquina criada dentro dele depois não tem `cost-centre` nenhum, a não ser que o arquivo que a
criou diga. Essa é a brecha em que todo esquema de tags cai: o grupo é tagueado uma vez, com cuidado,
pela pessoa que desenhou o esquema, e os seus recursos são criados por anos depois por pessoas que
nunca o leram. O Azure oferece dois jeitos de fechar a brecha, e eles trabalham em camadas diferentes.

## Uma política que escreve a tag

O primeiro é o Azure Policy, que a lição 4 apresentou: uma regra avaliada pelo Resource Manager quando
chega um pedido para criar ou mudar um recurso. A Microsoft publica as suas definições de política
nativas, e a cópia no GitHub pode ser lida sem conta. Peça a que herda uma tag:

```
ana@laptop:~/azure/tags$ curl -sS https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions/Tags/InheritTag_Add_Modify.json | jq '{name, displayName: .properties.displayName, mode: .properties.mode, effect: .properties.policyRule.then.effect, operation: .properties.policyRule.then.details.operations[0].operation, role: .properties.policyRule.then.details.roleDefinitionIds[0]}'
{
  "name": "ea3f2387-9b95-492a-a190-fcdc54f7b070",
  "displayName": "Inherit a tag from the resource group if missing",
  "mode": "Indexed",
  "effect": "modify",
  "operation": "add",
  "role": "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
}
```

Campo por campo, o que essa resposta diz:

- **`name`** é o id da definição, um GUID que é o mesmo em todo tenant, porque uma definição nativa é
  da Microsoft e é compartilhada por todos eles. Uma atribuição a cita por esse id.
- **`displayName`** diz *if missing*, e essa é a regra: a política acrescenta o valor do grupo quando
  o recurso não tem essa tag, e **deixa em paz um valor diferente**. Uma definição irmã, *Inherit a tag
  from the resource group*, acrescenta ou substitui, sobrescrevendo o que o recurso dizia.
- **`mode: Indexed`** quer dizer que a política só olha recursos que aceitam tags e localização, então
  os próprios grupos de recursos não são tocados por ela.
- **`effect: modify`** é o efeito que muda o pedido no caminho: o recurso é criado com a tag
  acrescentada, como se a pessoa a tivesse escrito.
- **`role`** é o GUID do papel nativo **Contributor**. Uma política que escreve em recursos precisa de
  uma identidade com permissão para escrever, e este é o papel que essa identidade precisa ter. As
  lições 8 e 9 explicam identidades gerenciadas e papéis; aqui basta saber que a atribuição traz uma
  identidade própria.

A regra em si, no mesmo arquivo, tem duas condições: o recurso não tem a tag, e o valor do grupo não
está vazio. Um grupo que nunca foi tagueado não acrescenta nada.

## Atribuindo-a

Uma atribuição aplica uma definição num escopo, com valores para os seus parâmetros. A loja atribui
esta à assinatura de produção inteira, para a tag `cost-centre`. Salve isto como `inherit.bicep`:

```bicep
targetScope = 'subscription'

resource inheritCostCentre 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'inherit-cost-centre'
  location: 'brazilsouth'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Inherit cost-centre from the resource group if missing'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070'
    parameters: {
      tagName: {
        value: 'cost-centre'
      }
    }
  }
}

output principalId string = inheritCostCentre.identity.principalId
```

```
ana@laptop:~/azure/tags$ az bicep build --file inherit.bicep --stdout | jq -c '(.resources[0] | {type, identity, policy: .properties.policyDefinitionId}), .outputs'
{"type":"Microsoft.Authorization/policyAssignments","identity":{"type":"SystemAssigned"},"policy":"/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"}
{"principalId":{"type":"string","value":"[reference(subscriptionResourceId('Microsoft.Authorization/policyAssignments', 'inherit-cost-centre'), '2024-04-01', 'full').identity.principalId]"}}
```

`identity: SystemAssigned` pede ao Azure que crie essa identidade junto com a atribuição, e `location`
é onde ela mora. A saída é o id da identidade, uma expressão que só o Resource Manager consegue
preencher, e alguém então precisa dar a essa identidade o papel Contributor na assinatura; até lá a
política pode decidir acrescentar uma tag e não tem direito de fazê-lo. **Nada disso foi implantado.**

Duas coisas que a política não faz. **Ela não mexe no que já existe**: ela age sobre pedidos, e um
recurso criado no ano passado não recebe pedido nenhum. Recursos existentes são consertados por uma
**tarefa de remediação**, que aplica a modificação a tudo o que a política encontra fora da linha. E
**ela muda o recurso**, que é o objetivo e também o custo: a tag agora está no recurso, onde qualquer
um pode mudá-la e toda implantação posterior desse recurso ou a repete ou briga com ela.

## Herança só nos dados de custo

O segundo jeito trabalha na fatura em vez de nos recursos. O Cost Management tem uma configuração de
**herança de tags** que, ligada, aplica as tags de uma assinatura e de um grupo de recursos aos
**registros de uso** dos recursos dentro deles. A documentação da Microsoft é precisa sobre a
diferença: as tags herdadas são aplicadas *aos registros de uso dos recursos filhos e não aos próprios
recursos*. Nada no Azure muda; a exportação da próxima seção desta lição ganha as tags.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-two-inheritances\" aria-label=\"O grupo de recursos rg-shop-prod-app leva a tag cost-centre cc-410, e a máquina virtual vm-shop-web-2 dentro dele não tem tags. Dois caminhos trazem a tag do grupo para baixo. À esquerda, uma atribuição do Azure Policy com o efeito modify escreve a tag no próprio recurso, quando ele é criado ou remediado. À direita, a herança de tags do Cost Management deixa o recurso como está e acrescenta a tag só aos seus registros de uso nos dados de custo.\"><defs><marker id=\"l15-two-inheritances-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l15-two-inheritances-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"220.0\" y=\"16.0\" width=\"280.0\" height=\"92.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"232.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">grupo de recursos</text><text x=\"488.0\" y=\"32.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">rg-shop-prod-app</text><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">cost-centre: cc-410</text><rect x=\"270.0\" y=\"64.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vm-shop-web-2</text><path d=\"M300.0 110.0 L300.0 130.0 L170.0 130.0 L170.0 154.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-two-inheritances-af-ah-phosphor)\"></path><rect x=\"30.0\" y=\"156.0\" width=\"280.0\" height=\"112.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Azure Policy, efeito modify</text><rect x=\"70.0\" y=\"190.0\" width=\"200.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vm-shop-web-2</text><text x=\"170.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">cost-centre: cc-410</text><text x=\"170.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a tag é escrita no recurso</text><path d=\"M420.0 110.0 L420.0 130.0 L550.0 130.0 L550.0 154.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-two-inheritances-af-ah-paper)\"></path><rect x=\"410.0\" y=\"156.0\" width=\"280.0\" height=\"112.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">herança de tags do Cost Management</text><rect x=\"430.0\" y=\"190.0\" width=\"240.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">vm-shop-web-2  3.20  Tags:</text><text x=\"550.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">{&quot;cost-centre&quot;: &quot;cc-410&quot;}</text><text x=\"550.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só os registros de uso a ganham</text></svg>", "caption": "Uma regra muda o recurso; a outra muda só o que a fatura diz dele."}
```

Ela só está disponível para alguns tipos de conta de cobrança, o Enterprise Agreement, o Microsoft
Customer Agreement e o Microsoft Partner Agreement, e não para toda assinatura comprada com cartão.
**Nada aqui foi ligado.** Onde ela existe, é a ferramenta mais suave para a pergunta *quem gastou o
quê*, e a política é a ferramenta para a pergunta *de quem é este recurso*; uma loja que faz as duas
perguntas usa as duas.
