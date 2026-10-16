---
title: Rodando testes de iOS, à mão e numa esteira
version: 1
---

**O Xcode roda um teste a partir de um botão, o `xcodebuild` roda os mesmos testes de um terminal, e
os dois precisam de um Mac.** O primeiro serve para escrever um teste, o segundo para uma esteira, a
mesma divisão que a lição 16 fez entre o Android Studio e o Gradle. Nada nesta seção foi rodado para
este curso, e nenhuma saída aparece para nada dela.

## No Xcode

Escolha um simulador na barra de ferramentas no alto da janela, um modelo de iPhone com uma versão
do iOS ao lado. *Product › Test*, ou Command-U, compila o app e os testes e inicia esse simulador. Ele
roda todos os testes que o projeto tem, Swift Testing e XCTest juntos. O *Test navigator* os lista,
com um losango ao lado de cada teste e de cada classe que roda só aquele quando apertado. Uma falha
mostra a mensagem na linha que falhou, e o *Report navigator* guarda toda execução.

## Na linha de comando

Os simuladores que o Xcode instalou são listados pelo `simctl`, a ferramenta dele para isso, e uma
execução escolhe um pelo modelo:

```sh
xcrun simctl list devices available
xcodebuild test -project Tickets.xcodeproj -scheme Tickets \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -resultBundlePath build/Tickets.xcresult
```

- `-scheme` nomeia o que compilar e quais testes vêm junto. Um projeto novo tem um scheme, com o
  nome do app.
- `-destination` diz onde rodar. O nome precisa ser um simulador que o `simctl` listou. Quais
  iPhones existem depende da versão do Xcode, então `iPhone 16` é um exemplo e não uma promessa.
- `-resultBundlePath` grava os resultados e os logs da execução num pacote só,
  `Tickets.xcresult`. O Xcode o abre, e um servidor de CI pode guardá-lo como artefato.
- `-only-testing:TicketsUITests/TicketsUITests/testAShowOpensWithItsSeats` roda um teste, nomeado
  como alvo, classe e método.

O `xcodebuild` sai com código diferente de zero quando um teste falha, que é tudo o que uma esteira
precisa dele, como a lição 6 disse do Newman. O pacote Swift da seção 03 não precisa de nada disso.
`swift test` em `ios/TicketsCore` compila e roda os testes dele, num Mac ou no Linux ou Windows com
Swift 6.

## Numa esteira

Uma esteira para testes de interface iOS precisa de uma máquina macOS, e essa é a parte cara.
**Serviços de CI hospedados cobram mais por um minuto de macOS que por um de Linux, várias vezes
mais no momento em que este curso foi escrito.** Uma máquina macOS também demora mais para ser obtida e
para iniciar. Os preços e os multiplicadores mudam, então confira a página do próprio serviço e não
um número num curso.

Esse custo empurra a suíte para o formato que a lição 14 desenhou para o Android, e com mais força.
Muitos testes Swift Testing na lógica, que rodam nas máquinas Linux baratas. Menos testes XCUITest,
cada um ali porque o caminho de uma pessoa pelas telas precisa dele. E iPhones reais só onde se sabe
que o simulador esconde algo, que é o assunto da lição 19.
