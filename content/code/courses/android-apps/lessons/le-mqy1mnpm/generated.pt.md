---
title: O que o Hilt gera, e o erro de que ele te livra
version: 1
---

**O Hilt não é mágica nem reflexão: é código-fonte escrito durante o build.** O KSP roda o compilador
do Hilt sobre as anotações, e o resultado fica no diretório de build como Java comum, compilado para
dentro do app junto com todo o resto. Contá-lo é o jeito mais rápido de ver quanta fiação as anotações
substituíram: 22 arquivos, para as anotações de seis classes suas.

```
ana@vm:~/planner$ find app/build/generated/ksp/debug app/build/generated/hilt -name "*.java" | wc -l
22
ana@vm:~/planner$ find app/build/generated/ksp/debug app/build/generated/hilt -name "*.java" | sed "s|.*/||" | sort | grep -E "^(Hilt_|DaggerPlannerApp|PlannerApp_Hilt|WeekViewModel_(Factory|HiltModules)\.)"
DaggerPlannerApp_HiltComponents_SingletonC.java
Hilt_MainActivity.java
Hilt_PlannerApp.java
PlannerApp_HiltComponents.java
WeekViewModel_Factory.java
WeekViewModel_HiltModules.java
```

Três nomes dessa lista dizem o que o Hilt fez com elas. `Hilt_MainActivity` é uma classe base que
injeta a activity, e o build faz a `MainActivity` estendê-la sem alarde, e é por isso que o
`@AndroidEntryPoint` não precisa de mais nada de você; `Hilt_PlannerApp` faz o mesmo pela aplicação.
`WeekViewModel_HiltModules` registra o ViewModel para que o `hiltViewModel()` o encontre pela classe. E
`DaggerPlannerApp_HiltComponents_SingletonC` é o próprio componente singleton: a classe que guarda o
único `InMemorySessionStore` e sabe chamar `ClockModule.clock()` quando um `Clock` é pedido.

## Uma ligação que falta

A propriedade que vale a pena é esta: **um grafo que não pode ser completado não compila**. Para ver,
tire o `StoreModule` do projeto, para que nada diga qual `SessionStore` construir, e compile:

```
ana@vm:~/planner$ mv app/src/main/java/com/example/planner/di/StoreModule.kt /tmp/
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E -A8 "MissingBinding" | head -9
/home/ana/planner/app/build/generated/hilt/component_sources/debug/com/example/planner/PlannerApp_HiltComponents.java:138: error: [Dagger/MissingBinding] com.example.planner.data.SessionStore cannot be provided without an @Provides-annotated method.
  public abstract static class SingletonC implements PlannerApp_GeneratedInjector,
                         ^
  
      com.example.planner.data.SessionStore is injected at
          [com.example.planner.PlannerApp_HiltComponents.ViewModelC] com.example.planner.ui.WeekViewModel(store, …)
      com.example.planner.ui.WeekViewModel is injected at
          [com.example.planner.PlannerApp_HiltComponents.ViewModelC] com.example.planner.ui.WeekViewModel_HiltModules.BindsModule.binds(arg0)
      @dagger.hilt.android.internal.lifecycle.HiltViewModelMap java.util.Map<java.lang.Class<?>,javax.inject.Provider<androidx.lifecycle.ViewModel>> is requested at
ana@vm:~/planner$ mv /tmp/StoreModule.kt app/src/main/java/com/example/planner/di/
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 13s
```

A mensagem nomeia o tipo que ninguém fornece, `SessionStore`, e o caminho que precisava dele: o
construtor do `WeekViewModel`, alcançado a partir do mapa de ViewModels que o `hiltViewModel()` lê.
**Sem Hilt, o mesmo erro compila**, e a tela quebra na primeira vez que abre, no celular de quem abrir
primeiro. Devolver o módulo faz o build passar de novo, como mostram as duas últimas linhas.

Dois outros erros produzem mensagens do mesmo tipo: duas ligações para o mesmo tipo
(`DuplicateBindings`), e um objeto de vida curta pedido por um de vida longa, como um `@Singleton` que
quer o `SavedStateHandle` de uma tela. Em cada caso a saída do build nomeia as duas pontas.
