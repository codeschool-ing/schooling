---
title: A cadeia que a Apple confere
version: 1
---

**No Android você é a sua própria autoridade; no iOS, a Apple é, e um app só roda quando a Apple
assinou cada elo de uma cadeia.** A lição 1 criou uma chave que ninguém avalizou, e o celular
ficava satisfeito enquanto as atualizações batessem com ela. Um iPhone pede mais: quem assinou o
app, se foi a Apple que emitiu o certificado dessa pessoa, que app é esse, o que ele pode fazer e
em quais aparelhos pode rodar. *Tudo nesta lição acontece num Mac com Xcode, e nada foi rodado
para este curso; foi lido da documentação de desenvolvedor da Apple, outubro de 2026.*

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-chain\" aria-label=\"Três entradas alimentam um perfil de provisionamento. O certificado diz quem assina, e a chave privada dele fica no Mac que o criou. O App ID diz qual app, pelo bundle identifier, e com quais recursos. A lista de aparelhos diz onde um build de desenvolvimento ou ad hoc pode rodar; um perfil da App Store não tem nenhum. O perfil, assinado pela Apple, vai embutido no app assinado, e toda parte dele tem data de vencimento, menos o App ID.\"><defs><marker id=\"l02-chain-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"220\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">certificado</text><text x=\"130\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">quem assina</text><text x=\"130\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chave privada num Mac</text><path d=\"M240 58 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-chain-ah-paper-dim)\"></path><rect x=\"20\" y=\"108\" width=\"220\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">App ID</text><text x=\"130\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">qual app:</text><text x=\"130\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">com.example.planner</text><text x=\"130\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e os recursos dele</text><path d=\"M240 146 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-chain-ah-paper-dim)\"></path><rect x=\"20\" y=\"196\" width=\"220\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">aparelhos</text><text x=\"130\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">onde pode rodar</text><text x=\"130\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(nenhum na App Store)</text><path d=\"M240 234 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-chain-ah-paper-dim)\"></path><rect x=\"302\" y=\"104\" width=\"200\" height=\"92\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"402\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">perfil de provisionamento</text><text x=\"402\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">assinado pela Apple</text><text x=\"402\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">embutido no app</text><path d=\"M502 150 L556 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-chain-ah-paper-dim)\"></path><rect x=\"558\" y=\"124\" width=\"142\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"629.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o app assinado</text><rect x=\"470\" y=\"248\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"500\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">tem data de vencimento</text></svg>", "caption": "Toda caixa com borda tracejada tem uma data. O App ID é o único elo que nunca vence.", "same": ["App ID"]}
```

## Os quatro elos

**O certificado diz quem.** Você cria uma chave privada no seu Mac e manda à Apple um **pedido de
assinatura de certificado**, que leva a metade pública. A Apple devolve um certificado que liga
essa chave pública à sua equipe. A chave privada nunca sai do Mac que a criou, e é essa a parte
que as pessoas perdem: um certificado no portal do desenvolvedor não serve para nada sem a chave
no chaveiro de algum Mac.

**O App ID diz qual app.** Ele é o **bundle identifier**, como `com.example.planner`, registrado
na sua conta, mais os **recursos** que o app usa: notificações push, iCloud, Sign in with Apple. Ele
faz o papel que o nome do pacote faz no Android, e também não pode mudar depois que o app é
publicado.

**Os entitlements dizem o que o app pode fazer.** São uma lista gravada na assinatura: este app
pode receber notificações push, pode compartilhar um grupo do chaveiro, pode usar este contêiner do
iCloud. Um recurso ligado no App ID e ausente dos entitlements, ou o contrário, é um erro de
assinatura na hora do build ou um recurso que não faz nada, em silêncio, na hora de rodar.

**O perfil de provisionamento amarra tudo.** É um arquivo, assinado pela Apple, que diz: *apps
assinados por estes certificados, com este App ID e estes entitlements, podem rodar nestes
aparelhos* — ou, para a App Store, em qualquer aparelho depois que a Apple os reassina. O Xcode o
embute no app como `embedded.mobileprovision`.

## Por que a cadeia, e não só uma chave

O Android deixa qualquer pessoa instalar o que decidir confiar; o iOS não deixa rodar nada que a
Apple não assinou. A cadeia é como a Apple delega: ela assina o seu certificado, o seu certificado
assina o app, e o perfil diz qual dos seus apps pode fazer o quê. **Tudo o que a Apple assinou pode
vencer ou ser revogado, que é a única propriedade que as chaves feitas em casa do Android não
têm**, e a seção "Vigiando o vencimento" trata de conviver com isso.

E o topo da cadeia também não é seu: o certificado intermediário da própria Apple, o Worldwide
Developer Relations, tem data de vencimento. O que está em uso desde janeiro de 2021 vence em 20 de
fevereiro de 2030.
