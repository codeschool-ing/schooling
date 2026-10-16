---
title: Emulador, simulador e aparelho são três coisas diferentes
version: 1
---

**Um emulador imita o hardware de um celular e roda nele o sistema operacional de verdade; um
simulador imita o sistema operacional e roda no hardware do próprio computador; um aparelho não
imita nada e só é verdade para si mesmo.** As palavras são usadas sem cuidado, muitas vezes como se
fossem a mesma, e esse hábito esconde justamente o assunto desta lição: cada um dos três erra num
lugar diferente, então um defeito que um deles não consegue mostrar é um defeito que outro pode
mostrar muito bem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" aria-label=\"Três colunas, cada uma com três camadas: o app, o sistema e o hardware. Emulador Android: o app é o mesmo APK que um celular recebe e o Android é a imagem real do Google, iniciada, os dois reais; o hardware é inventado, propriedade por propriedade. iOS Simulator: o app é compilado para o processador do Mac, o iOS são frameworks de simulador no macOS, e o hardware é o do próprio Mac, sem celular nenhum, os três imitados ou diferentes. Um aparelho real: o build que um usuário instala, o build do próprio fabricante para o sistema e um modelo real de hardware, todos reais.\"><text x=\"120\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Emulador Android</text><rect x=\"20\" y=\"62\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o app</text><text x=\"120\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o mesmo APK que um celular recebe</text><rect x=\"20\" y=\"124\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Android</text><text x=\"120\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a imagem do Google, iniciada</text><rect x=\"20\" y=\"186\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"120\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o hardware</text><text x=\"120\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">inventado, propriedade por propriedade</text><text x=\"350\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">iOS Simulator</text><rect x=\"250\" y=\"62\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"350\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o app</text><text x=\"350\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">compilado para o processador do Mac</text><rect x=\"250\" y=\"124\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"350\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">iOS</text><text x=\"350\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">frameworks de simulador no macOS</text><rect x=\"250\" y=\"186\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"350\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o hardware</text><text x=\"350\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o do próprio Mac: celular nenhum</text><text x=\"580\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um aparelho real</text><rect x=\"480\" y=\"62\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o app</text><text x=\"580\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o build que um usuário instala</text><rect x=\"480\" y=\"124\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o sistema</text><text x=\"580\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o build do próprio fabricante</text><rect x=\"480\" y=\"186\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o hardware</text><text x=\"580\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">um modelo real</text><rect x=\"150\" y=\"262\" width=\"26\" height=\"16\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"184\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o de verdade</text><rect x=\"370\" y=\"262\" width=\"26\" height=\"16\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"404\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">imitado, ou outro build</text></svg>", "caption": "O emulador imita o hardware, o simulador imita o sistema, e um aparelho é real em todas as camadas, só para um modelo.", "same": ["Android", "iOS", "iOS Simulator"]}
```

## O emulador Android

O emulador da lição 14 é uma máquina virtual. Ele **inicia o Android**, uma imagem de sistema real
montada pelo Google, com kernel próprio, num hardware que o emulador inventa: processador, memória,
tela, bateria, GPS, câmeras e sensores. O processador é real, emprestado do seu computador pela
virtualização que a lição 14 pediu para ligar, e é por isso que a imagem precisa combinar com ele,
x86_64 num PC e arm64 num Mac com Apple silicon. Todo o resto é imitado, e a imitação é declarada,
propriedade por propriedade, numa lista que vem com o emulador. Três delas, lidas do SDK da máquina
de gravação:

```
ana@laptop:~$ grep -A4 -E '^name += hw\.(gps|battery|accelerometer)$' ~/Android/Sdk/emulator/lib/hardware-properties.ini
name        = hw.gps
type        = boolean
default     = yes
abstract    = GPS support
description = Whether there is a GPS in the device.
--
name        = hw.battery
type        = boolean
default     = yes
abstract    = Battery support
description = Whether the device can run on a battery.
--
name        = hw.accelerometer
type        = boolean
default     = yes
abstract    = Accelerometer
description = Whether there is an accelerometer in the device.
```

**Uma bateria é um sim ou não**: o celular virtual tem uma ou não tem, e a carga dela é um número que
você define na janela *Extended controls* do emulador. O GPS também, e a posição dele é o que você
digitar ali. O APK é o mesmo arquivo que um celular recebe, e o Android o roda com o mesmo código que
um celular rodaria; o que difere é tudo o que fica abaixo do Android.

## O simulador do iOS

O iOS Simulator da lição 18 não é uma máquina virtual e não inicia nada. **O app é compilado para o
processador do próprio Mac e roda como um processo no macOS**, ligado a versões dos frameworks da
Apple feitas para o simulador. Ele parece um iPhone porque desenha um. Não há hardware de celular
nenhum por baixo: memória, processador, disco e rede são do Mac, e é por isso que `localhost` lá
dentro alcançou o boxoffice na lição 18 sem o `10.0.2.2` de que um emulador precisa.

Isso o deixa rápido para iniciar e ágil para rodar, e significa que o binário que você testa não é
o binário que um iPhone roda: o do celular é compilado de novo, para o processador do celular, e
assinado.

## Um aparelho real

Um celular na sua mão roda o build do fabricante para o sistema operacional, no hardware dele, com
os ajustes do dono, os outros apps do dono e a rede que houver na sala. **Nada é imitado, e nada se
generaliza**: um teste que passa num Samsung com Android 14 não diz nada certo sobre um Motorola com
Android 12. A lição 20 trata de escolher em quais poucos aparelhos confiar, e de alugar o resto.
