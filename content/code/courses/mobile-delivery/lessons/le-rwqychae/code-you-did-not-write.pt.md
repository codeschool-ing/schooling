---
title: Código que você não escreveu
version: 1
---

**O formulário pergunta sobre tudo o que o app manda, e uma biblioteca manda em seu nome.** Um
coletor de crashes manda pilhas de chamadas e modelos de aparelho; uma biblioteca de analytics
manda eventos e um identificador de instalação; uma biblioteca de publicidade manda muito mais. A
documentação da Apple diz isso numa linha: você declara as práticas dos **parceiros terceiros cujo
código integra ao app**, além das suas. Não saber o que uma biblioteca manda não é uma resposta que
alguma das lojas aceite.

## Descobrindo o que uma biblioteca manda

1. **Leia a documentação de privacidade dela.** Todo SDK sério publica uma página listando o que
   coleta, muitas vezes já mapeada para as categorias da Apple e do Google. O Firebase, o Sentry e
   os outros publicam.
2. **Leia a configuração dela.** A maioria coleta menos se pedirem: um coletor de crashes pode ser
   instruído a não mandar o identificador do usuário; uma biblioteca de analytics, a não coletar o
   ID de publicidade.
3. **Observe o tráfego.** Um proxy na sua mesa mostra o que o build de debug manda e para onde. O
   que você vê ali é a verdade que o formulário descreve; a lição 12 monta um coletor minúsculo que
   mostra o que um relatório de crash leva.

## O privacy manifest da Apple

A Apple introduziu o **privacy manifest** em 2023: um arquivo chamado `PrivacyInfo.xcprivacy`
dentro de um app ou de um SDK, que declara quais dados ele coleta e por que chama certas APIs. O
Xcode junta os manifests do app e das bibliotecas num único **relatório de privacidade**, que você
lê antes de preencher o formulário. A Apple também lista SDKs de uso comum que precisam trazer um
manifest, e uma assinatura quando vêm como binários compilados; um app que acrescenta um deles sem
isso é recusado no envio.

O manifest também cobre as **required reason APIs**: um punhado de APIs do sistema, como ler a
data de um arquivo ou o espaço livre em disco, que podem ser usadas para identificar um aparelho
pela impressão digital. Chamar uma delas exige declarar um dos motivos que a Apple lista para isso.

```xml
<!-- PrivacyInfo.xcprivacy: the planner reads UserDefaults for its own settings -->
<dict>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>CA92.1</string></array>
    </dict>
  </array>
</dict>
```

`CA92.1` é o código que a lista da Apple dá para ler e gravar informação que só o próprio app
alcança. *Não rodado: o manifest é lido pelo Xcode num Mac, e os códigos de motivo estão na página
da Apple sobre required reason APIs.*

## No Android e no React Native

O Android não tem um manifest desse tipo; o formulário de Segurança dos dados é a declaração, e o
Google espera que ele cubra os seus SDKs. O Google publica um **índice de SDKs** que diz quais
bibliotecas têm um guia de Segurança dos dados. Num app React Native, as bibliotecas nativas em
`ios/` e `android/` é que coletam, então o mesmo trabalho é feito para cada uma, e os config
plugins do Expo podem escrever o privacy manifest no projeto iOS por você.
