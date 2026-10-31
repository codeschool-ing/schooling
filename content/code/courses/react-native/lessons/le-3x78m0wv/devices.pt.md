---
title: Um celular, um emulador, um simulador
version: 1
---

**Três lugares rodam o app nativo, e cada um precisa de algo que o computador de gravação deste curso
não tinha.** O que vem a seguir é ensinado a partir da documentação do Expo e das plataformas. *Nada
disto foi rodado para este curso*, e nada disto é necessário para terminá-lo; é como você vê o planner
desenhado por um celular, quando tiver os meios.

## Um celular com o Expo Go

O mais barato dos três. Instale o **Expo Go** pela App Store ou pelo Google Play, ponha o celular na
mesma rede Wi-Fi do computador, e suba o servidor de desenvolvimento:

```sh
npx expo start
```

Ele imprime um QR code no terminal. No Android, leia-o de dentro do Expo Go; num iPhone, com o app de
câmera, que oferece abri-lo no Expo Go. O celular baixa o bundle do seu computador, como o `curl` da
seção do Metro fez, e o planner aparece com views nativas de verdade. Salve um arquivo e o celular se
atualiza.

**Quando o celular não alcança o computador**, o que é comum em redes de escritório, escola e hotel que
isolam os aparelhos, o `npx expo start --tunnel` passa a conexão por um retransmissor público. É mais
lento, e manda o seu bundle pelo servidor de um terceiro, o que vale saber antes de usá-lo em código que
você não pode compartilhar.

O planner roda no Expo Go até a aula 17, em que ganha um módulo nativo próprio. Dali em diante ele
precisa do development build da seção anterior.

## Um emulador Android

**Um emulador é um celular Android rodando como programa**, e precisa de virtualização por hardware:
KVM no Linux, a Windows Hypervisor Platform no Windows, o Hypervisor framework num Mac. O *Device
Manager* do Android Studio cria um: escolha um celular, escolha uma imagem de sistema (um download à
parte, de vários gigabytes) e inicie-o. Depois, no terminal em que o `npx expo start` roda, aperte
**`a`**: o Expo instala o Expo Go no emulador, ou o seu development build se o `expo-dev-client` estiver
instalado, e abre o app. O `npx expo run:android` faz o build, a instalação e a abertura de uma vez.

Uma imagem de sistema para o processador do seu computador roda quase na velocidade nativa; uma
imagem ARM num computador Intel, ou o contrário, roda traduzida e devagar. Escolha a que o Device
Manager recomenda.

## O simulador de iOS

**Ele precisa de um Mac com o Xcode**, que é gratuito na Mac App Store e grande. Abra o Xcode uma vez
para deixá-lo instalar os componentes; depois, com o `npx expo start` rodando, aperte **`i`**, e o Expo
abre o simulador, instala o Expo Go nele e abre o app. O `npx expo run:ios` compila um development
build e o roda ali no lugar. O simulador roda o app iOS compilado para o próprio processador do Mac,
então é rápido, e não precisa de conta de desenvolvedor Apple.

## Um development build num iPhone de verdade

Este precisa de **assinatura**. O iOS se recusa a instalar um app que não esteja assinado por uma
identidade Apple em que o celular confia. Uma conta Apple gratuita assina um build para os seus
próprios aparelhos por sete dias de cada vez; o Apple Developer Program, pago, assina por mais tempo e
é exigido para publicar. A aula 20 explica a assinatura e os dois jeitos de fazê-la sem um Mac na sua
mesa.

## Qual usar

| você tem | use |
|---|---|
| um celular, qualquer computador | o Expo Go, até a aula 17; depois um development build (Android: esta aula; iPhone: aula 20) |
| nenhum celular, um computador com virtualização | o emulador Android |
| um Mac | o simulador de iOS, e o emulador Android ao lado |
| nada disso | o navegador e os testes, que é como este curso foi gravado |
