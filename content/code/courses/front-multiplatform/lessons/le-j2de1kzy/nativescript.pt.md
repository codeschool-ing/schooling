---
title: NativeScript, as interfaces da plataforma a partir do JavaScript
version: 1
---

**O NativeScript roda o seu JavaScript, como o React Native, e desenha com as views da própria
plataforma, como o React Native.** Onde ele difere é em quanto deixa o JavaScript alcançar. Toda classe das
interfaces do próprio Android e do iOS está disponível a partir do JavaScript pelo nome nativo, então uma
linha de TypeScript consegue criar uma `TextView` do Android ou chamar um framework do iOS diretamente, sem
um plugin escrito em Kotlin ou Swift no meio.

As telas são descritas num XML próprio do NativeScript, ou escritas com Angular, Vue, Svelte, React ou
Solid por adaptadores para cada um, o que faz dele a única ferramenta aqui que não pede que você troque de
framework. As regras do planner atravessariam como atravessaram para o React Native, como TypeScript sem
DOM.

*O NativeScript não foi instalado para este curso. A ferramenta de linha de comando dele constrói para
Android com o SDK do Android e para iOS com o Xcode, e a máquina de gravação não tinha nenhum dos dois, e,
ao contrário do Expo, ele não tem um alvo web para olhar no lugar. O que esta seção diz vem da documentação
do NativeScript.*

## Onde ele se encaixa

**Ele é a ferramenta certa quando o núcleo do app são recursos da plataforma**, e uma equipe quer
alcançá-los sem escrever código nativo, ou quando a equipe já vive num dos frameworks que ele suporta. A
comunidade dele é bem menor que a do React Native ou a do Flutter, o que importa para as bibliotecas que
você encontra e as respostas que você consegue pesquisar, e esse é o motivo honesto de ele ser o menos
usado dos três.

## E as próprias linguagens nativas

Kotlin para Android e Swift para iOS continuam sendo a referência com que toda ferramenta aqui é medida: a
linguagem da própria plataforma, os kits de interface dela, Jetpack Compose e SwiftUI, e tudo o que é novo
no dia em que sai. O **Kotlin Multiplatform** compartilha código Kotlin, e com o Compose Multiplatform também
as telas, entre Android e iOS. Nenhum deles reaproveita nada de uma aplicação web, e é por isso que este
curso, feito para quem vem da web, termina o passeio aqui.
