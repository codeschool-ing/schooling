---
title: O bundle identifier, o único nome que não muda
version: 1
---

**O bundle identifier de um app é a identidade dele para o iOS e para a App Store, e depois que um
build foi enviado ao App Store Connect ele nunca mais pode mudar.** É uma string em formato de DNS
invertido, `com.example.planner`, feita de um domínio que você controla escrito ao contrário e de um
nome para o app. O iOS o usa para distinguir apps: dois apps com o mesmo identificador são o mesmo
app, e instalar o segundo substitui o primeiro.

A crença a largar é que o identificador é um rótulo como o nome do app. O nome embaixo do ícone é o
`CFBundleDisplayName`, e você pode mudá-lo a cada versão. O identificador está mais perto de uma chave
primária: o registro na App Store, os dados do app em cada telefone onde ele está instalado, as
entradas dele no keychain, o registro de notificações push e os contêineres do iCloud penduram todos
nele. **Renomeie um app e nada se mexe. Mude o identificador e você publicou outro app**, sem
avaliações, sem usuários e sem nenhum dos dados deles.

## As regras

A documentação da Apple para o `CFBundleIdentifier`, lida em 30 de outubro de 2026, as enuncia, e a
seção 08 confere um arquivo contra a primeira:

- letras de `A` a `Z` e de `a` a `z`, dígitos, hífens e pontos, e nada mais;
- ordem de DNS invertido, da parte mais geral para a mais específica;
- ele não diferencia maiúsculas de minúsculas, nas palavras da própria documentação, então
  `com.example.Planner` e `com.example.planner` são um identificador só e a caixa nunca separa dois
  apps.

`com.example.planner` usa `example.com`, um domínio reservado para exemplos. **Para um app seu, use
um domínio que você tenha**, escrito ao contrário. Se você não tem nenhum, um nome que comece pelo seu
sobrenome ou pelo nome da sua conta é uma convenção segura, e a App Store recusa um identificador que
alguém já registrou.

## Onde ele é escrito, e por onde ele viaja

No Xcode o identificador é o campo *Bundle Identifier* do target do app, que grava a configuração de
build `PRODUCT_BUNDLE_IDENTIFIER`, e o build o copia para o `Info.plist` como `CFBundleIdentifier`. Os
targets de teste ganham identificadores próprios, derivados do do app com um sufixo. Uma **extensão
de app** — um widget, uma extensão de compartilhamento — tem de ter um identificador que comece pelo
do app, `com.example.planner.widget`, porque é por esse prefixo que o iOS sabe que a extensão pertence
ao app.

Quando a aula 21 assina o app, o identificador ganha a companhia de um **team identifier**, dez
caracteres que a Apple atribui à sua conta de desenvolvedor, e os dois juntos são o **App ID** do app:
`ABCDE12345.com.example.planner`. É por isso que o mesmo identificador não pode ser registrado por
duas contas, e por isso que um erro de assinatura tantas vezes acaba sendo um identificador digitado
um pouco diferente em dois lugares.
