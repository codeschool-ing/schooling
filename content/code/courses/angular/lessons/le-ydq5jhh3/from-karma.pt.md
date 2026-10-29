---
title: Karma e Jasmine, e a mudança para o Vitest
version: 1
---

**Até o Angular 21, o `ng new` configurava o Karma e o Jasmine; a partir do Angular 21 configura o
Vitest, e a maior parte do código Angular que você vai abrir no trabalho ainda tem os dois
primeiros.** O Karma é um runner que abre um navegador de verdade, em geral o Chrome, e roda os testes
lá dentro; o Jasmine é a biblioteca que dá `describe`, `it`, `expect` e spies. O projeto Karma foi
descontinuado em 2023, e isso explica boa parte da mudança: um runner que ninguém mantém é um runner
que ninguém conserta.

A maior parte de um teste se lê igual nos dois. `describe`, `it`, `beforeEach`,
`expect(...).toBe(...)` e tudo que o `TestBed` faz são idênticos, e é por isso que os testes deste
curso rodariam quase todos no Karma. As diferenças estão nos spies e em alguns matchers. Um spec
escrito do jeito do Jasmine, como um projeto de antes do Angular 21 o teria:

```typescript
// src/app/minutes-pipe.jasmine.spec.ts
import { MinutesPipe } from './minutes-pipe';

describe('MinutesPipe, as Karma projects wrote it', () => {
  it('writes an hour and a half in words', () => {
    const pipe = new MinutesPipe();
    const transform = spyOn(pipe, 'transform').and.callThrough();
    expect(pipe.transform(90)).toBe('1 hour 30 minutes');
    expect(transform).toHaveBeenCalledOnceWith(90);
  });
});
```

O `spyOn` embrulha um método para um teste poder perguntar como ele foi chamado; o
`.and.callThrough()` deixa o método de verdade rodar também. No Vitest nenhum dos dois nomes existe,
e o build para antes de um teste rodar:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -A4 ERROR
✘ [ERROR] TS2304: Cannot find name 'spyOn'. [plugin angular-compiler]

    src/app/minutes-pipe.jasmine.spec.ts:7:22:
      7 │     const transform = spyOn(pipe, 'transform').and.callThrough();
        ╵                       ~~~~~
--
✘ [ERROR] TS2551: Property 'toHaveBeenCalledOnceWith' does not exist on type 'Assertion<any>'. Did you mean 'toHaveBeenCalledOnce'? [plugin angular-compiler]

    src/app/minutes-pipe.jasmine.spec.ts:9:22:
      9 │     expect(transform).toHaveBeenCalledOnceWith(90);
        ╵                       ~~~~~~~~~~~~~~~~~~~~~~~~
```

O CLI tem um schematic para essa mudança. Ele está marcado como experimental, então é rodado num
arquivo só e o trabalho dele é lido antes de ganhar confiança:

```
ana@dev:~/planner$ npx ng generate @schematics/angular:refactor-jasmine-vitest --include src/app/minutes-pipe.jasmine.spec.ts
    Jasmine to Vitest Refactoring Summary:
    - 1 test file(s) scanned.
    - 1 file(s) transformed.
CREATE jasmine-vitest-20261029T223326033Z.md (350 bytes)
UPDATE src/app/minutes-pipe.jasmine.spec.ts (473 bytes)
```

```
ana@dev:~/planner$ cat src/app/minutes-pipe.jasmine.spec.ts
// src/app/minutes-pipe.jasmine.spec.ts
import { MinutesPipe } from './minutes-pipe';

describe('MinutesPipe, as Karma projects wrote it', () => {
  it('writes an hour and a half in words', () => {
    const pipe = new MinutesPipe();
    const transform = vi.spyOn(pipe, 'transform');
    expect(pipe.transform(90)).toBe('1 hour 30 minutes');
    expect(transform).toHaveBeenCalledTimes(1);
    expect(transform).toHaveBeenCalledWith(90);
  });
});
```

O `spyOn` virou `vi.spyOn`, que chama o método de verdade por padrão, então o `.and.callThrough()`
não tinha mais nada a dizer. O `toHaveBeenCalledOnceWith`, que o Vitest não tem, virou as duas
verificações que ele sempre quis dizer. O relatório que ele escreveu diz que nada precisou de uma
pessoa; quando algo precisa, ele lista como um `TODO`, com o arquivo e a linha.

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓.*jasmine|Tests '
 ✓ |planner| src/app/minutes-pipe.jasmine.spec.ts (1 test) 5ms
      Tests  22 passed (22)
```

O arquivo era só para esta seção, e o relatório não faz parte do projeto:

```
ana@dev:~/planner$ rm src/app/minutes-pipe.jasmine.spec.ts jasmine-vitest-*.md
```

A outra metade de uma mudança de verdade é o `angular.json`. Um projeto no Karma nomeia o builder
`@angular/build:karma`, ou o mais antigo `@angular-devkit/build-angular:karma`, em `test`, com um
`karma.conf.js` ao lado. O do planner diz `@angular/build:unit-test`, o builder que roda o Vitest, e
esse builder também roda o Karma, com `"runner": "karma"`: um projeto pode trocar o builder primeiro e
o runner depois, com os testes verdes entre os dois passos.

| Jasmine, no Karma | Vitest |
| --- | --- |
| `spyOn(object, 'method')` | `vi.spyOn(object, 'method')` |
| `jasmine.createSpy()` | `vi.fn()` |
| `.and.returnValue(x)` | `.mockReturnValue(x)` |
| `toHaveBeenCalledOnceWith(x)` | `toHaveBeenCalledTimes(1)` e `toHaveBeenCalledWith(x)` |
| um navegador de verdade, aberto pelo Karma | o jsdom no Node.js, ou um navegador de verdade se for pedido |
