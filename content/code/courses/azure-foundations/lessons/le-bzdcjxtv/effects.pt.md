---
title: Efeitos, e quando uma regra de fato roda
version: 1
---

**O efeito decide o que uma condição verdadeira faz, e a escolha é entre parar um pedido, mudá-lo e
anotá-lo.** A documentação da Microsoft lista onze efeitos; a loja encontra sete deles, em três
famílias:

| família | efeito | o que acontece quando a condição é verdadeira |
|---|---|---|
| recusar | `deny` | o pedido para criar ou mudar o recurso é recusado, com o nome da política no erro |
| recusar | `denyAction` | uma ação citada, como apagar, é recusada em recursos que batem |
| mudar | `modify` | o pedido é alterado antes de ser executado: uma tag acrescentada, trocada ou removida |
| mudar | `deployIfNotExists` | depois de criado o recurso, um recurso relacionado é implantado se estiver faltando |
| reportar | `audit` | o recurso é criado e marcado como não conforme |
| reportar | `auditIfNotExists` | o recurso é marcado como não conforme se faltar um recurso relacionado |
| desligado | `disabled` | nada; a atribuição existe e está desligada |

## A ordem em que rodam

**Quando chega um pedido para criar ou atualizar um recurso, o Resource Manager junta todas as
atribuições que se aplicam a ele e roda os efeitos numa ordem fixa**, que a Microsoft documenta:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l04-order\" aria-label=\"A ordem em que o Azure Policy roda os efeitos quando chega um pedido: disabled primeiro, depois append e modify, que mudam o pedido, depois deny, depois audit, depois auditIfNotExists, e denyAction por último. Depois que o resource provider informa sucesso, auditIfNotExists e deployIfNotExists olham o que existe ao lado do novo recurso.\"><defs><marker id=\"l04-order-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"23.0\" y=\"40.0\" width=\"104.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">disabled</text><text x=\"75.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pula se desligada</text><path d=\"M128.0 75.0 L136.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-order-af-ah-paper-dim)\"></path><rect x=\"137.0\" y=\"40.0\" width=\"104.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"189.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">append, modify</text><text x=\"189.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">muda o pedido</text><path d=\"M242.0 75.0 L250.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-order-af-ah-paper-dim)\"></path><rect x=\"251.0\" y=\"40.0\" width=\"104.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"303.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">deny</text><text x=\"303.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">recusa</text><path d=\"M356.0 75.0 L364.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-order-af-ah-paper-dim)\"></path><rect x=\"365.0\" y=\"40.0\" width=\"104.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"417.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">audit</text><text x=\"417.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reporta</text><path d=\"M470.0 75.0 L478.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-order-af-ah-paper-dim)\"></path><rect x=\"479.0\" y=\"40.0\" width=\"104.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"531.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">auditIfNotExists</text><text x=\"531.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">vizinho ausente</text><path d=\"M584.0 75.0 L592.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-order-af-ah-paper-dim)\"></path><rect x=\"593.0\" y=\"40.0\" width=\"104.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">denyAction</text><text x=\"645.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">recusa uma exclusão</text><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">quando o pedido chega</text><path d=\"M23.0 140.0 L697.0 140.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"360.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">depois que o resource provider informa sucesso</text><rect x=\"170.0\" y=\"180.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">auditIfNotExists</text><rect x=\"370.0\" y=\"180.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">deployIfNotExists</text></svg>", "caption": "Mudar antes de recusar, recusar antes de reportar, e os efeitos sobre vizinhos depois que o recurso existe."}
```

A ordem não é arbitrária. `disabled` é conferido primeiro para que uma regra desligada não custe nada.
`modify` e `append` rodam antes do `deny` porque podem mudar o pedido, e um pedido consertado pelo
`modify`, que recebeu a tag que faltava, não deve depois ser recusado por não tê-la. `deny` roda antes
do `audit` para que um pedido recusado não seja também registrado como um recurso não conforme que
nunca existiu. Os dois efeitos `IfNotExists` só rodam depois que o resource provider disse que a
criação deu certo, porque eles são sobre o que existe ao lado do novo recurso.

## Efeitos que agem precisam de uma identidade

`modify` e `deployIfNotExists` fazem alguma coisa na sua assinatura, então alguém precisa ter
permissão para fazê-la. Esse alguém é a **identidade gerenciada da própria atribuição**, uma
identidade que o Azure cria para a atribuição, que a lição 8 explica, com os papéis que a definição
pede. A nativa que copia uma tag do grupo de recursos para os recursos que não a têm mostra o pedido
na sua regra:

```
ana@laptop:~/azure/policy$ curl -sS https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions/Tags/InheritTag_Add_Modify.json | jq '{displayName: .properties.displayName, effect: .properties.policyRule.then.effect, roles: .properties.policyRule.then.details.roleDefinitionIds}'
{
  "displayName": "Inherit a tag from the resource group if missing",
  "effect": "modify",
  "roles": [
    "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
  ]
}
```

`b24988ac-6180-42a0-ab88-20f7382dd24c` é o id do papel nativo *Contributor*, o mesmo GUID em todo
tenant; papéis são o assunto da lição 9. Atribuir esta definição cria a identidade e exige que o papel
seja dado a ela no escopo da atribuição; sem o papel, a regra avalia e as mudanças dela falham. A lição
15 trata de por que essas tags importam para a fatura.

## Quando uma regra roda, e quando não roda

Um `deny` age no momento de um pedido, e só nele. **Recursos que existiam antes da atribuição não são
tocados por ela**: são avaliados e reportados, e é só. Então uma atribuição de *Allowed locations*
numa assinatura com uma máquina no Texas deixa a máquina rodando e a marca como não conforme.
Consertar o que já existe é um passo à parte, uma **tarefa de remediação**, disponível para `modify` e
`deployIfNotExists`, e uma decisão manual para todo o resto.

A documentação dá os tempos, e nenhum deles este laboratório consegue mostrar:

- uma atribuição nova leva **cerca de cinco minutos** para valer no seu escopo, e então a avaliação
  começa;
- toda atribuição é avaliada de novo **uma vez a cada 24 horas**, o ciclo padrão, sem promessa de
  quando uma grande termina;
- uma varredura pode ser pedida, para uma assinatura ou um grupo de recursos, com `az policy state
  trigger-scan`.

```
ana@laptop:~/azure/policy$ az policy state trigger-scan --resource-group rg-shop-prod
ERROR: Please run 'az login' to setup account.
```

## Várias definições como uma

As duas regras da loja vão virar dez. Atribuir dez definições uma a uma, no mesmo escopo, com
parâmetros que se sobrepõem, é como uma regra é esquecida num ramo. Uma **iniciativa**, chamada de
*policy set definition* na API, agrupa definições para que sejam atribuídas, reportadas e isentadas
como uma só, com parâmetros compartilhados. Os padrões regulatórios da Microsoft, como o da ISO 27001,
são iniciativas nativas de muitas definições cada, e a página de conformidade então responde por
iniciativa: a que distância esta assinatura está do padrão.
