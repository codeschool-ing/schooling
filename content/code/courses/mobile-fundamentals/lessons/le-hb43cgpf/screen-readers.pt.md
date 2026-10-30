---
title: O que um leitor de tela lê, e como o usuário dele se move
version: 1
---

**Um leitor de tela transforma a tela numa lista e a lê em voz alta, um elemento por vez, a partir do
que o app declarou sobre cada elemento.** Ele não olha os pixels. Um tique desenhado em verde não
significa nada para ele; um botão que declarou "marcar como feita" significa muito. O leitor de tela
do Android é o **TalkBack**, o do iPhone é o **VoiceOver**, e os dois funcionam do mesmo jeito no
nível de que esta aula precisa.

A imagem comum é que acessibilidade é questão de botões grandes e texto grande, algo que um app
acrescenta no fim para poucos usuários. O leitor de tela é o caso que quebra essa imagem: para quem
não consegue ver a tela, um app que não declarou nada é um app sem interface nenhuma, e nada
acrescentado no fim conserta uma tela cujos controles nunca foram descritos.

## Como o usuário se move

**Um usuário que enxerga toca no que vê; um usuário de leitor de tela move um foco pela lista e
depois age sobre ele.** A documentação do Android sobre testes com o TalkBack descreve os dois jeitos
comuns. Na *navegação linear* o usuário desliza para a direita ou para a esquerda para ir ao elemento
seguinte ou anterior, e dá um toque duplo em qualquer lugar da tela para ativar o que está em foco.
Na *exploração por toque* ele arrasta um dedo pela tela e ouve o que está embaixo dele, e de novo
toca duas vezes para agir. A página da Apple sobre testes com o VoiceOver lista o mesmo deslize para
a direita ou para a esquerda, para selecionar o item seguinte ou anterior, entre os gestos de que
quem testa precisa.

Duas consequências decorrem disso, e as duas dão forma ao planner. **A ordem da lista é a ordem em que
a tela é ouvida**, então o total da semana deve vir antes das sessões que ele soma, como vem na tela.
E **cada elemento da lista custa um deslize**: uma linha de sessão ouvida como quatro pedaços
separados, curso, data, minutos, tique, leva quatro deslizes para passar, e uma semana de sete sessões
leva vinte e oito.

## O que ele lê de cada elemento

Para cada elemento em foco, o leitor de tela fala uma sequência curta, e cada parte vem de algo que
o app declarou:

| parte | o que diz | de onde vem |
|---|---|---|
| **rótulo** | o que o elemento é: "SQL, sexta 23 de outubro, 60 minutos" | o texto, ou um rótulo que o app define |
| **papel** | que tipo de coisa ele é: botão, caixa de seleção, título | o componente, ou um papel que o app define |
| **estado** | como ele está agora: marcada, não marcada, selecionado, desativado | o estado do componente, ou uma descrição que o app define |
| **dica** | o que acontece ao ativar, se isso não for óbvio | uma dica opcional, lida depois de uma pausa |

O Android chama a segunda parte de *role* e a terceira de *state description*; a Apple chama a
segunda de *trait* e põe o estado no *value* do elemento ou nos traits. O React Native tem uma
propriedade para cada uma: `accessibilityRole`, `accessibilityState`, `accessibilityHint`. As
palavras mudam e os quatro lugares são os mesmos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l19-announce\" aria-label=\"A sequência que um leitor de tela fala quando o foco chega à linha de marcar feito do planner. Um deslize leva o foco à linha. Depois quatro partes, em ordem: o rótulo, SQL, sexta 23 de outubro, 60 minutos, que vem do texto ou de um rótulo que o app define; o papel, caixa de seleção, do componente ou de um papel declarado; o estado, não marcada, do estado do componente; e uma dica, opcional e lida depois de uma pausa, de que esta linha não precisa. Um toque duplo então a alterna, e o estado é lido de novo como marcada.\"><defs><marker id=\"l19-announce-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">um deslize para a direita: o foco chega</text><path d=\"M30 34 L30 70 L40 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l19-announce-ah-paper-dim)\"></path><text x=\"120\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">rótulo</text><rect x=\"44\" y=\"62\" width=\"152\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SQL, sex 23 out,</text><text x=\"120.0\" y=\"95.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">60 minutos</text><text x=\"120\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">o texto, ou um rótulo</text><path d=\"M196 89 L212 89\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-announce-ah-paper-dim)\"></path><text x=\"288\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">papel</text><rect x=\"212\" y=\"62\" width=\"152\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"288.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">caixa de seleção</text><text x=\"288\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">o papel do componente</text><path d=\"M364 89 L380 89\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-announce-ah-paper-dim)\"></path><text x=\"456\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">estado</text><rect x=\"380\" y=\"62\" width=\"152\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"456.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">não marcada</text><text x=\"456\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">o estado do componente</text><path d=\"M532 89 L548 89\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-announce-ah-paper-dim)\"></path><text x=\"624\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">dica</text><rect x=\"548\" y=\"62\" width=\"152\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"624.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">(nenhuma precisa)</text><text x=\"624\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">opcional, após pausa</text><rect x=\"44\" y=\"168\" width=\"656\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"372.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um toque duplo: a linha alterna, e o estado é lido de novo: marcada</text><path d=\"M370 146 L370 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l19-announce-ah-paper-dim)\"></path></svg>", "caption": "O que um leitor de tela diz para uma linha, em ordem. É um diagrama da sequência, não uma gravação: as palavras exatas e as pausas mudam entre o TalkBack e o VoiceOver e com os ajustes do usuário."}
```

A figura mostra as partes na ordem em que vêm, para o botão de tique do planner numa sessão. É um
diagrama da sequência, não uma gravação: as palavras exatas e as pausas mudam entre o TalkBack e o
VoiceOver, entre versões e com os ajustes do usuário. A documentação do React Native observa, por
exemplo, que o VoiceOver lê a dica "se o usuário estiver com as dicas ativadas".

**O rótulo é o que carrega mais e o que mais dá errado.** Sem ele, o usuário ouve só o papel,
"botão", em cada tique da lista, e não tem como saber a que sessão cada um pertence. A documentação
do Android dá a regra pelo outro lado: descreva "o propósito e o resultado da interação, não os
detalhes visuais". Ela também pede que você não repita o papel no rótulo ("Enviar", não "Botão enviar") e que faça cada descrição
única, porque uma lista de sete botões chamados todos "marcar como feita" é uma lista de sete sons
idênticos.

**O estado é a parte que um designer que enxerga esquece**, porque quem enxerga o vê num relance. O
tique está cheio ou vazio. Um usuário de leitor de tela ouve "marcada" ou "não marcada", e só se o app
declarou o controle como algo que tem estado. Um botão que muda de cor quando apertado, sem nada
declarado, diz ao usuário de leitor de tela que nada aconteceu.

## Experimentando

Os dois leitores fazem parte do celular, em Ajustes, depois Acessibilidade. A documentação do
Android sugere ligar o TalkBack e deslizar por cada elemento do app, em ordem, ouvindo o que falta, o
que é vago ou o que é longo demais. Esse é o teste que encontra o que as verificações desta aula não
alcançam. No caminho do iPhone, o `ios-apps` dedica a aula 19 ao VoiceOver e ao Dynamic Type. Aqui,
a próxima seção escreve as declarações em si.
