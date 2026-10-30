---
title: "React Native: expo-background-task, e as regras por baixo"
version: 1
---

**Um app React Native roda em segundo plano exatamente sob as regras da plataforma em que está; a
biblioteca só poupa você do código nativo.** O `expo-background-task` do Expo, no Expo SDK 53 em
diante, agenda uma tarefa pelo WorkManager no Android e pelo `BGTaskScheduler` no iOS, então tudo
nas duas seções anteriores continua valendo: quinze minutos no mínimo, nenhuma garantia de quando,
uns trinta segundos no iOS, nada depois de um forçar parada.

*A listagem desta seção não foi rodada para este curso: uma tarefa em segundo plano precisa de um
aparelho Android ou iOS, ou de um emulador, e nenhum estava disponível. Ela segue a documentação do
`expo-background-task` em docs.expo.dev.*

```tsx
import * as BackgroundTask from "expo-background-task";
import * as TaskManager from "expo-task-manager";

const SYNC = "planner-sync";

// At the top level of a module, never inside a component.
TaskManager.defineTask(SYNC, async () => {
  try {
    await sync();
    return BackgroundTask.BackgroundTaskResult.Success;
  } catch {
    return BackgroundTask.BackgroundTaskResult.Failed;
  }
});

export async function scheduleSync() {
  await BackgroundTask.registerTaskAsync(SYNC, { minimumInterval: 15 }); // in minutes
}
```

**Por que o nível de cima importa.** Quando o sistema decide rodar a tarefa, ele pode iniciar o app
sem tela nenhuma: nenhum componente montado, nenhuma navegação, e o JavaScript roda a partir do
primeiro módulo. Uma tarefa definida dentro de um componente ainda não existiria, e a execução não
faria nada. O mesmo vale para o que `sync` usa: o banco precisa ser aberto pela própria tarefa, não
por uma tela que nunca foi desenhada.

**Pergunte se é permitido.** `BackgroundTask.getStatusAsync()` responde se as tarefas em segundo
plano estão disponíveis ou restritas, por exemplo porque a pessoa desligou a Atualização em Segundo
Plano no iOS. Um planner que as encontra restritas não perde nada importante se a sincronização dele
também roda na abertura e ao salvar, como a primeira seção disse que precisa.

Um ponto é próprio do jeito como a tarefa é iniciada. Com o app aberto, a tarefa roda no mesmo
ambiente JavaScript das telas, então uma sincronização em segundo plano e uma que uma tela iniciou
podem rodar ao mesmo tempo e esvaziar a mesma caixa de saída duas vezes. Com o app fechado, a tarefa
é uma abertura nova que não sabe nada da anterior. **Então proteja a caixa de saída nas linhas, não
na memória**: as linhas registram o que está em andamento, que é como a aula 8 as marca, e as chaves
de idempotência da aula 10 absorvem a duplicata rara que passar.
