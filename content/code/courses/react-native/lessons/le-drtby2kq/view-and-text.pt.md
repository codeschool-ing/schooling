---
title: View e Text
version: 1
---

**Dois componentes carregam quase toda tela: a `View` é uma caixa, e o `Text` é o único lugar onde texto
pode morar.** Todo o resto desta aula é um deles com uma função específica.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l04-tree\" aria-label=\"A primeira tela do planner como uma árvore de componentes, e no que cada um se transforma no Android e no iOS. ScrollView vira uma scroll view nativa; View vira um ViewGroup ou uma UIView; Image vira uma ImageView ou uma UIImageView; Text vira uma TextView ou um UILabel; Pressable vira uma view nativa que recebe toques.\"><defs><marker id=\"l04-tree-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">os seus componentes</text><text x=\"450\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">Android</text><text x=\"620\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">iOS</text><rect x=\"30\" y=\"36\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;ScrollView&gt;</text><path d=\"M200 51 L370 51\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-tree-ah-paper-dim)\"></path><rect x=\"370\" y=\"36\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ScrollView</text><rect x=\"550\" y=\"36\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UIScrollView</text><rect x=\"60\" y=\"78\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"145.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;View&gt;</text><path d=\"M230 93 L370 93\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-tree-ah-paper-dim)\"></path><rect x=\"370\" y=\"78\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ViewGroup</text><rect x=\"550\" y=\"78\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UIView</text><rect x=\"90\" y=\"120\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;Image&gt;</text><path d=\"M260 135 L370 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-tree-ah-paper-dim)\"></path><rect x=\"370\" y=\"120\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ImageView</text><rect x=\"550\" y=\"120\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UIImageView</text><rect x=\"90\" y=\"162\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;Text&gt;</text><path d=\"M260 177 L370 177\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-tree-ah-paper-dim)\"></path><rect x=\"370\" y=\"162\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">TextView</text><rect x=\"550\" y=\"162\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UILabel</text><rect x=\"90\" y=\"204\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;Pressable&gt;</text><path d=\"M260 219 L370 219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-tree-ah-paper-dim)\"></path><rect x=\"370\" y=\"204\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ViewGroup + touch</text><rect x=\"550\" y=\"204\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UIView + touch</text></svg>", "caption": "Cada componente da sua árvore é uma view nativa em cada plataforma, criada pelo Fabric na thread principal."}
```

## A View, a caixa

Uma `View` é um retângulo que contém outras coisas, as posiciona e pode receber estilo: um fundo, uma
borda, padding, um tamanho. Ela vira um `android.view.ViewGroup` no Android e uma `UIView` no iOS. Não
tem significado próprio, e por isso um leitor de tela passa por ela a não ser que você lhe dê um; a prop
`role` faz isso, e a última seção desta aula dá à lista de cursos `role="list"`.

**Uma View posiciona os filhos em coluna por padrão**, de cima para baixo, o contrário de um `<div>` com
`display: flex` na web. A aula 5 é sobre o porquê, e sobre todo o resto que o Flexbox faz aqui.

## O Text, a única casa de uma string

Um `Text` mostra uma string, e é o único componente que consegue. Ele vira uma `TextView` no Android e um
`UILabel` no iOS, e faz coisas que uma `View` não faz: quebra linhas, pode ser selecionado, e se mede pelo
conteúdo.

Elementos `Text` se aninham, e **o aninhamento é o único lugar onde o estilo é herdado no React Native**.
Um `Text` interno pega a fonte e a cor do pai e acrescenta as próprias mudanças, que é como uma palavra em
negrito fica no meio de uma frase:

```tsx
<Text style={{ fontSize: 16 }}>
  This week: <Text style={{ fontWeight: "700" }}>75</Text> of 125 minutes
</Text>
```

O `Text` interno não é uma caixa separada. A frase inteira é uma única view de texto nativa com um trecho
em negrito, então ela quebra como um parágrafo só e um leitor de tela a lê como uma só.

Uma `View` dentro de um `Text` é permitida, e raramente vale a pena; um `Text` dentro de uma `View` é o
caso comum. O que **nunca** é permitido é o assunto da próxima seção.

## Acessível por padrão, quase

Um `Text` é lido em voz alta por um leitor de tela do jeito que está. Uma `View` que guarda vários `Text`
é lida como vários itens separados, e quem usa VoiceOver e TalkBack passa por eles um de cada vez. Quando
um grupo de textos é uma coisa só, um cartão com um título e uma contagem, o `accessible` na `View` faz o
leitor de tela tratá-lo como um elemento único e ler todo o texto junto. O `Pressable` da penúltima seção
faz isso sozinho, o que é parte do motivo de ele ser o elemento certo para uma linha que se aperta.
