---
title: O arquivo, o build que você entrega
version: 1
---

**Um arquivo (archive) é um build Release do app, assinado, com os símbolos de depuração ao lado,
guardado para você poder distribuí-lo e depois entender os relatórios de falha dele.** É o que
*Product*, *Archive* produz no Xcode, e é o único build que o App Store Connect aceita. Nada aqui foi
executado: não há Mac na gravação deste curso. Foi escrito a partir da ajuda do Xcode da Apple sobre
distribuir um app, lida em 30 de outubro de 2026.

Escolha *Any iOS Device* como destino, não um simulador, e rode o *Archive*. O Xcode compila com a
configuração **Release** do scheme, da aula 1, seção 06, assina com a identidade do time e abre o
**Organizer**, que lista cada arquivo com a versão e o número do build. Dali, *Distribute App* o
assina de novo para onde ele vai, App Store Connect, Ad Hoc ou desenvolvimento, e o envia ou exporta.

## Os mesmos passos, na linha de comando

Um servidor de build faz o mesmo com o `xcodebuild`, e ver os dois comandos deixa claros os dois
passos. Eles não foram executados:

```sh
# archive.sh: archive the planner and export it for App Store Connect
xcodebuild archive \
  -project Planner.xcodeproj \
  -scheme Planner \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/Planner.xcarchive

xcodebuild -exportArchive \
  -archivePath build/Planner.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/export
```

O primeiro compila e assina o arquivo. O segundo o assina de novo para o destino, que o
`ExportOptions.plist` cita, e grava o arquivo `.ipa` que é enviado.

## O que o arquivo guarda para depois

**O dSYM**, os símbolos de depuração, é a parte que as pessoas esquecem. Um relatório de falha do
telefone de alguém lista endereços de memória; com o dSYM do arquivo esses endereços voltam a ser
nomes de função e números de linha. Apague o arquivo e as falhas daquele build não podem mais ser
lidas. As aulas 12 e 13 de `mobile-delivery` tratam de enviar símbolos e ler os stack traces.

**Todo arquivo que você envia precisa de um número de build maior**, o `CFBundleVersion` da aula 1,
seção 08, e a aula 22 começa onde o envio termina.
