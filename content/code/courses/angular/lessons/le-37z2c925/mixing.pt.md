---
title: Módulos e standalone, na mesma aplicação
version: 1
---

**Módulos e componentes standalone funcionam juntos nas duas direções, e é por isso que uma migração
pode ir um arquivo por vez.** A seção anterior mostrou uma direção, um módulo importando um componente
standalone. Esta mostra as outras, porque um código de verdade fica no meio da mudança por muito
tempo.

## Um componente standalone que importa um módulo

Uma biblioteca escrita antes do standalone traz as suas peças como um NgModule. Um componente
standalone põe o módulo no próprio `imports`, e o template pode então usar tudo o que o módulo
exporta:

```typescript
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-note',
  imports: [FormsModule],
  template: '<input [(ngModel)]="text" />',
})
export class Note {
  text = '';
}
```

O `FormsModule` exporta o `ngModel`, assunto da aula 16, e ainda é assim que ele é importado no
Angular 21. Os pacotes do próprio Angular agora são quase todos standalone, e alguns dos módulos deles
continuam como um pacote prático de peças relacionadas.

## Providers que vinham de um módulo

Os módulos também traziam **providers**, as coisas que um componente pode pedir para receber. O
`HttpClientModule` tornava o `HttpClient` disponível; o `RouterModule.forRoot(routes)` configura o
router. Uma aplicação standalone não tem módulo onde importá-los, então o Angular deu a cada um uma
função:

| uma app baseada em módulos importa | uma app standalone fornece |
|---|---|
| `RouterModule.forRoot(routes)` | `provideRouter(routes)` |
| `HttpClientModule` | `provideHttpClient()` |
| `StoreModule.forRoot(reducers)`, do NgRx (aula 22) | `provideStore(reducers)` |

Para um módulo que ainda não tem essa função, geralmente de uma biblioteca, existe o
**`importProvidersFrom(UmModulo)`**: ele tira os providers do módulo e os entrega à aplicação
standalone. É o invólucro que a migração escreveu no `main.ts` de `~/legacy`, e é a ponte que toda
aplicação meio migrada atravessa. A versão arrumada daquele arquivo é o formato que o `app.config.ts`
do planner já tem:

```typescript
bootstrapApplication(App, {
  providers: [provideBrowserGlobalErrorListeners(), provideRouter(routes)],
});
```

O `BrowserModule` sai de vez, porque o `bootstrapApplication` monta tudo o que ele fornecia.

## Lendo um código misturado

Três perguntas resolvem a maior parte da confusão num código no meio do caminho:

1. **O componente diz `standalone: false`, ou nada, num projeto anterior ao Angular 19?** Então o
   escopo do template dele é o de um módulo, e o módulo que o declara é onde procurar.
2. **O componente é standalone?** Então o próprio `imports` dele é tudo o que o template pode usar.
3. **Falta um provider em tempo de execução?** Então procure uma função `provide…()`, ou um
   `importProvidersFrom` em volta do módulo que o fornecia.

O `~/legacy` cumpriu o papel. Apague-o, e os 320 MB dele junto:

```
ana@dev:~$ rm -rf ~/legacy
```
