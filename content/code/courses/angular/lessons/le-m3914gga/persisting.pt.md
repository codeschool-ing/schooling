---
title: Persistindo, com o effect que a aula 6 prometeu
version: 1
---

**Guardar um valor no navegador entre visitas quer dizer escrevê-lo fora da aplicação, e um effect é a
ferramenta para isso.** A aula 6 disse que os effects que valem a pena neste curso eram poucos, e que
um aqui salvaria no `localStorage`, que é exatamente o mundo de fora para o qual um effect serve. Um
`computed` deriva um valor dentro do grafo de signals; um effect faz algo que o grafo não vê, toda vez
que os signals que ele lê mudam.

```schooling-example
{"language": "typescript", "file": "src/app/preferences.ts", "parts": [
 {"code": "// src/app/preferences.ts\nimport { Injectable, computed, effect, signal } from '@angular/core';\n\nconst KEY = 'planner.preferences';\n\ninterface Saved {\n  hideDone: boolean;\n}", "note": "Uma chave para todas as preferências do planner, num objeto JSON, para uma preferência nova ser um campo novo e não uma chave nova a limpar."},
 {"code": "function read(): Saved {\n  try {\n    const saved = JSON.parse(localStorage.getItem(KEY) ?? '{}');\n    return { hideDone: saved?.hideDone === true };\n  } catch {\n    return { hideDone: false };\n  }\n}", "note": "A leitura é duas vezes defensiva. O texto guardado pode não ser JSON, ou ser de uma versão antiga do planner, então cada campo é conferido. E o `localStorage` pode lançar erro: um navegador que bloqueia o armazenamento, ou nenhum navegador, que é onde a aula 23 roda este código. Uma leitura que falha dá as preferências padrão, que é o que uma primeira visita tem de qualquer jeito."},
 {"code": "@Injectable({ providedIn: 'root' })\nexport class Preferences {\n  private readonly state = signal<Saved>(read());\n  readonly hideDone = computed(() => this.state().hideDone);\n\n  constructor() {\n    effect(() => {\n      const saved = JSON.stringify(this.state());\n      try {\n        localStorage.setItem(KEY, saved);\n      } catch (error) {\n        console.warn('Preferences will last this visit only:', error);\n      }\n    });\n  }\n\n  setHideDone(hide: boolean): void {\n    this.state.update((saved) => ({ ...saved, hideDone: hide }));\n  }\n}", "note": "O estado começa do que foi salvo. O effect roda uma vez no começo e de novo sempre que o `state` muda, e o escreve. Uma escrita que falha é dita no console em vez de engolida, porque quer dizer que a preferência não vai durar."}
]}
```

O mesmo look do fim da seção anterior:

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions --do 'check Hide sessions that are done' --do 'go /courses/javascript'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- check Hide sessions that are done
-- go /courses/javascript
[vite] connecting...
Angular is running in development mode.
[vite] connected.
Hide sessions that are done
Tue 13 Oct, 45 minutes
Tue 20 Oct, 1 hour
Sat 24 Oct, 50 minutes
```

A aplicação carregou de novo, fez um `Preferences` novo, e o novo leu o que o velho tinha escrito. Os
componentes não mudaram nada: o `CourseSessions` continua perguntando `hideDone()` e chamando
`setHideDone`, e onde o valor vive entre visitas é assunto do serviço.

**O `localStorage` é do leitor, não seu.** Ele é por navegador e por origem, a pessoa pode limpá-lo, e
qualquer script da página pode ler o que está lá, então ele serve para preferências e rascunhos, nunca
para uma senha ou um token. O que precisa sobreviver a uma troca de computador vai para o servidor, como
as sessões.
