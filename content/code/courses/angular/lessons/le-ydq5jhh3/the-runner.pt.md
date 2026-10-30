---
title: O que o `ng test` roda
version: 1
---

**A aula 2 rodou o `ng test` uma vez e leu uma falha; desde então o planner juntou arquivos de spec
sem ninguém escolher o que eles testam.** A maioria são os que o CLI escreveu ao lado de cada arquivo
gerado, e algumas aulas os rodaram quando uma mudança quebrou um. Esta aula escreve testes de
propósito, em cada um dos níveis que uma aplicação Angular tem. Primeiro, como as coisas estão:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | tail -14
 RUN  v4.1.12 /home/ana/planner

 ✓ |planner| src/app/minutes-pipe.spec.ts (4 tests) 5ms
 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 61ms
 ✓ |planner| src/app/autofocus.spec.ts (1 test) 10ms
 ✓ |planner| src/app/app.spec.ts (2 tests) 77ms
 ✓ |planner| src/app/planner-store.spec.ts (1 test) 6ms
 ✓ |planner| src/app/week/week.spec.ts (1 test) 80ms

 Test Files  6 passed (6)
      Tests  10 passed (10)
   Start at  20:57:04
   Duration  1.24s (transform 283ms, setup 925ms, import 356ms, tests 239ms, environment 3.19s)
```

Dez testes em seis arquivos, e a maioria diz pouco. O `planner-store.spec.ts` confere que o store
"should be created"; o `week-summary.spec.ts` confere o mesmo de um componente. Esses são os
marcadores do CLI: passam enquanto a classe puder ser criada, e continuariam passando se todo número
que o planner mostra estivesse errado. A aritmética do `planner.ts`, de que toda tela depende, não
tem teste nenhum.

Sem `--watch=false`, o `ng test` continua rodando e roda de novo os specs afetados a cada vez que
você salva, que é como se usa enquanto se escreve código. As transcrições aqui usam `--watch=false`
porque elas terminam.

Três nomes, para não se misturarem:

| nome | o que é |
| --- | --- |
| **Vitest** | o runner: acha os testes, roda, e dá `describe`, `it`, `expect` e `vi` |
| **jsdom** | um DOM escrito em JavaScript, para um componente renderizar sem navegador |
| **TestBed** | do Angular: monta um injetor e componentes dentro de um teste, como o `bootstrapApplication` faz para a aplicação |

O jsdom é o motivo de os testes começarem em cerca de um segundo: nenhum navegador abre. É também o
limite deles. O jsdom tem elementos, eventos e `localStorage`, mas não tem layout: nada tem tamanho
nem posição, e nada é desenhado. Um teste que precisa de um navegador de verdade pode ter um, pela
opção `browsers` do builder de testes e um provider de navegador do Vitest; os testes do planner não
precisam, e o `look` da aula 2 já abre um navegador de verdade para o que só um navegador sabe dizer.

O formato que todo teste aqui segue é o que a aula 19 usou para o pipe `minutes`. O `describe` nomeia
um grupo, o `it` nomeia um teste, e o nome é uma frase sobre o que deveria ser verdade, porque essa
frase é o que o relatório imprime quando não é:

```
ana@dev:~/planner$ cat src/app/minutes-pipe.spec.ts
// src/app/minutes-pipe.spec.ts
import { MinutesPipe } from './minutes-pipe';

describe('MinutesPipe', () => {
  const pipe = new MinutesPipe();

  it('writes less than an hour in minutes', () => {
    expect(pipe.transform(50)).toBe('50 minutes');
    expect(pipe.transform(1)).toBe('1 minute');
  });

  it('writes whole hours without minutes', () => {
    expect(pipe.transform(60)).toBe('1 hour');
    expect(pipe.transform(120)).toBe('2 hours');
  });

  it('writes hours and minutes together', () => {
    expect(pipe.transform(165)).toBe('2 hours 45 minutes');
    expect(pipe.transform(61)).toBe('1 hour 1 minute');
  });

  it('writes nothing as 0 minutes', () => {
    expect(pipe.transform(0)).toBe('0 minutes');
  });
});
```

Nenhum `TestBed` em lugar nenhum: um pipe é uma classe, então o teste cria um com `new` e chama.
**Esse é o teste mais barato que existe, e o primeiro a usar**: nada a configurar, nada a esperar, e
uma falha que só pode querer dizer que a função está errada. A próxima seção dá à aritmética do
planner o mesmo tipo de teste.
