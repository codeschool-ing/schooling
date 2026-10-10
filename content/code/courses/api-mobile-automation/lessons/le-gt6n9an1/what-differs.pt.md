---
title: O que muda quando o que se testa é um app
version: 1
---

**A segunda metade deste curso testa algo que uma pessoa segura na mão, e quase toda suposição da
primeira metade deixa de valer.** Uma API espera num endereço por uma requisição e a responde. Um app
é um programa instalado no celular de alguém, dividindo esse celular com outros cem, à mercê de uma
bateria, de um sinal e de um sistema operacional que pode pará-lo quando quiser. As lições 1 a 13
eram sobre se uma resposta está certa. As lições 14 a 22 são sobre se o app faz a coisa certa com
ela, num aparelho que você não controla.

O erro comum é pensar em teste mobile como teste web numa tela pequena. Algumas ideias passam
inteiras: você ainda desenha casos, ainda automatiza os que valem a repetição, ainda encontra
elementos numa tela e age sobre eles, o que `web-automation` ensinou se você o fez. O que muda é a
lista abaixo, e cada item é uma lição própria mais adiante.

| | uma página web | um app |
|---|---|---|
| **como chega** | um endereço num navegador; toda visita carrega a versão atual | um pacote instalado, um APK no Android; versões antigas ficam instaladas por meses |
| **onde roda** | um punhado de navegadores | milhares de modelos de celular, uma dúzia de versões do Android em uso ao mesmo tempo (lição 20) |
| **sua vida** | aberta ou fechada | iniciado, pausado, mandado para segundo plano, encerrado para liberar memória, restaurado (lição 21) |
| **o que pode fazer** | o que o navegador permite | o que a pessoa concedeu: câmera, localização, notificações, cada uma pedida em tempo de execução (lição 21) |
| **sua rede** | presumida | um túnel, um elevador, um trem: lenta, perdida, de volta (lição 22) |
| **como você o toca** | mouse e teclado | toques, deslizes, toques longos, rotação, o botão voltar (lição 21) |
| **onde os testes rodam** | um navegador em qualquer computador | um emulador, um aparelho real ou uma fazenda deles (lições 19 e 20) |

## Três lugares onde um teste mobile pode morar

Na web existe mais ou menos um tipo de teste de navegador. No Android existem três, e a diferença é
**onde o código do teste roda em relação ao app**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 266\" role=\"img\" aria-label=\"Três lugares onde um teste mobile pode morar. Um teste local roda no computador, na JVM, sem Android. Um teste instrumentado como o Espresso roda no dispositivo, dentro do processo do próprio app, ao lado do Tickets. Um teste de ponta a ponta como o Appium roda no computador e alcança o app por fora, pela camada de acessibilidade do dispositivo, a árvore do que está na tela.\"><defs><marker id=\"f14where-tests-run-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"250\" height=\"200\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"145\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">seu computador</text><rect x=\"330\" y=\"30\" width=\"350\" height=\"200\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"505\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o dispositivo: emulador ou celular</text><rect x=\"470\" y=\"70\" width=\"190\" height=\"140\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">o processo do app</text><rect x=\"485\" y=\"100\" width=\"160\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tickets</text><text x=\"565\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o app</text><rect x=\"485\" y=\"154\" width=\"160\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">teste instrumentado</text><text x=\"565\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Espresso</text><rect x=\"40\" y=\"70\" width=\"210\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">teste local</text><text x=\"145\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">JVM no computador, sem Android</text><rect x=\"40\" y=\"154\" width=\"210\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">teste de ponta a ponta</text><text x=\"145\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Appium</text><rect x=\"345\" y=\"100\" width=\"105\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"397.5\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">acessibilidade</text><text x=\"397.5\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a árvore da tela</text><line x1=\"250\" y1=\"176\" x2=\"343\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f14where-tests-run-ah)\"></line><line x1=\"450\" y1=\"122\" x2=\"483\" y2=\"122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f14where-tests-run-ah)\"></line><text x=\"350\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">quanto mais longe do app o teste roda, mais ele vê como uma pessoa, e mais lento ele é</text></svg>", "caption": "Onde o código do teste roda decide o que ele vê: nada da tela, o app por dentro, ou a tela como uma pessoa a vê.", "same": ["Tickets"]}
```

- **Um teste local** roda na própria JVM do seu computador, sem Android. É rápido, segundos para
  centenas, e só testa código que não precisa de tela: a formatação de preço do app que você monta
  na seção 05, por exemplo.
- **Um teste instrumentado** é empacotado num segundo APK e roda no aparelho, **dentro do processo do
  próprio app**, então enxerga as views do app e espera as threads dele. O Espresso, da lição 16,
  funciona assim. É rápido para um teste em aparelho e só conhece este app.
- **Um teste de ponta a ponta** roda no seu computador e conduz o aparelho por fora, pela camada de
  acessibilidade, do jeito que uma pessoa faria: vê o que está na tela e nada mais. O Appium, da
  lição 15, funciona assim. Ele atravessa apps (o diálogo de permissão é do Android, não do app) e é
  o mais lento dos três.

A pirâmide de testes vale aqui como em todo lugar: muitos testes locais, menos instrumentados, um
punhado de ponta a ponta. E a primeira metade deste curso fica embaixo dos três, porque um app cuja
API está errada está errado em toda tela.

## As duas plataformas, e a que este curso roda

Android e iOS compartilham essas ideias e nada mais: linguagens diferentes, ferramentas diferentes,
regras diferentes sobre o que um teste pode tocar. **Este curso roda Android e descreve o iOS por
fora.** Testar um app iOS exige o Xcode, e o Xcode só roda no macOS; não existe caminho para ele a
partir do Windows ou do Linux a preço nenhum. A lição 18 explica o que o XCUITest e o Swift Testing
fazem e como se comparam, para que você leia uma suíte iOS e converse sobre uma, e diz com clareza
que você não vai rodar uma neste curso a menos que tenha um Mac.
