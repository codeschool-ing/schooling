---
title: Interrupções
version: 1
---

**Um celular interrompe o app da frente o dia inteiro, e quase toda interrupção é uma das mudanças de
estado da seção 04 com outra roupa.** Uma ligação toma a tela e a devolve. A aba de notificações
desliza por cima do app. O teclado sobe e cobre metade dele. Uma pessoa põe o celular no tema escuro
às nove da noite. Testar cada uma como um caso próprio multiplica a suíte. Testar cada uma pelo
estado que ela provoca a mantém pequena.

## As mais comuns, e como provocá-las

| interrupção | o que acontece com o app | como provocar no emulador | pelo Appium |
|---|---|---|---|
| **chega uma ligação** | a tela da ligação o cobre; ele vai para o segundo plano até a ligação acabar | `adb emu gsm call 5551234`, depois `adb emu gsm cancel 5551234` | `mobile: gsmCall`, `{ phoneNumber, action: 'call' }`, depois `'cancel'` |
| **a aba de notificações** | fica embaixo, sem o foco, até a aba fechar | `adb shell cmd statusbar expand-notifications`, depois `collapse` | `mobile: openNotifications` |
| **Home, outro app, volta** | o segundo plano, talvez uma morte de processo | seção 04 | seção 04 |
| **a tela bloqueia** | parado até ser desbloqueado | `adb shell input keyevent KEYCODE_POWER` | `mobile: lock`, `mobile: unlock` |
| **o tema escuro, o tamanho da fonte, o idioma** | destruído e recriado, como numa rotação | `adb shell cmd uimode night yes`; `adb shell settings put system font_scale 1.3` | `mobile: shell`, com os mesmos comandos |
| **o botão voltar** | a tela da frente é encerrada; a partir da lista, o app sai | `adb shell input keyevent KEYCODE_BACK` | `driver.back()` |
| **o teclado** | metade da tela coberta enquanto um campo tem o foco | tocar num campo de texto | `mobile: isKeyboardShown`, `mobile: hideKeyboard` |

O `adb emu` manda um comando para o console do próprio emulador, então a ligação só existe num
emulador. Um celular de verdade precisa de uma ligação de verdade. **Nada disso foi rodado para este
curso**, pelo motivo que o resto da lição dá.

## Quais merecem um teste

O Tickets responde à tabela de três jeitos, e esse é o jeito útil de lê-la:

- Tudo o que recria a activity é um caso só. Rotação, tema escuro, tamanho da fonte e idioma
  chegam ao mesmo código, então o defeito da seção 05 aparece nos quatro. Um teste com
  `recreate()` ou uma rotação cobre a classe inteira. Escreva esse teste uma vez por tela.
- Tudo o que manda o app embora é o segundo plano e, às vezes, uma morte de processo. Uma
  ligação, um bloqueio e o botão Home são diferentes para uma pessoa e não para o Tickets. Os dois
  testes da seção 05 os cobrem.
- O que fica na tela é uma verificação de layout, não de estado. A aba e o teclado cobrem o app
  sem mudá-lo. O teclado importa onde há um campo, e o Tickets não tem nenhum, então não há o que
  testar hoje. Num app com formulário, o caso é o botão de enviar escondido debaixo do teclado na
  menor tela da matriz da lição 20. O `closeSoftKeyboard()` do Espresso ou o `hideKeyboard` do
  Appium entram no teste antes do toque.

**O botão voltar merece uma linha própria num plano de testes**, porque é a interrupção que a pessoa
provoca de propósito. Na tela do espetáculo, ele deve voltar à lista como ela estava, linhas e faixa,
sem carga nova. Na lista, ele sai do app. Isso é uma activity encerrada, que o Android não
restaura, então a próxima abertura é a frio. O `pressBack()` do Espresso e o `driver.back()` do
Appium o apertam.

**E uma ligação ainda vale uma passada manual por versão.** Uma ligação chegando por cima de uma tela
no meio de um pagamento é a interrupção de que uma pessoa se lembra. É mais barato testá-la num
emulador por um minuto do que automatizar um telefone.
