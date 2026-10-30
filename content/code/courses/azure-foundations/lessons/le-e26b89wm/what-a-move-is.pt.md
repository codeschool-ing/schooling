---
title: O que é um movimento, e o que ele deixa para trás
version: 1
---

**Mover um recurso no Azure não o leva a lugar nenhum.** A imagem errada é a de um caminhão: a
máquina é desligada num lugar e ligada de novo em outro. Um movimento entre grupos de recursos, ou
entre assinaturas, muda em qual caixa o recurso está arquivado e nada mais. A máquina virtual continua
rodando no mesmo datacenter, no mesmo disco, com o mesmo endereço, e os usuários dela não percebem
nada. O que muda é o nome.

## O id muda, e tudo o que o guardava quebra

A lição 2 desmontou ids de recurso. Um movimento reescreve a ponta esquerda de um deles:

| | id de recurso |
|---|---|
| antes | `/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod` |
| depois de um movimento para outro grupo | `/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod-network/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod` |
| depois de um movimento para outra assinatura | `/subscriptions/ddddeeee-3333-ffff-4444-aaaa5555bbbb/resourceGroups/rg-shop-network/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod` |

**Tudo o que guardava o id antigo agora aponta para o nada**: um script, um painel, uma regra de
alerta, um arquivo Bicep que o cita, a referência de outro recurso a ele. A lista de verificação da
própria Microsoft diz isso numa linha: se você usa o id do recurso em algum lugar, troque-o. Nada faz
isso por você, e nada diz em quais lugares procurar. Esse é o primeiro custo de um movimento, e o
motivo para escolher bem o grupo de recursos na primeira vez.

**A região não muda.** Um movimento entre grupos ou assinaturas mantém o recurso onde ele está.
Levá-lo para outra região é outra operação, feita recriando-o lá, à mão ou com o Azure Resource Mover,
e a ideia da lição 26, de um recurso escrito num arquivo, é o que torna barato recriá-lo.

## O que acontece enquanto ele se move

Quatro coisas que a documentação afirma e que este laboratório não consegue mostrar:

- **Os dois grupos de recursos ficam travados durante o movimento.** Nada pode ser criado, apagado
  ou mudado no grupo de origem nem no de destino até o movimento terminar. Os recursos continuam
  funcionando; só não podem ser modificados. Um movimento de muitos recursos pode levar horas, que
  são horas em que ninguém consegue implantar em nenhum dos dois grupos.
- **Recursos filhos vão com o pai, e só com ele.** Uma sub-rede se move com a rede, e uma extensão
  com a máquina virtual. Você pede para mover o pai; pedir para mover um filho sozinho é recusado.
- **As atribuições de papel no próprio recurso não se movem.** Uma permissão dada no próprio
  recurso, que a lição 9 explica, fica para trás e vira uma órfã que o Azure acaba removendo. Ela
  precisa ser criada de novo no destino. As permissões herdadas de cima simplesmente mudam: o recurso
  agora herda do novo grupo e da nova assinatura.
- **Entre assinaturas, as duas precisam confiar no mesmo tenant.** Um movimento não leva um recurso
  do diretório de uma empresa para o de outra. Isso é outra operação, feita na assinatura inteira, e a
  última seção desta lição diz quanto ela custa.

## Mover uma assinatura não é mover um recurso

Uma assinatura pode ser movida entre grupos de gerenciamento, e essa é uma operação comum: um pedido,
nada travado, nenhum id mudando, já que o id de uma assinatura não cita o grupo de gerenciamento dela.
**O que muda é o que ela herda.** O aviso da lição 2 sobre mover uma assinatura entre ramos da árvore
vem daqui: os recursos ficam exatamente onde estão, e as políticas da lição 4 e as permissões da lição
9 que se aplicam a eles mudam no mesmo segundo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-three-moves\" aria-label=\"Três tipos de movimento comparados em três colunas. Um recurso movido para outro grupo de recursos: o id muda, a região não, e os dois grupos ficam travados enquanto ele se move. Um recurso movido para outra assinatura: o id muda, a região não, as duas assinaturas precisam confiar no mesmo tenant, e as dependências vão junto. Uma assinatura movida para outro grupo de gerenciamento: nenhum id muda e nada é travado, mas o que ela herda muda na hora.\"><rect x=\"20.0\" y=\"20.0\" width=\"216.0\" height=\"260.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"128.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um recurso, para outro grupo</text><path d=\"M36.0 78.0 L220.0 78.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"128.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o id muda</text><text x=\"128.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a região fica</text><text x=\"128.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os dois grupos travados</text><text x=\"128.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">atribuições próprias perdidas</text><rect x=\"252.0\" y=\"20.0\" width=\"216.0\" height=\"260.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um recurso, para outra assinatura</text><path d=\"M268.0 78.0 L452.0 78.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o id muda</text><text x=\"360.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a região fica</text><text x=\"360.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mesmo tenant exigido</text><text x=\"360.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dependências vão juntas</text><rect x=\"484.0\" y=\"20.0\" width=\"216.0\" height=\"260.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"592.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma assinatura, para outro grupo</text><path d=\"M500.0 78.0 L684.0 78.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"592.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nenhum id muda</text><text x=\"592.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nada travado</text><text x=\"592.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a herança muda</text><text x=\"592.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">na hora, para tudo dentro dela</text></svg>", "caption": "Dois tipos de movimento renomeiam um recurso; o terceiro não renomeia nada e muda as regras."}
```
