---
title: O que roda onde, dentro de um app
version: 1
---

**Um app React Native é um app nativo.** O que o celular instala é um pacote Android ou um bundle iOS,
construído pelo Gradle ou pelo Xcode como qualquer outro, com um ponto de entrada nativo e views
nativas na tela. O que o torna React Native é uma coisa que esse app carrega dentro dele: um motor de
JavaScript, e um arquivo com o seu JavaScript para esse motor rodar.

A imagem mais comum está de cabeça para baixo. Muita gente chega acreditando que o JavaScript é
*compilado para* Kotlin ou Swift, ou que o app é uma página web num navegador escondido. Nenhuma das
duas é verdade. O seu código continua sendo JavaScript até o fim e roda num motor chamado **Hermes**,
que vai dentro do app. Nada desenha HTML: um `<Text>` no seu componente vira uma `TextView` no
Android e um `UILabel` no iOS, os mesmos objetos que um desenvolvedor Kotlin ou Swift teria criado.

## Três lugares onde o trabalho acontece

O celular dá ao app uma única thread que pode mexer na tela, a **thread principal** (o Android a chama
de thread de UI). Toda view é criada, alterada e desenhada ali, e todo toque chega ali primeiro.
Bloqueie essa thread por um terço de segundo e o app para de responder, o que os dois sistemas
punem: o Android mostra um diálogo *Application Not Responding* depois de cinco segundos assim.

O React Native acrescenta uma segunda thread, a **thread de JavaScript**, onde o Hermes roda o seu
código. É nela que o React calcula como a tela deve ficar: chama os seus componentes, compara o
resultado com o anterior e decide o que mudou. Um laço demorado no seu código bloqueia essa thread e
não a principal, então o app continua rolando, mas nada do que você escreveu consegue responder a um
toque até o laço terminar.

Entre as duas fica o trabalho de transformar a resposta do React em views:

| etapa | o que acontece | onde |
|---|---|---|
| render | os seus componentes rodam e devolvem elementos | thread de JavaScript |
| layout | o Yoga, uma biblioteca em C++, transforma regras de flexbox em tamanhos e posições | onde o render rodou |
| montagem | as views nativas são criadas ou atualizadas para bater com o resultado | thread principal |

O **Yoga** é o motivo de a aula 5 poder falar de flexbox num app sem CSS: é um motor de layout escrito
em C++ que entende flexbox e mais nada, e as duas plataformas usam a mesma cópia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 215\" role=\"img\" data-fig=\"l01-threads\" aria-label=\"Três lugares onde o trabalho acontece num app React Native. Na thread de JavaScript, o Hermes roda os seus componentes e o React, que renderiza os elementos. O Yoga, em C++, calcula o layout. Na thread principal, as views nativas são montadas e desenhadas, e os toques chegam; um toque viaja até a thread de JavaScript como evento, e a resposta volta como views.\"><defs><marker id=\"l01-threads-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">thread de JavaScript</text><text x=\"360\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">C++, compartilhado</text><text x=\"600\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">thread principal</text><rect x=\"40\" y=\"60\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"78.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o Hermes roda os seus</text><text x=\"120.0\" y=\"91.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">componentes e o React</text><text x=\"120\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">1 · render</text><rect x=\"280\" y=\"60\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"78.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Yoga: flexbox em</text><text x=\"360.0\" y=\"91.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tamanhos e posições</text><text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">2 · layout</text><rect x=\"520\" y=\"60\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"78.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">views nativas:</text><text x=\"600.0\" y=\"91.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">TextView, UILabel</text><text x=\"600\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">3 · montagem</text><path d=\"M200 85 L280 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-threads-ah-paper-dim)\"></path><path d=\"M440 85 L520 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-threads-ah-paper-dim)\"></path><text x=\"600\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">um toque chega aqui</text><path d=\"M560 182 L560 196 L120 196 L120 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-threads-ah-paper-dim)\"></path><text x=\"340\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">evento</text></svg>", "caption": "O seu código roda na thread de JavaScript. Só a thread principal pode mexer numa view, então o resultado é entregue a ela.", "same": ["1 · render", "2 · layout", "TextView, UILabel"]}
```

## Por que a divisão importa para você

Boa parte dos conselhos de desempenho deste curso vem desta imagem. Um componente lento atrasa a
thread de JavaScript, então um toque é respondido com atraso; uma lista que cria milhares de views
atrasa a thread principal, então a rolagem engasga. A aula 12 tira as animações da thread de
JavaScript por inteiro, para que um componente ocupado não as faça engasgar, e a aula 19 mede em
qual thread uma lentidão mora antes de corrigir qualquer coisa.

Ela também explica uma regra que aparece na documentação de toda biblioteca: **qualquer coisa que mexa
numa view precisa acontecer na thread principal**, então um módulo nativo que desenha precisa entregar
o trabalho a ela. A aula 17 escreve um.
