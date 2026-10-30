---
title: Mover com segurança, e o movimento que não é movimento
version: 1
---

**Um movimento é conferido antes de começar, e a conferência é um pedido à parte que você pode fazer
sozinho.** O Resource Manager tem uma ação chamada `validateMoveResources`: ela recebe o grupo de
origem, o destino e a lista de ids, e responde se o movimento daria certo, sem mover nada. O portal a
roda para você antes de todo movimento. Pela linha de comando são dois comandos, a conferência e o
movimento:

```
ana@laptop:~/azure/moves$ az resource invoke-action --action validateMoveResources --ids /subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod --request-body '{"resources": ["/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod"], "targetResourceGroup": "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod-network"}'
ERROR: Please run 'az login' to setup account.
```

```
ana@laptop:~/azure/moves$ az resource move --destination-group rg-shop-prod-network --ids /subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod
ERROR: Please run 'az login' to setup account.
```

**Nenhum dos dois foi respondido aqui**, pelo motivo de nenhum pedido ao Resource Manager ser
respondido neste laboratório. Com uma conta, uma validação que passa não devolve nada, e uma que falha
devolve um erro com o recurso e o motivo. O `az resource move` também aceita
`--destination-subscription-id`, para um movimento entre assinaturas.

## A lista de verificação que a Microsoft publica

Antes de um movimento, a documentação lista o que precisa ser verdade. Lida como uma lista dos jeitos
de um movimento falhar, ela é curta:

| o que precisa ser verdade | o que acontece se não for |
|---|---|
| o tipo pode se mover, pela tabela da seção anterior | a validação recusa |
| as assinaturas de origem e destino estão ativas e confiam no mesmo tenant | a validação recusa |
| a assinatura de destino está **registrada** no namespace do provider do recurso | o movimento falha com *the subscription isn't registered for a resource type* |
| o destino tem cota para o que chega | o movimento falha no destino |
| nenhuma trava somente leitura no grupo de origem, no de destino ou em qualquer das assinaturas | o movimento é recusado |
| você pode fazer `moveResources` no grupo de origem e `write` no de destino | o pedido é recusado |

O registro é o que as pessoas encontram primeiro. Uma assinatura precisa estar registrada num
namespace de provider, como `Microsoft.Network`, antes de poder guardar recursos desse provider.
Criar um recurso faz o registro de passagem, e é por isso que ninguém repara, mas um movimento não:
uma assinatura nova que nunca teve uma rede recusa uma rede movida para ela até alguém registrar o
`Microsoft.Network` com `az provider register`.

## Entre assinaturas, as dependências viajam juntas

**Entre assinaturas, um recurso e tudo de que ele depende precisam estar no mesmo grupo de recursos,
e se mover no mesmo pedido.** Uma máquina virtual não é um recurso só: ela tem discos, uma interface
de rede, e a interface fica numa sub-rede de uma rede. Mover a máquina para outra assinatura quer
dizer mover tudo isso de uma vez. A Microsoft descreve isso em três passos:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-cross-subscription\" aria-label=\"Mover uma máquina virtual para outra assinatura em três passos. Antes: a máquina está em rg-shop-prod-app e a rede em rg-shop-prod-network, os dois em shop-prod. Passo 1, juntar: a rede é movida para rg-shop-prod-app, dentro de shop-prod. Passo 2, mover: tudo o que está no grupo, máquina, disco, interface e rede, vai para shop-shared num pedido só. Passo 3, espalhar: no destino eles podem ser divididos em grupos de novo.\"><defs><marker id=\"l03-cross-subscription-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l03-cross-subscription-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">antes</text><rect x=\"20.0\" y=\"44.0\" width=\"200.0\" height=\"236.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-prod</text><text x=\"34.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">assinatura</text><rect x=\"32.0\" y=\"80.0\" width=\"176.0\" height=\"90.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"120.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-prod-app</text><text x=\"120.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vm-shop-1</text><text x=\"120.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">disk</text><text x=\"120.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nic</text><rect x=\"32.0\" y=\"182.0\" width=\"176.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"120.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-prod-network</text><text x=\"120.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vnet-shop-prod</text><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1  juntados</text><rect x=\"260.0\" y=\"44.0\" width=\"200.0\" height=\"236.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"446.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-prod</text><text x=\"274.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">assinatura</text><rect x=\"272.0\" y=\"80.0\" width=\"176.0\" height=\"110.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-prod-app</text><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vm-shop-1</text><text x=\"360.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">disk</text><text x=\"360.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nic</text><text x=\"360.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vnet-shop-prod</text><text x=\"600.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">2  movidos, 3  espalhados</text><rect x=\"500.0\" y=\"44.0\" width=\"200.0\" height=\"236.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"686.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-shared</text><text x=\"514.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">assinatura</text><rect x=\"512.0\" y=\"80.0\" width=\"176.0\" height=\"90.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-app</text><text x=\"600.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vm-shop-1</text><text x=\"600.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">disk</text><text x=\"600.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nic</text><rect x=\"512.0\" y=\"182.0\" width=\"176.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-network</text><text x=\"600.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vnet-shop-prod</text><path d=\"M222.0 160.0 L258.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-cross-subscription-af-ah-paper-dim)\"></path><path d=\"M462.0 160.0 L498.0 160.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l03-cross-subscription-af-ah-amber)\"></path></svg>", "caption": "Entre assinaturas, uma máquina viaja com o disco, a interface e a rede, num pedido só."}
```

1. **juntar**: se as dependências estão espalhadas por vários grupos, mova-as para um grupo só
   primeiro, dentro da mesma assinatura;
2. **mover** tudo o que está nesse grupo para a outra assinatura, num pedido só;
3. **espalhar** de novo, se quiser, em grupos no destino.

Algumas dependências se recusam a viajar, e a orientação de rede cita as que a loja encontraria.
**Uma rede virtual com peering precisa ter o peering removido antes de se mover**, e refeito depois,
que é o assunto da lição 20. Uma rede com um serviço implantado numa das suas sub-redes, como o Azure
Databricks, carrega um vínculo desse serviço e não pode ir para outra assinatura. E qualquer coisa
presa a um endereço IP público Standard fica na sua assinatura, como a seção anterior descobriu.

## O movimento que não é movimento: uma assinatura para outro tenant

Uma assinatura também pode ser entregue a um **tenant diferente**, que é o que acontece quando uma
empresa é comprada, ou quando uma assinatura aberta com a conta pessoal de alguém é trazida para o
diretório da empresa. No portal isso se chama *change directory*. **Isso não é um movimento no sentido
desta lição, e é muito mais destrutivo**: toda identidade em que a assinatura confiava pertencia ao
tenant antigo, então a documentação da Microsoft avisa que as atribuições de papel, os papéis
personalizados e as identidades gerenciadas da lição 8 não sobrevivem, e que recursos que guardam um
id de tenant, como um key vault, precisam receber o novo.

**Nada disso foi executado**, e nada disso deve ser executado sem cuidado com uma conta também. Um
movimento entre grupos é uma mudança de arquivo; uma mudança de tenant está mais perto de uma mudança
de casa em que as chaves se perdem no caminho.
