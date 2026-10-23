---
title: OnPush, conferir só o que pede para ser conferido
version: 1
---

**`ChangeDetectionStrategy.OnPush` diz ao Angular para pular um componente durante a passada, a não ser
que o componente tenha sido marcado como precisando dela.** Com o zone.js, era o jeito de parar de
conferir tudo depois de tudo, e em aplicações grandes era a diferença entre uma página que acompanhava e
uma que engasgava. A linha do meio da seção anterior mostra a regra em ação: o timer pôs o `count` em 1,
o zone.js disparou uma passada, e o Angular pulou o `TickOnPush`, porque nada o tinha marcado.

O que marca um componente OnPush, para a próxima passada visitá-lo:

| o que aconteceu | exemplo |
|---|---|
| **um signal que o template dele lê mudou** | o `count.set(1)` do `TickSignal`, que é por que a linha dele dizia 1 |
| **um evento disparou no template dele** | um `(click)` num dos botões dele |
| **um input mudou para um valor novo** | aula 8: o pai passa um objeto novo, não o mesmo alterado |
| **alguém o marcou à mão** | `inject(ChangeDetectorRef).markForCheck()`, a saída de emergência de que o código antigo está cheio |

Um campo comum mudado por um timer não é nenhum desses, então o componente OnPush nunca ficou sabendo.
O conserto que o código antigo usava era a última linha: injetar o `ChangeDetectorRef` e chamar
`markForCheck()` depois de mudar o campo. O conserto de hoje é a primeira linha: ponha o valor num
signal, e o signal faz a marcação.

**O OnPush também é o motivo de a aula 6 ter insistido em valores novos.** Um input que recebe o mesmo
array, alterado no lugar, não mudou pela regra do OnPush, exatamente como um signal que o guarda não
mudou, e pelo mesmo motivo: a comparação é de identidade.

O OnPush não é padrão no Angular 21. O `ng generate component` escreve componentes sem ele, e eles são
conferidos em toda passada. A última seção desta aula muda isso no planner.
