---
title: Quando os módulos compensam, e por que quase todo código não tem nenhum
version: 1
---

Os módulos chegaram no Java 9, em 2017, depois de boa parte de uma década de projeto. **A maioria das
aplicações Java escritas desde então não tem `module-info.java`**, e isso inclui quase todo serviço
construído com os frameworks que o `java-back` usa. Vale saber por quê, porque os motivos são de custo,
e não de o sistema de módulos estar errado.

## O que um módulo custa

- **Toda dependência precisa ser um módulo também**, ou passar por um. Um jar de biblioteca sem
  `module-info.class` pode ir para o module path como *módulo automático*, com o nome do jar, mas uma
  aplicação é tão modular quanto o jar menos modular que ela puxa, e um serviço de verdade puxa dezenas.
- **Frameworks fazem reflexão.** Eles leem os campos privados e as anotações das suas classes, como o
  validador da lição 39 fez, então todo pacote em que eles mexem precisa ser `opens`, e a declaração se
  enche de exceções à regra que ela existe para impor.
- **Dois caminhos para não confundir.** O class path e o module path se comportam de jeitos
  diferentes, como a seção 03 mostrou com os mesmos dois diretórios, e um build que mistura os dois é
  uma fonte de erros que um build de class path nunca tem.

## O que um módulo compra

- **As entranhas de uma biblioteca ficam internas.** O `Index` da seção 02 não vira, por acidente,
  dependência de outra pessoa. Para uma biblioteca com muitos usuários, esse é o principal motivo para
  escrever o arquivo: o próprio JDK é o maior exemplo.
- **Peças faltando falham na inicialização.** Um módulo que faz `requires` de outro que não está lá se
  recusa a iniciar, em vez de falhar com um `NoClassDefFoundError` uma hora depois de começar, na
  primeira vez que uma classe pouco usada é tocada.
- **O `jlink`.** Um runtime de 60 MB em vez de 331, da seção 04, quando o programa e as dependências
  dele são módulos.

## Então, na prática

**Escreva uma aplicação no class path**, como fez cada outra lição deste curso, e como faz o projeto
Maven da lição 18. Recorra ao `module-info.java` quando publicar uma biblioteca de que outros dependem e
você quiser as entranhas dela protegidas, ou quando um runtime pequeno e autossuficiente valer o
esforço de tornar cada peça modular.

Escreva o que escrever, você já vive dentro dos módulos do JDK. A `InaccessibleObjectException` da
seção 03 é o sistema de módulos falando com um programa que nunca declarou um módulo, e ler essa
mensagem direito é a parte desta lição de que todo desenvolvedor Java precisa, construa o que construir.
