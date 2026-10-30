---
title: Três passos: o pai propõe, o filho escolhe, o pai posiciona
version: 1
---

**No SwiftUI um pai nunca define o tamanho de um filho. Ele oferece um, e o filho decide.** Esse é o
sistema de layout inteiro numa frase, e a documentação da Apple para o `ProposedViewSize` a diz quase
com essas palavras: durante o layout, as views escolhem o próprio tamanho, mas o fazem em resposta a
uma proposta de tamanho do pai. Três passos acontecem para cada view na tela:

1. **o pai propõe um tamanho** ao filho: tanto de largura, tanto de altura, ou "o que você quiser";
2. **o filho escolhe o seu tamanho**, levando a proposta em conta ou não, e o informa de volta;
3. **o pai posiciona o filho** em algum ponto das suas próprias coordenadas, e o tamanho escolhido
   pelo filho é respeitado: o pai não pode mudá-lo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l04-steps\" aria-label=\"Três passos entre um pai e um filho. Passo 1, o pai propõe um tamanho: 360 de largura. Passo 2, o filho escolhe o seu tamanho, 104 de largura, e o informa. Passo 3, o pai posiciona o filho num ponto do seu próprio espaço. A largura escolhida pelo filho é mantida; o pai decide só onde ele fica.\"><defs><marker id=\"l04-steps-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l04-steps-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l04-steps-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l04-steps-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">pai</text><text x=\"120\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">HStack</text><rect x=\"510\" y=\"30\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">filho</text><text x=\"600\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Text</text><path d=\"M212 44 L506 44\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-steps-ah-phosphor)\"></path><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">1  propõe: 360 de largura</text><path d=\"M506 70 L214 70\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-steps-ah-amber)\"></path><text x=\"360\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">2  escolhe e informa: 104 de largura</text><rect x=\"30\" y=\"130\" width=\"660\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">3  o pai posiciona o filho; a largura continua 104</text><rect x=\"50\" y=\"162\" width=\"104\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"102\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SQL Databases</text><text x=\"420\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o resto dos 360 é do pai para repartir</text></svg>", "caption": "O pai oferece, o filho decide, e o pai só escolhe onde o filho fica."}
```

A crença a largar vem de sistemas de layout em que um contêiner estica os filhos para preenchê-lo.
Aqui um `Text` a quem se oferece a largura inteira da tela fica com a largura das suas palavras e nada
mais, e o contêiner o centraliza no espaço por padrão. **Preencher espaço é algo que uma view escolhe
fazer**, e só algumas fazem: uma `Color`, um `Spacer`, uma forma, um `GeometryReader`. A documentação
da Apple para `frame(width:height:alignment:)` dá o exemplo: uma forma sempre ocupa o espaço oferecido
a ela, e é por isso que uma `Ellipse` sem frame preenche o que o pai oferecer.

## Por que isso importa para o planner

A linha da lista de cursos é `HStack { Text(course.title); Spacer(); Text("\(minutes) min") }`. Lida
com os três passos em mente:

- a linha recebe da lista a largura da tela;
- a stack oferece partes dela aos dois textos, e cada um fica com a largura das suas palavras;
- o spacer fica com o que sobra, o que empurra os minutos para a borda direita.

Nada nessa linha diz "alinhe os minutos à direita". **O alinhamento sai de quem escolhe o quê.** A
seção 08 roda essa aritmética em Swift puro e imprime os números. O resto desta aula pega as peças uma
de cada vez: stacks, frames, alinhamento, spacers e padding, e o `GeometryReader`, a view que lê a
própria proposta.

Nada nesta seção foi executado para o curso; ela foi escrita a partir da documentação da Apple para
`ProposedViewSize`, `Layout` e `frame(width:height:alignment:)`, lida em 30 de outubro de 2026.
