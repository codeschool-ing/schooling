---
title: Girar o celular constrói uma activity nova
version: 1
---

**Quando a configuração muda, o sistema destrói a activity e cria outra.** A configuração é tudo o
que, no aparelho, um recurso pode levar em conta: orientação, tamanho de tela, idioma, modo escuro,
tamanho da fonte. A seção 07 da aula 1 mostrou pastas como `values-pt` e `values-night` escolhidas
por ela. O jeito mais simples de garantir que todo recurso seja escolhido de novo é começar a tela de
novo, e é isso que o Android faz por padrão.

O segundo teste da seção 03 gira o celular, que é o que `scenario.recreate()` faz:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --rerun --tests "*LifecycleTest.rotation" 2>&1 | grep -E "STANDARD_OUT|Lifecycle:|  --|^BUILD"
LifecycleTest > rotation STANDARD_OUT
    D/Lifecycle: onCreate: instance 1 in this process, saved state: false
    D/Lifecycle: onStart
    D/Lifecycle: onResume
    -- the user turns the phone
    D/Lifecycle: onPause
    D/Lifecycle: onStop
    D/Lifecycle: onSaveInstanceState
    D/Lifecycle: onDestroy: finishing false, configuration change true
    D/Lifecycle: onCreate: instance 2 in this process, saved state: true
    D/Lifecycle: onStart
    D/Lifecycle: onResume
BUILD SUCCESSFUL in 18s
```

Leia como duas vidas. A primeira instância desce por `onPause` e `onStop`, salva o estado e é
destruída com `configuration change true`, que é o sistema avisando que vai criar outra logo em
seguida. Então **um objeto diferente** começa: `instance 2 in this process`, e desta vez
`saved state: true`. O `Bundle` que o `onSaveInstanceState` preencheu é entregue ao novo `onCreate`.

## O que atravessa, e o que não atravessa

Três tipos de valor, três destinos diferentes, naquela única rotação:

- **Um campo da activity se perde.** Ele pertencia ao objeto que foi destruído. Uma lista de
  sessões guardada em `private val sessions = mutableListOf<StudySession>()` volta vazia depois do
  giro.
- **O que foi para o `Bundle` volta.** Foi escrito pela instância velha e lido pela nova. O
  framework salva algumas coisas ali por você, o texto de um campo de texto nativo entre elas, e o
  `rememberSaveable` da aula 4 põe ali o estado do Compose.
- **O que mora fora da activity fica intacto.** `ProcessWide.created` foi de 1 para 2 porque o
  objeto que o guarda é o mesmo: a rotação troca a activity e mantém o processo. O `ViewModel` da
  aula 10 é construído sobre esse fato.

Antes do Compose e do `ViewModel`, o primeiro item era o bug mais comum do Android: preencher um
formulário, girar o celular, e o formulário está vazio. A cura era código em toda activity para pôr
cada campo no `Bundle` e tirá-lo de volta, e a aula 4 mostra quanto disso hoje é uma palavra.

## Recusar a troca, e por que não fazer isso

Uma activity pode declarar no manifesto que ela mesma cuida de uma mudança:
`android:configChanges="orientation|screenSize"`. O sistema então chama `onConfigurationChanged` na
instância que já existe em vez de reconstruí-la. Parece a cura e é uma armadilha: **só as mudanças
listadas são tratadas**, então a mesma activity continua sendo reconstruída quando o idioma ou o
modo escuro mudam, e qualquer recurso que dependia da orientação agora é trabalho seu recarregar. A
documentação do Google recomenda isso só para activities que realmente não podem ser
reconstruídas, e um player de vídeo é o exemplo de sempre. Este curso não usa, e a aula 4 torna isso
desnecessário.
