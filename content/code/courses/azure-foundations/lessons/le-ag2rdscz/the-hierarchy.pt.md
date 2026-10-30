---
title: Tenant, grupos de gerenciamento, assinaturas e grupos de recursos
version: 1
---

**A primeira imagem que se costuma ter do Azure tem uma caixa, a conta, com tudo dentro. O Azure tem
quatro caixas, aninhadas, e duas coisas diferentes que as pessoas chamam de "a conta".** Uma é a
caixa da identidade, a outra é a caixa do dinheiro, e mantê-las separadas é a primeira coisa que este
curso pede de você.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 390\" role=\"img\" data-fig=\"l02-hierarchy\" aria-label=\"A hierarquia da loja como quatro tipos de caixa, uma dentro da outra. O tenant, shop.onmicrosoft.com, guarda o grupo de gerenciamento raiz. Debaixo dele fica mg-shop, e debaixo deste três grupos de gerenciamento: mg-shop-prod, mg-shop-nonprod e mg-shop-platform. Cada um guarda uma assinatura: shop-prod, shop-staging e shop-shared. Dentro de shop-prod ficam dois grupos de recursos, rg-shop-prod-app e rg-shop-prod-data, e dentro deles os recursos. Uma nota diz que a identidade mora no tenant e o dinheiro na assinatura.\"><rect x=\"20.0\" y=\"14.0\" width=\"680.0\" height=\"362.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tenant</text><text x=\"684.0\" y=\"32.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop.onmicrosoft.com</text><rect x=\"270.0\" y=\"46.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">grupo de gerenciamento raiz</text><path d=\"M360.0 80.0 L360.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"290.0\" y=\"96.0\" width=\"140.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mg-shop</text><path d=\"M125.0 142.0 L595.0 142.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M360.0 126.0 L360.0 142.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M125.0 142.0 L125.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"45.0\" y=\"154.0\" width=\"160.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mg-shop-prod</text><path d=\"M125.0 184.0 L125.0 198.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"27.0\" y=\"198.0\" width=\"196.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"37.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">assinatura</text><text x=\"213.0\" y=\"214.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-prod</text><path d=\"M360.0 142.0 L360.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"280.0\" y=\"154.0\" width=\"160.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mg-shop-nonprod</text><path d=\"M360.0 184.0 L360.0 198.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"262.0\" y=\"198.0\" width=\"196.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">assinatura</text><text x=\"448.0\" y=\"214.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-staging</text><path d=\"M595.0 142.0 L595.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"515.0\" y=\"154.0\" width=\"160.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mg-shop-platform</text><path d=\"M595.0 184.0 L595.0 198.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"497.0\" y=\"198.0\" width=\"196.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">assinatura</text><text x=\"683.0\" y=\"214.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-shared</text><rect x=\"40.0\" y=\"228.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"125.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-prod-app</text><text x=\"125.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vnet-shop-prod</text><rect x=\"40.0\" y=\"286.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"125.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-prod-data</text><text x=\"125.0\" y=\"319.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sql-shop-prod</text><text x=\"470.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a identidade mora no tenant</text><text x=\"470.0\" y=\"324.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o dinheiro mora na assinatura</text><text x=\"470.0\" y=\"348.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">grupos de recursos não se aninham</text></svg>", "caption": "Quatro tipos de caixa. A árvore do meio pode ter seis níveis; a loja precisa de dois.", "same": ["tenant"]}
```

De fora para dentro:

- **O tenant** é uma instância do Microsoft Entra ID: um diretório de usuários, grupos e aplicações,
  com um GUID como id e um domínio como `shop.onmicrosoft.com`. É a caixa da identidade, e as lições
  6 a 12 moram dentro dela. Uma empresa tem um, normalmente, e toda identidade que ela possui está
  nele.
- **Grupos de gerenciamento** são pastas para assinaturas. Todo tenant tem um no topo, o **grupo de
  gerenciamento raiz**, cujo id é o próprio id do tenant e que o portal chama de *Tenant Root Group*.
  Abaixo dele você monta uma árvore, de até **seis níveis de profundidade**, sem contar a raiz nem as
  assinaturas lá embaixo. Todo o propósito deles é a herança: uma política ou uma permissão dada a um
  grupo de gerenciamento alcança tudo o que está abaixo dele, que é o assunto das lições 4 e 9.
- **Uma assinatura** é a caixa do dinheiro. Os recursos são criados nela, ela é cobrada por eles, as
  cotas são contadas dentro dela, e ela confia em **exatamente um tenant** para as identidades que
  podem mexer nela. Uma assinatura tem um pai: um grupo de gerenciamento, ou a raiz se ninguém a
  colocou em lugar nenhum.
- **Um grupo de recursos** é uma caixa dentro de uma assinatura, com recursos que vivem e morrem
  juntos. Todo recurso está em exatamente um grupo de recursos, e **grupos de recursos não se
  aninham**. Apagar um grupo apaga tudo o que está nele, e é por isso que a lição 1 o usou como a
  unidade de limpeza.

## Para que serve cada caixa

| caixa | ela decide | quantas |
|---|---|---|
| tenant | quem existe: toda identidade, e como ela faz login | uma por empresa, em regra |
| grupo de gerenciamento | o que é herdado: políticas e permissões para um ramo inteiro | até 10.000 num tenant, seis níveis abaixo da raiz |
| assinatura | quem paga, e os limites: a fatura, as cotas, a fronteira de um erro | quantas a empresa precisar; nunca uma só |
| grupo de recursos | o que vive e morre junto: uma aplicação num ambiente | até 980 numa assinatura |

**Um grupo de recursos tem uma localização, e ela não quer dizer o que parece.** O `rg-shop-prod` é
criado em `brazilsouth`, e esse é só o lugar onde o Azure guarda o registro do próprio grupo: a lista
do que está nele. Uma máquina virtual dentro do grupo pode estar em qualquer outra região. Escolha a
região onde os recursos estão, para que o registro e as coisas que ele descreve vivam sob a mesma lei
e falhem juntos.

## A árvore da loja

A loja online que este curso acompanha tem um tenant e três assinaturas, e a árvore é desenhada em
torno do que difere entre elas, não em torno dos departamentos da empresa:

- `mg-shop` debaixo da raiz, guardando tudo o que a loja roda;
- `mg-shop-prod` debaixo dele, com a assinatura `shop-prod`, onde estão os pedidos dos clientes;
- `mg-shop-nonprod` ao lado, com `shop-staging`, onde as versões são testadas primeiro;
- `mg-shop-platform`, com `shop-shared`, para o que os dois ambientes usam: a rede hub da lição 20, as
  zonas de DNS da lição 21, os logs.

**A árvore segue as regras, não o organograma.** Um ramo existe porque tudo o que está debaixo dele é
governado do mesmo jeito: produção com políticas mais rígidas, não produção com políticas mais
baratas. Um departamento que se reorganiza a cada dois anos arrastaria a árvore junto, e cada mudança
de uma assinatura de ramo muda o que ela herda.

Esta árvore é o primeiro rascunho que uma equipe desenha, e tem um defeito que a lição 5 aponta: o
desenho de landing zone da Microsoft desaconselha separar a produção do resto neste nível, e a lição 5
redesenha a árvore da loja do jeito dele.

## Criando as caixas, e o que este laboratório pode fazer a respeito

Cada caixa é criada por uma porta diferente. Um tenant vem com a assinatura do Azure, como na lição 1.
Um grupo de gerenciamento é um recurso do Resource Manager no nível do tenant, e também são a posição
da assinatura na árvore e o grupo de recursos:

```
ana@laptop:~/azure$ az group create --name rg-shop-prod --location brazilsouth
ERROR: Please run 'az login' to setup account.
```

**Nada foi criado**: cada um destes é um pedido ao Resource Manager, e o laboratório nunca faz login.
Vale conhecer os comandos pelo nome, `az account management-group create` para um grupo de
gerenciamento, `az account management-group subscription add` para posicionar uma assinatura,
`az group create` para um grupo de recursos; o resto desta lição monta a mesma árvore num arquivo, que
é algo que o laboratório consegue conferir.
