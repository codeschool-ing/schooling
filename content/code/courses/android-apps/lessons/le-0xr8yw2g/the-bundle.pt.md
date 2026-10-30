---
title: "O app bundle, e os APKs que o Google monta a partir dele"
version: 1
---

**Um APK é o que um celular instala; um app bundle é o que você entrega ao Google Play para que ele
monte os APKs.** A documentação do Google diz isso com todas as letras: desde agosto de 2021, apps
novos precisam ser publicados no Google Play com o Android App Bundle. O `bundlePlayRelease`, no
build de release da seção 04, escreveu um:

```
ana@vm:~/planner$ unzip -l app/build/outputs/bundle/playRelease/app-play-release.aab | tail -1
 15398689                     87 files
ana@vm:~/planner$ unzip -l app/build/outputs/bundle/playRelease/app-play-release.aab | grep -E " (BundleConfig.pb|base/manifest/AndroidManifest.xml|base/dex/classes.dex|base/resources.pb|META-INF/UPLOAD.RSA)$"
      628  1981-01-01 01:01   BundleConfig.pb
  1130676  1981-01-01 01:01   base/dex/classes.dex
     5063  1981-01-01 01:01   base/manifest/AndroidManifest.xml
    46001  1981-01-01 01:01   base/resources.pb
     1983  1981-01-01 01:01   META-INF/UPLOAD.RSA
ana@vm:~/planner$ unzip -l app/build/outputs/bundle/playRelease/app-play-release.aab | grep -E "base/lib/" | awk "{print \$4}"
base/lib/arm64-v8a/libandroidx.graphics.path.so
base/lib/armeabi-v7a/libandroidx.graphics.path.so
base/lib/x86/libandroidx.graphics.path.so
base/lib/x86_64/libandroidx.graphics.path.so
```

O bundle é um zip como o APK, organizado de outro jeito. `base/` é o único módulo do app, com o
manifesto, o dex e os recursos num formato que o Play lê, `resources.pb`. `BundleConfig.pb` descreve
como o Play pode dividi-lo. `META-INF/UPLOAD.RSA` é a assinatura, pela chave de upload da seção 04. E
`base/lib/` guarda uma biblioteca nativa em quatro builds, um por família de processador, dos quais
cada celular precisa de exatamente um.

**Esse último fato é a razão do formato.** Um celular com processador `arm64-v8a` e uma tela de certa
densidade precisa de uma biblioteca nativa, de uma densidade de imagens e dos recursos de idioma que
usa. A partir de um bundle, o Google Play monta **APKs divididos** por aparelho e entrega a cada
celular só o que ele precisa; a documentação descreve isso como o Play gerando e servindo APKs
otimizados para cada configuração de aparelho. Um APK universal, como os da lista da seção 04, leva
as quatro bibliotecas a todo celular.

## Vendo o que um celular receberia

**Não executado.** O `bundletool` do Google, um download à parte, monta a partir de um bundle os
mesmos APKs divididos que o Play montaria, para um aparelho específico ou para a descrição de um, e
pode instalá-los num celular conectado. Ele não foi baixado para este curso, então os tamanhos por
aparelho que ele relataria não aparecem aqui. O Play Console mostra os mesmos números para cada
bundle enviado, por modelo de aparelho.

## Quem assina os APKs que o Play monta

Os APKs que chegam aos celulares são montados pelo Google, então é o Google que os assina, com a
**chave de assinatura do app**, que ele guarda. Esse é o assunto da próxima seção, e o motivo de a
chave que você criou se chamar chave de upload.
