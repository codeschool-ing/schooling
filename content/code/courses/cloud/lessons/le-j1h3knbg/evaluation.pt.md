---
title: Como um pedido é decidido
version: 1
---

Um pedido raramente encontra uma política só. Um usuário pertence a dois grupos, cada um com as suas
políticas, e tem uma própria anexada; o bucket que ele está lendo tem uma política de bucket própria.
O provedor precisa transformar tudo isso numa resposta, e faz isso com três regras:

1. Tudo começa negado. Um pedido que nenhuma declaração menciona é recusado. Isso se chama negação
   implícita, e é a resposta para todo pedido em que ninguém pensou.
2. Um `Allow` explícito que casa concede o pedido, venha de qualquer política que se aplique.
3. Um `Deny` explícito que casa recusa o pedido, e nada desfaz isso. Nem um segundo `Allow`, nem um
   mais específico, nem um anexado mais perto da pessoa.

**Um pedido só é permitido quando algo o permite e nada o nega.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um fluxo de decisão para um pedido já autenticado. Ele começa negado. Primeira pergunta: alguma política que se aplica traz um Deny explícito que casa com esta ação, recurso e circunstâncias? Se sim, a resposta é NEGADO e nada mais é lido. Se não, a segunda pergunta: alguma política traz um Allow que casa? Se sim, PERMITIDO. Se não, o pedido fica onde começou: NEGADO, por padrão, o que se chama de negação implícita.\"><defs><marker id=\"evl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">um pedido autenticado</text><text x=\"130\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">começa como: negado</text><path d=\"M130 70 L130 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#evl-ah)\"></path><rect x=\"20\" y=\"100\" width=\"220\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um Deny explícito casa,</text><text x=\"130\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">em alguma política aplicável?</text><path d=\"M240 128 L430 128\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#evl-ah)\"></path><text x=\"335\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">sim</text><rect x=\"430\" y=\"100\" width=\"270\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"565\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"700\">NEGADO</text><text x=\"565\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">explícito: nenhum Allow desfaz</text><path d=\"M130 156 L130 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#evl-ah)\"></path><text x=\"146\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não</text><rect x=\"20\" y=\"190\" width=\"220\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um Allow casa,</text><text x=\"130\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">em alguma política aplicável?</text><path d=\"M240 218 L430 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#evl-ah)\"></path><text x=\"335\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sim</text><rect x=\"430\" y=\"190\" width=\"270\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"565\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"700\">PERMITIDO</text><text x=\"565\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o pedido segue</text><path d=\"M130 246 L130 270\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#evl-ah)\"></path><text x=\"146\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não</text><rect x=\"20\" y=\"270\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"130\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"700\">NEGADO</text><text x=\"130\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">implícito: nada permitiu</text></svg>", "caption": "A ordem em que as políticas foram escritas, e qual foi anexada primeiro, não muda nada: toda política que se aplica é lida, um Deny que casa encerra a questão e, sem um Allow que case, a resposta é aquela com que o pedido começou."}
```

## O modelo errado: vence a política mais próxima

Quem conhece permissões de arquivo ou CSS espera que a regra mais específica passe por cima da geral,
então uma política no usuário deveria vencer uma política no grupo. Não existe essa hierarquia. Toda
política que se aplica é lida, as declarações são reunidas, e as três regras decidem. Três casos,
todos com o mesmo usuário, `ana`, no grupo `analysts`:

| o grupo `analysts` diz | a política da própria `ana` diz | `ana` pede | resultado |
|---|---|---|---|
| Allow `s3:*` no bucket de relatórios | Deny `s3:DeleteObject` ali | `s3:DeleteObject` | recusado, explicitamente |
| Allow `s3:*` no bucket de relatórios | Deny `s3:DeleteObject` ali | `s3:GetObject` | permitido |
| Allow `s3:GetObject` no bucket de relatórios | nada | `s3:PutObject` | recusado, implicitamente |

A primeira linha é a regra de que as pessoas duvidam. O `s3:*` do grupo cobre excluir, e não
importa: um `Deny` que casa em qualquer lugar encerra a questão. A segunda linha mostra que o `Deny`
remove só o que nomeia. A terceira mostra a negação implícita fazendo o seu trabalho: ninguém escreveu
"sem uploads", e não há nenhum, porque nada os permitiu.

## Usando um Deny de propósito

Como um deny explícito vence tudo, ele é a ferramenta para uma regra que precisa valer seja o que for
que os outros permitam. Esta declaração recusa exclusões no bucket de relatórios a toda sessão aberta
sem segundo fator, por mais amplo que seja o `Allow` que de outro modo a cobriria:

```json
{
  "Effect": "Deny",
  "Action": "s3:DeleteObject",
  "Resource": "arn:aws:s3:::example-reports/*",
  "Condition": {
    "BoolIfExists": { "aws:MultiFactorAuthPresent": "false" }
  }
}
```

`BoolIfExists` em vez de `Bool` faz diferença aqui. Um pedido assinado com uma chave de acesso de
longa duração não carrega a chave de MFA, então o `Bool` simples não acharia nada para comparar e
não se aplicaria. A forma `IfExists` trata a chave ausente como uma correspondência, e o deny pega
esses pedidos também.

## Onde as regras deixam de ser a história toda

Duas políticas de donos diferentes se encontram quando um pedido cruza contas. Um usuário de uma
conta lendo um bucket de outra precisa de um `Allow` dos **dois** lados: a política da própria
identidade tem de permitir a ação, e a política do bucket tem de permitir a conta dele ou ele. Dentro
de uma conta só, um `Allow` das políticas da identidade ou da política do recurso basta.

A AWS também tem limites que ficam acima das políticas desta aula e nunca concedem nada sozinhos:
um **limite de permissões** (permission boundary) restringe o que as políticas de um usuário ou de
uma role podem dar a eles. Uma service control policy faz o mesmo para contas inteiras de uma
organização. Com qualquer um dos dois no lugar, um pedido precisa de um `Allow` de toda camada que se
aplica, e um `Deny` em qualquer camada continua vencendo. É ali que o `aws-foundations` e o
`cloud-security` continuam; as três regras acima não mudam dentro deles.
