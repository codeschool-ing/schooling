---
title: A ponte, e o que ela custava
version: 1
---

**Durante quase toda a sua primeira década, as duas metades do React Native conversaram trocando
mensagens.** Esse canal se chamava **ponte** (*bridge*), e a maior parte dos artigos, respostas e
cursos sobre React Native escritos antes de 2024 descreve um app construído em volta dela. Você vai
lê-los, então vale saber o que querem dizer e por que a ponte não existe mais.

## Mensagens, em lotes, em JSON

O lado JavaScript e o lado nativo nunca compartilhavam um único objeto. Quando o seu código queria
criar uma view, ele não chamava nada nativo: acrescentava uma mensagem a uma fila, algo como *crie a
view 42 do tipo `RCTText` com estas propriedades*. A fila era serializada em JSON, entregue do outro
lado, interpretada e executada. As respostas voltavam do mesmo jeito, depois.

Três propriedades saíram desse desenho, e cada uma moldou o jeito de escrever apps React Native:

- **Tudo era assíncrono.** O JavaScript nunca podia fazer uma pergunta ao código nativo e esperar a
  resposta na mesma função. Medir uma view significava enviar um pedido e receber o tamanho num
  callback alguns quadros depois.
- **Tudo era copiado.** Um array grande enviado ao código nativo virava texto, era enviado e virava
  array de novo. Uma lista de mil itens atravessava a ponte como o texto de mil itens.
- **Todo módulo nativo nascia na abertura do app.** A ponte precisava de uma tabela com todos os
  módulos que o app talvez chamasse, então todos eram criados quando o app abria, inclusive o módulo
  de câmera de um app cuja tela de câmera ninguém ia abrir naquele dia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l01-bridge\" aria-label=\"A arquitetura antiga. O lado JavaScript põe mensagens numa fila, como criar a view 42 ou definir o texto dela. A fila é serializada em JSON e atravessa a ponte em lote. O lado nativo a interpreta e age. As respostas voltam do mesmo jeito, depois, então toda chamada é assíncrona e todo valor é copiado.\"><defs><marker id=\"l01-bridge-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">lado JavaScript</text><text x=\"130\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">uma fila de mensagens</text><rect x=\"40\" y=\"76\" width=\"180\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">{\"op\":\"create\",\"tag\":42}</text><rect x=\"40\" y=\"108\" width=\"180\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">{\"op\":\"set\",\"text\":\"Hi\"}</text><rect x=\"40\" y=\"140\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">…</text><rect x=\"270\" y=\"70\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">a ponte</text><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">JSON, em lotes</text><path d=\"M220 100 L270 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-bridge-ah-paper-dim)\"></path><path d=\"M450 100 L500 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-bridge-ah-paper-dim)\"></path><text x=\"590\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">lado nativo</text><rect x=\"510\" y=\"76\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"94.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">interpreta e</text><text x=\"595.0\" y=\"107.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cria as views</text><path d=\"M590 170 L590 196 L130 196 L130 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-bridge-ah-paper-dim)\"></path><text x=\"360\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">as respostas voltam do mesmo jeito, quadros depois</text></svg>", "caption": "Antes de 2024: nada era compartilhado, tudo era mensagem, e toda resposta era um callback."}
```

## Onde doía

Os custos apareciam como sintomas específicos, que todo desenvolvedor React Native daquela época
aprendeu a reconhecer. Um gesto que seguia o dedo pelo JavaScript ficava para trás, porque cada
movimento fazia uma viagem de ida e volta pela fila. Uma tela que se media e depois se posicionava
piscava entre os dois estados por um quadro. O tempo de abertura crescia com o número de bibliotecas
instaladas, usadas ou não. E uma animação conduzida pelo JavaScript engasgava sempre que a thread de
JavaScript estava ocupada, porque os quadros também eram mensagens.

Cada um desses ganhou o seu contorno. `useNativeDriver: true` mandava a descrição inteira de uma
animação de uma vez, para o código nativo rodá-la sem mais mensagens; a aula 12 ainda o usa. As
bibliotecas passaram os caminhos mais quentes para código nativo. Nada disso tirava a ponte em si, e
a próxima seção é sobre isso.

## Por que ainda vale conhecê-la

Dois motivos. **Código antigo ainda fala dela**: o README de uma biblioteca que menciona a ponte, uma
resposta no Stack Overflow sobre `NativeModules`, um post sobre "tráfego na ponte" — todos descrevem
um desenho que o seu app não tem mais, e o conselho neles talvez já não se aplique. E **os hábitos
sobreviveram a ela**: manter pequenos os dados que passam de um lado para o outro, e manter fora da
thread de JavaScript o trabalho que precisa ser suave, continuam sendo bons conselhos, por motivos que
a próxima seção muda mas não elimina.
