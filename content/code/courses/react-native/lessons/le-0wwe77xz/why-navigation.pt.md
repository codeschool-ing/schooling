---
title: A navegação é uma biblioteca, e por quê
version: 1
---

**O React Native não traz navegação embutida.** Na web, o navegador guarda um histórico e a barra de
endereço diz onde você está; um app de celular não tem nenhum dos dois, então passar de uma tela para outra,
lembrar o caminho de volta e animar a troca são trabalho do próprio app. A biblioteca que quase todo app
React Native usa para isso é o **React Navigation**, e o roteador baseado em arquivos do próprio Expo, o Expo
Router, é construído sobre ela.

## As três formas

| navegador | o que a pessoa vê | no planner |
|---|---|---|
| **pilha** | telas deslizam por cima umas das outras; voltar tira a de cima | a tela de um curso, sobre a lista |
| **abas** | uma barra de abas, cada uma uma tela que mantém o seu lugar | *Courses* e *This week* |
| **gaveta** | um painel que desliza de lado | não é necessária |

Navegadores se **aninham**. A raiz do planner é uma pilha cuja primeira tela são as abas; a tela de um curso
fica na pilha, acima das abas, então cobre a barra de abas enquanto está aberta e voltar leva à aba em que a
pessoa estava.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l08-nesting\" aria-label=\"Os navegadores do planner. A raiz é uma pilha nativa. A primeira tela dela é Tabs, um navegador de abas inferiores com Courses e This week. Acima das abas, a pilha pode empilhar Course, com um id. Empilhar Course cobre a barra de abas; voltar devolve à aba em que a pessoa estava.\"><defs><marker id=\"l08-nesting-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-nesting-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">raiz: pilha nativa</text><rect x=\"20\" y=\"34\" width=\"380\" height=\"170\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">Tabs: abas inferiores</text><rect x=\"40\" y=\"70\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Courses</text><rect x=\"40\" y=\"130\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">This week</text><rect x=\"230\" y=\"100\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"305.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Course { id }</text><path d=\"M190 90 L230 112\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-nesting-ah-amber)\"></path><text x=\"214\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">empilha</text><path d=\"M230 128 L190 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l08-nesting-ah-paper-dim)\"></path><text x=\"212\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">volta</text></svg>", "caption": "Navegadores se aninham: a tela de um curso fica na pilha acima das abas, então voltar devolve à aba que estava aberta.", "same": ["Courses", "This week"]}
```

## Instalando

Aqui o React Navigation são quatro pacotes: o núcleo, os dois navegadores, e o `react-native-screens`, que
transforma cada tela numa tela nativa de verdade, um `UIViewController` no iOS e um `Fragment` no Android. A
biblioteca de áreas seguras da aula 6 é o quinto, já instalado:

```
ana@dev:~/planner$ npm install -E @react-navigation/native@7.5.1 @react-navigation/native-stack@7.21.0 @react-navigation/bottom-tabs@7.21.0 react-native-screens@4.30.1

added 21 packages, and audited 1090 packages in 9s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

O `native-stack` usa os controladores de navegação das próprias plataformas, então a animação de empilhar, o
deslizar para voltar no iOS e o cabeçalho são os do sistema. Existe também uma pilha em JavaScript, a
`@react-navigation/stack`, mais fácil de personalizar; a nativa é a escolha padrão porque se comporta
exatamente como um app nativo.

## O Expo Router, num parágrafo

O Expo Router monta os mesmos navegadores a partir dos **arquivos** de uma pasta `app/`: `app/course/[id].tsx`
é ao mesmo tempo a tela do curso e o endereço dela. É uma boa escolha para um app novo e é React Navigation
por baixo, então tudo nesta aula vale para ele. Este curso escreve os navegadores à mão porque é isso que o
Expo Router escreve por você, e vê-lo uma vez torna legível a versão gerada.
