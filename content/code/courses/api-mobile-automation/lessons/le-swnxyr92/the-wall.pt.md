---
title: Por que todo teste de iOS precisa de um Mac
version: 1
---

**Toda ferramenta que compila um app iOS ou roda os testes dele numa tela roda no macOS, e em mais
nada.** O Xcode, o ambiente de desenvolvimento da Apple, só é publicado para Mac. O iOS Simulator
faz parte do Xcode. Os dois frameworks desta lição, Swift Testing e XCUITest, são rodados pelo Xcode
ou pelo seu gêmeo de linha de comando, o `xcodebuild`. E o próprio macOS só pode ser instalado em
computadores da Apple, pela licença que a Apple publica com ele. Um Mac virtual num notebook
Windows não é um caminho que este curso possa recomendar.

A crença que isso corrige é esperançosa: a de que alguma ferramenta, talvez o Appium, abra o iOS
para um computador Windows ou Linux. Não abre. O teste da lição 15 pede `platformName: iOS` de
qualquer computador. Mas o servidor Appium com que ele fala precisa rodar num Mac com Xcode. O
driver XCUITest compila e roda ali o WebDriverAgent, um executor de testes feito com o XCUITest da
Apple. **O cliente pode estar em qualquer lugar; a máquina que toca o iPhone é sempre um Mac.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 298\" role=\"img\" aria-label=\"Três regiões, uma dentro da outra. A de fora é qualquer computador com Swift 6, macOS, Linux ou Windows: ali rodam os testes Swift Testing da lógica por trás das telas, e também o código de um cliente Appium. Dentro dela, um Mac com Xcode: o iOS Simulator, que faz parte do Xcode, o XCUITest no simulador e o servidor Appium quando o app é iOS. Dentro desta, um iPhone e uma Apple Account: um build que o Xcode assina para o seu celular, e o celular com o Modo de Desenvolvedor ligado.\"><rect x=\"20\" y=\"30\" width=\"660\" height=\"240\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"34\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">qualquer computador com Swift 6: macOS, Linux ou Windows</text><rect x=\"36\" y=\"92\" width=\"176\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"124\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Swift Testing</text><text x=\"124\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a lógica por trás das telas</text><rect x=\"36\" y=\"168\" width=\"176\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"124\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um cliente Appium</text><text x=\"124\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o código do próprio teste</text><rect x=\"228\" y=\"58\" width=\"436\" height=\"198\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"242\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um Mac com Xcode</text><rect x=\"244\" y=\"92\" width=\"180\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"334\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o iOS Simulator</text><text x=\"334\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">parte do Xcode</text><rect x=\"244\" y=\"146\" width=\"180\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"334\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">XCUITest</text><text x=\"334\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o app num simulador</text><rect x=\"244\" y=\"200\" width=\"180\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"334\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o servidor Appium</text><text x=\"334\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">quando o app é iOS</text><rect x=\"440\" y=\"86\" width=\"210\" height=\"158\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"454\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">e um iPhone, uma Apple Account</text><rect x=\"454\" y=\"124\" width=\"182\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um build assinado</text><text x=\"545\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o Xcode assina para o seu celular</text><rect x=\"454\" y=\"184\" width=\"182\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Modo de Desenvolvedor</text><text x=\"545\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">ligado no celular</text><text x=\"350\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cada caixa precisa de tudo o que a envolve: um teste no iPhone precisa do Mac também</text></svg>", "caption": "O que cada nível de teste iOS exige. Só o anel de fora está aberto a um computador que não é um Mac.", "same": ["Swift Testing", "XCUITest"]}
```

## O que cada nível exige

- Código sem tela. As regras por trás das telas, como o jeito de escrever um preço ou de ler a
  resposta do boxoffice, podem ser testadas com Swift Testing onde quer que o Swift 6 rode. Isso é
  macOS,
  Linux e Windows, com o toolchain do swift.org. A seção 03 escreve esses testes.
- O app num simulador. Um Mac com o Xcode instalado pela Mac App Store, de graça. O simulador
  roda o app, e o XCUITest o conduz. A lição 19 diz o que é um simulador e o que ele esconde.
- O app num iPhone de verdade. O Mac, mais uma Apple Account conectada ao Xcode, mais o celular
  ligado ao computador e com o *Modo de Desenvolvedor* (Developer Mode) ativado nos ajustes. O iOS
  exige isso desde o iOS 16. Todo app que roda num iPhone é **assinado**, e o Xcode assina o seu build
  para o seu próprio celular. No momento em que este curso foi escrito, uma Apple Account gratuita
  faz isso para um aparelho seu, com limites de quanto tempo a assinatura dura. Entregar o app a
  testadores pelo TestFlight, ou publicá-lo, exige a assinatura paga do Apple Developer Program, em
  termos que a Apple define e muda.

**Um Mac não precisa estar na sua mesa.** Serviços de CI hospedados alugam máquinas macOS por
minuto. As nuvens de dispositivos da lição 20 oferecem iPhones reais pela rede. Algumas empresas
alugam Macs inteiros num data center. Todos rodam em hardware da Apple, que é o que a licença pede.

## O que esta lição faz, e o que não faz

**Nada nesta lição foi rodado.** O curso foi gravado numa máquina Linux sem nenhum Mac ao alcance. O
toolchain do Swift também não pôde ser baixado ali, então nem os testes Swift Testing da seção 03
foram compilados. Todo arquivo Swift desta lição foi escrito contra as APIs que a Apple documenta, e é
curto de propósito para que cada linha possa ser lida. Nenhuma saída, relatório ou captura de
tela dele aparece, porque nenhum foi feito.

Sem um Mac, esta lição permite ler uma suíte iOS e revisar uma. Você pode escrever os casos que ela
deveria ter e conversar sobre ela com quem desenvolve e roda. Se você tem um Mac, todo
arquivo daqui foi feito para ser digitado e rodado, e a seção 05 diz como.
