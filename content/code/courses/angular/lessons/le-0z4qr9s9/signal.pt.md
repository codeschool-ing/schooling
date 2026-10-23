---
title: Um signal é um valor que avisa quando muda
version: 1
---

**Um signal guarda um valor, e tudo o que o lê é avisado quando o valor muda.** Essa segunda metade é
a ideia inteira. Um campo comum também guarda um valor, mas ninguém sabe quando alguém escreve nele,
então o Angular precisa ir lá olhar; um signal anuncia. A aula 7 é sobre por que essa diferença decide
como o Angular redesenha uma página. Esta aula é sobre usar signals, e começa fora de um componente,
porque um signal não precisa de um.

Crie uma pasta para programas curtos dentro do projeto, para que eles achem o `@angular/core` no
`node_modules` dele, e salve isto nela:

```typescript
// try/signals.mts
import { signal } from '@angular/core';

const minutes = signal(45);
console.log('read:', minutes());

minutes.set(60);
console.log('after set:', minutes());

minutes.update((m) => m + 15);
console.log('after update:', minutes());

const sessions = signal<number[]>([]);
sessions.update((list) => [...list, 30]);
console.log('sessions:', sessions());
```

O `.mts` diz ao Node que o arquivo é um módulo, então ele roda o `import` sem perguntar. O Node tira os
tipos e roda, como na aula 1:

```
ana@dev:~/planner$ node try/signals.mts
read: 45
after set: 60
after update: 75
sessions: [ 30 ]
```

Três coisas a ler nele:

- **Um signal é lido chamando-o**: `minutes()`, com parênteses. Essa chamada é como um signal fica
  sabendo quem o está lendo, coisa de que a próxima seção depende.
- **O `set` substitui o valor; o `update` calcula o novo a partir do antigo.** Use o `update` sempre
  que o valor novo depender do antigo, para que a leitura e a escrita não se separem.
- **`signal<number[]>([])`** dá nome ao tipo quando o valor inicial não o mostra: um array vazio pode
  guardar qualquer coisa. O TypeScript infere `signal(45)` como um `WritableSignal<number>` sozinho.

## Num template

Um template lê um signal do mesmo jeito, chamando-o: `{{ minutes() }}`. Esquecer os parênteses é o erro
mais comum com signals, e a conferência de templates da aula 4 o pega como erro de build em vez de
imprimir o código-fonte de uma função na página.

Num componente, a convenção é a que a aula 4 definiu para campos: `protected readonly`. `readonly`
porque o campo guarda sempre o mesmo signal, cujo valor muda; ninguém deve trocar o próprio signal.

```typescript
protected readonly minutes = signal(45);
```

## Onde isto fica na história do Angular

Os signals chegaram no Angular 16 como prévia e são estáveis desde o 17 para `signal` e `computed`, e
desde o 20 para `effect` e `linkedSignal`. O framework está no meio do caminho de levar tudo para eles:
inputs (aula 8), queries, formulários e a detecção de mudanças da aula 7. Código escrito antes de 2023
não tem nenhum, e você vai encontrar campos comuns e RxJS (aula 13) onde o código de hoje tem signals.
Os dois são Angular; este curso escreve código novo do jeito novo.
