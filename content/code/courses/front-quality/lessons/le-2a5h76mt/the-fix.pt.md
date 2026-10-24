---
title: Texto continua texto
version: 1
---

**A correção é escrever a anotação como texto e deixar o CSS manter as quebras de linha**, uma
propriedade que o CSS tem há muito tempo: o `white-space: pre-line` mostra um `\n` como uma linha nova e
junta os outros espaços como de costume.

```
ana@dev:~/planner$ git diff
diff --git a/src/style.css b/src/style.css
index 184ff39..d3d4775 100644
--- a/src/style.css
+++ b/src/style.css
@@ -11,3 +11,4 @@ button:focus { outline: none; }
 .add { display: flex; gap: 0.5rem; margin: 1rem 0; }
 .week { font-weight: bold; animation: pulse 1s ease-in-out 3; }
 @keyframes pulse { 50% { transform: scale(1.06); } }
+.note { white-space: pre-line; margin: 0.2rem 0 0; }
diff --git a/src/view.ts b/src/view.ts
index 52e94e0..0a81f3f 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -35,7 +35,7 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
     }
     if (s.note) {
       const note = el("p", "", "note");
-      note.innerHTML = s.note.replace(/\n/g, "<br>");
+      note.textContent = s.note;
       item.append(note);
     }
     list.append(item);
```

O `textContent` põe os caracteres no parágrafo do jeito que são, então `<b>` são dois sinais de menor e
maior e uma letra, e não há nada para construir. O estilo vai no `src/style.css`, ao lado das outras
regras.

```
ana@dev:~/planner$ npx vitest run src/view.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  4 passed (4)
   Start at  20:41:55
   Duration  1.33s (environment 52%, tests 34%, import 9%, transform 4%)
```

E a suíte inteira, com os testes de navegador, já que a página do curso mudou:

```
ana@dev:~/planner$ npm run check 2>&1 | grep -E "Tests |[0-9] (passed|failed)"
 Test Files  5 passed (5)
      Tests  33 passed (33)
  8 passed (6.3s)
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Write the note as text"
```

## A regra por trás

**Todo valor entra na página pelo método que combina com o que ele é.** Texto pelo `textContent` ou pelo
`createElement`, um atributo pelo `setAttribute` com um nome que não seja de tratador de evento, uma URL
por uma checagem do esquema. Marcação é escrita com `innerHTML` só quando a marcação é do próprio site,
um template fixo, nunca quando qualquer parte dela veio de uma pessoa ou de um servidor. O `view.ts` do
planner fez isso com todo valor desde a aula 1, pelo ajudante `el()`; a anotação foi a única linha que
quebrou o hábito, que é como isso costuma acontecer.
