---
title: App Store Connect, onde o app é um registro
version: 1
---

**O App Store Connect é o site onde um app existe como registro antes de existir na loja: o nome, o
bundle identifier, os builds, os testadores, a listagem e as revisões.** O arquivo da aula 21, seção
09, é enviado para ele, e nada chega ao TestFlight ou à App Store sem passar por ele. Ele exige a
assinatura paga que a aula 21, seção 02, mostrou custar 99 dólares americanos por ano. **Nada nesta
aula foi executado para o curso**: nenhum registro foi criado e nenhum build foi enviado. Ela foi
escrita a partir da ajuda do App Store Connect, da página de requisitos futuros da Apple e das App
Review Guidelines, todas lidas em 30 de outubro de 2026, e as datas e números abaixo são os delas
naquele dia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l22-pipeline\" aria-label=\"O caminho de um arquivo até a loja. O arquivo é enviado ao App Store Connect e processado. Ele chega aos testadores internos na hora. O primeiro build para testadores externos passa antes pela App Review. Quando a versão é enviada, a App Review lê o app e a listagem contra as diretrizes. Um build aprovado é lançado. Um rejeitado volta com o número de uma diretriz, para uma resposta, uma correção e um build novo, ou uma vez para um recurso.\"><defs><marker id=\"l22-pipeline-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l22-pipeline-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l22-pipeline-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l22-pipeline-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">envio</text><text x=\"80\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o arquivo, aula 21</text><rect x=\"160\" y=\"40\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"220\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">processamento</text><text x=\"220\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">minutos ou mais</text><rect x=\"300\" y=\"40\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">TestFlight</text><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">internos na hora</text><rect x=\"440\" y=\"40\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">App Review</text><text x=\"500\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">contra as diretrizes</text><rect x=\"580\" y=\"40\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">lançado</text><text x=\"640\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">na hora ou numa data</text><path d=\"M140 70 L158 70\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-pipeline-ah-wire)\"></path><path d=\"M280 70 L298 70\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-pipeline-ah-wire)\"></path><path d=\"M420 70 L438 70\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-pipeline-ah-wire)\"></path><path d=\"M560 70 L578 70\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-pipeline-ah-wire)\"></path><rect x=\"300\" y=\"150\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">testadores externos</text><text x=\"360\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o primeiro build revisado</text><path d=\"M360 100 L360 148\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l22-pipeline-ah-wire)\"></path><rect x=\"440\" y=\"200\" width=\"260\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">rejeitado: o número de uma diretriz</text><text x=\"570\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">responder, corrigir, build novo</text><text x=\"570\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ou um recurso</text><path d=\"M500 100 L500 198\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-pipeline-ah-amber)\"></path><path d=\"M440 250 C 120 260, 60 200, 70 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l22-pipeline-ah-paper-dim)\"></path><text x=\"180\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um número de build maior</text></svg>", "caption": "Todo build passa pelo App Store Connect, e todo caminho de volta de uma rejeição é um build novo com número maior.", "same": ["App Review", "TestFlight"]}
```

## Primeiro o registro

A página de ajuda da Apple *Add a new app* diz isso na primeira linha: "Before uploading a build of
your app to App Store Connect, first create an app record". O registro pede uma plataforma, um nome,
um idioma principal, o **bundle identifier** registrado na aula 21 e um SKU, um identificador seu
para os seus controles. O status começa como *Prepare for Submission*, e a página avisa do passo que
derruba as pessoas primeiro: o Account Holder tem de ter assinado o acordo mais recente na seção
*Business* antes de qualquer app ser acrescentado.

**O nome é reservado por idioma**, e é o único campo que bate com estranhos. A resposta da própria
página, quando outra pessoa tem o nome que você queria, é escolher outro, ou abrir uma reclamação se
você tiver a marca registrada.

## O build tem de ser recente o bastante

Cada envio é conferido contra os mínimos atuais da Apple, e eles mudam todo ano. Em 30 de outubro de
2026 a página de requisitos futuros dizia que desde 28 de abril de 2026 "apps uploaded to App Store
Connect must be built with Xcode 26 or later using an SDK for iOS 26", e que desde 9 de setembro de
2026 os apps iOS "must target iOS 13 or later". O planner mira o iOS 17 e a aula 1 o escreveu contra
o Xcode 27.1, então cumpre os dois. **Leia essa página antes de todo lançamento**: um envio compilado
com o Xcode do ano passado é recusado no envio, antes de alguém olhar o app.

Depois do envio, um build é *processado*, o que leva de minutos a mais que isso, e então aparece no
TestFlight com a versão e o número do build. Um número de build já usado na mesma versão é recusado,
que é o `CFBundleVersion` da aula 1, seção 08, trabalhando.

## Papéis

O App Store Connect tem papéis próprios, separados dos da conta de desenvolvedor: um **Account
Holder**, **Admins**, **App Managers**, que podem criar registros e enviar, **Developers**, que podem
enviar builds, e papéis para finanças, marketing e vendas. A página de novo app exige "Account
Holder, App Manager, or Admin". Quem escreve o código e envia builds não precisa de mais que
Developer, e **dar Admin a todo mundo é como um prestador acaba podendo remover o app**.
