---
title: "A nova arquitetura: JSI, Fabric e TurboModules"
version: 1
---

**A nova arquitetura troca mensagens por referências.** Em vez de descrever o que quer em JSON e
esperar, o JavaScript guarda um identificador para um objeto C++ e chama um método dele, do jeito que
chama um método de qualquer objeto JavaScript. O React Native 0.76 a tornou o padrão em 2024, e a
0.82 a tornou a única arquitetura que existe: um projeto na versão que este curso usa, a 0.88, não
consegue desligá-la.

Ela tem quatro partes, e cada uma desfaz um dos custos da seção anterior.

## JSI: a JavaScript Interface

A **JSI** é uma API em C++ pela qual um motor como o Hermes expõe valores JavaScript ao C++, e objetos
C++ ao JavaScript. Um objeto nativo registrado por ela aparece no JavaScript como um objeto com
métodos; chamar um deles roda a função C++ diretamente, na thread de JavaScript, e devolve o
resultado. Sem fila, sem JSON, sem callback quadros depois.

Duas consequências importam na prática. Uma chamada **agora pode ser síncrona**: um módulo nativo pode
responder `getString()` com uma string, ali mesmo. E os dados **não precisam ser copiados** em forma de
texto: um buffer grande pode ser entregue como ele mesmo. Nenhuma das duas torna toda chamada de
graça — uma chamada síncrona que faz trabalho lento bloqueia a thread de JavaScript exatamente por
esse tempo — mas o custo de atravessar desapareceu.

## Fabric: o renderizador

O **Fabric** é a parte que transforma os elementos do React em views nativas, reescrita sobre a JSI. A
árvore do que deve estar na tela vive em C++, compartilhada pelos dois lados, então o lado JavaScript
pode pedir o tamanho de uma view e recebê-lo na mesma chamada. É isso que permite a um componente se
medir e se posicionar sem um quadro piscando no meio.

Ele também deixa o React Native usar os recursos concorrentes do React. Uma renderização pode ser
interrompida quando chega algo mais urgente, um toque por exemplo, e retomada depois. A aula 9
apresenta o `useTransition`, que depende disso.

## TurboModules: módulos nativos, carregados quando usados

Um módulo nativo é código escrito em Kotlin, Java, Swift, Objective-C ou C++ que o JavaScript chama:
a câmera, o sistema de arquivos, o cofre seguro. **TurboModules** são módulos nativos alcançados pela
JSI, e são criados na primeira vez que o JavaScript pede um deles, e não quando o app abre. Um app
com quarenta bibliotecas instaladas paga na abertura pelas que a primeira tela usa.

## Codegen: o contrato, conferido

A JSI é C++, e um módulo nativo é escrito em Kotlin ou Swift, então alguém precisa escrever a cola
entre os dois. O **Codegen** escreve: você descreve o módulo uma vez, como uma interface TypeScript
tipada, e na hora do build ele gera o C++ e as interfaces nativas a partir dessa descrição. Uma função
Kotlin cujos tipos de parâmetro não batem com a spec TypeScript deixa de compilar, o que transforma
uma classe de falhas que apareciam no aparelho em erros no build. A aula 17 escreve uma spec e vê o
Codegen rodar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l01-jsi\" aria-label=\"A nova arquitetura. O JavaScript guarda referências a objetos C++ pela JSI e os chama diretamente, na mesma chamada. O Fabric mantém a árvore de views em C++ e monta as views nativas na thread principal. Os TurboModules são módulos nativos criados na primeira vez que são chamados. O Codegen escreve a cola em C++ na hora do build, a partir de uma spec em TypeScript tipada.\"><defs><marker id=\"l01-jsi-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">JavaScript, no Hermes</text><rect x=\"40\" y=\"60\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">module.getString()</text><text x=\"120\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">chamada direta, mesma thread</text><rect x=\"250\" y=\"55\" width=\"50\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"275\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">JSI</text><path d=\"M200 77 L250 77\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-jsi-ah-paper-dim)\" marker-start=\"url(#l01-jsi-ah-paper-dim)\"></path><rect x=\"330\" y=\"30\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415.0\" y=\"46.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">TurboModule:</text><text x=\"415.0\" y=\"59.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">criado no primeiro uso</text><rect x=\"330\" y=\"96\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415.0\" y=\"112.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Fabric: a árvore</text><text x=\"415.0\" y=\"125.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">de views, em C++</text><path d=\"M300 70 L330 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-jsi-ah-paper-dim)\"></path><path d=\"M300 85 L330 119\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-jsi-ah-paper-dim)\"></path><rect x=\"530\" y=\"30\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Kotlin ou Swift</text><rect x=\"530\" y=\"96\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"112.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">views nativas, na</text><text x=\"615.0\" y=\"125.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">thread principal</text><path d=\"M500 53 L530 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-jsi-ah-paper-dim)\"></path><path d=\"M500 119 L530 119\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-jsi-ah-paper-dim)\"></path><rect x=\"250\" y=\"186\" width=\"250\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"375.0\" y=\"202.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Codegen: cola em C++</text><text x=\"375.0\" y=\"215.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a partir de uma spec</text><text x=\"375\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">escrita na hora do build</text><path d=\"M375 186 L375 145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-jsi-ah-paper-dim)\"></path></svg>", "caption": "Desde a 0.76 por padrão, e desde a 0.82 sempre: referências em vez de mensagens.", "same": ["JSI", "TurboModule:"]}
```

## O que não mudou

**Os seus componentes são escritos do mesmo jeito.** `View`, `Text`, `useState` e o resto têm
exatamente a mesma cara; a arquitetura mudou por baixo deles. O que mudou para o código do app foi
principalmente o que *deixou* de acontecer: uma lista que se mede não pisca, uma biblioteca não
deixa a abertura mais lenta só por estar instalada, e o conselho "mantenha pequeno o tráfego na
ponte" não nomeia mais nada. **A thread de JavaScript continua sendo uma thread só**, e mantê-la livre
continua sendo o assunto inteiro das aulas 12 e 19.
