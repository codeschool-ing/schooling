---
title: O que você já sabe sobre o loop
version: 1
---

A aula 13 do javascript montou o event loop a partir de três partes, e as três valem no Node:

1. **uma pilha de chamadas**, e um callback só roda quando ela está vazia;
2. **uma fila de tarefas**, onde esperam trabalhos inteiros — o callback de um timer, uma requisição
   de rede que terminou — que rodam um de cada vez;
3. **uma fila de microtasks**, para callbacks de promise e `queueMicrotask`, que é esvaziada por
   completo depois de cada tarefa, antes de a próxima começar.

Aquela aula também mostrou a ordem em que um programa imprime, no Node e num navegador, e os dois
concordaram. **Esse modelo continua certo, e esta aula só acrescenta detalhe à segunda parte.** No
navegador a fila de tarefas é descrita como uma fila só. No Node são várias, visitadas numa ordem
fixa, e essa ordem é o que decide entre dois callbacks que estão prontos.

O que não muda é a consequência mais importante que a aula 13 tirou: **enquanto o seu código roda,
nada mais roda.** Numa página isso congelava um botão. Num servidor isso segura todas as outras
requisições do processo, e a seção sobre bloquear o loop mede quanto.

As outras coisas que esta aula pressupõe do `javascript`:

| de onde | o quê |
|---|---|
| aula 14 | callbacks, promises, `async`/`await`, e rodar coisas em paralelo com `Promise.all` |
| aula 15 | timers, e por que `setTimeout(fn, 0)` não quer dizer "agora" |
| aula 17 | `throw`, `try`/`catch`, e erros que acontecem depois |

Se algum desses estiver nebuloso, vale uma hora lá antes de seguir. Tudo nas aulas 5 a 10 deste
curso é escrito com eles.
