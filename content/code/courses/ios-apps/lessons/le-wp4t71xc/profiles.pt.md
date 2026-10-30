---
title: Perfis de provisionamento, a autorização por escrito
version: 1
---

**Um perfil de provisionamento é um arquivo, assinado pela Apple, que diz que este app, assinado por
estes certificados, pode rodar nestes aparelhos e usar estes entitlements.** O certificado diz quem
você é. O perfil diz o que você pode fazer com essa identidade, e o aparelho o confere na instalação.
Nada nesta seção foi executado; ela foi escrita a partir da ajuda da conta da Apple sobre perfis de
provisionamento, lida em 30 de outubro de 2026.

Um perfil de desenvolvimento guarda quatro coisas, e a página da Apple *Create a development
provisioning profile* as pede nesta ordem:

1. **um App ID**, o team identifier e o bundle identifier da aula 1, seção 07;
2. **um ou mais certificados de desenvolvimento**, as pessoas que podem assinar este app;
3. **um ou mais aparelhos registrados**, pelo seu identificador único, até os limites da seção 02;
4. **os entitlements** com que o App ID foi registrado, que a seção 07 confere.

Ele carrega também uma **data de validade**, e um perfil vencido é o motivo mais comum de um build que
funcionava ontem não instalar hoje. Um perfil de distribuição para a App Store não cita aparelhos: a
loja instala em todo aparelho, depois da sua própria revisão.

## Os tipos

| perfil | para | cita aparelhos? |
|---|---|---|
| iOS App Development | rodar a partir do Xcode nos seus aparelhos registrados | sim |
| Ad Hoc | entregar um build a testadores registrados sem a loja | sim |
| App Store Connect | enviar para o TestFlight e a App Store | não |

**Um perfil é uma property list assinada, e dá para lê-la.** Num Mac,
`security cms -D -i profile.mobileprovision` tira a assinatura e imprime o plist de dentro, com o
`ExpirationDate`, os `Entitlements`, os `ProvisionedDevices` e o `TeamIdentifier`. Esse comando não foi
executado para este curso; é o primeiro a digitar quando um erro de assinatura não faz sentido, porque
mostra o que o perfil diz de fato, e não o que você acha que ele diz.

Os perfis moram no Mac num diretório do próprio Xcode, e o Xcode os baixa da sua conta. Com a
assinatura automática, da seção 08, você raramente vê um, até um vencer.
