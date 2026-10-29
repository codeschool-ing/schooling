---
title: Uma anotação em cada sessão, escrita do jeito rápido
version: 1
---

**O planner ganha um recurso nesta aula: uma anotação numa sessão de estudo**, uma ou duas linhas sobre
o que cobrir. Anotações têm quebras de linha, e o jeito mais rápido de mantê-las na página é trocar cada
`\n` por um `<br>` e escrever o resultado com `innerHTML`. É exatamente assim que o cross-site scripting
entra nas aplicações: não porque alguém decidiu permitir, mas por uma linha escrita para manter alguma
formatação.

Eis o recurso, em três arquivos. Uma sessão pode ter uma `note`; o `addSession` recebe uma; e a página do
curso a mostra e tem um campo para ela:

```
ana@dev:~/planner$ git diff src/planner.ts src/view.ts
diff --git a/src/planner.ts b/src/planner.ts
index 979e7ab..80218df 100644
--- a/src/planner.ts
+++ b/src/planner.ts
@@ -10,6 +10,7 @@ export interface Session {
   date: string;
   minutes: number;
   done: boolean;
+  note?: string;
 }
 
 export interface Plan {
@@ -17,14 +18,15 @@ export interface Plan {
   sessions: Session[];
 }
 
-export function addSession(plan: Plan, course: string, date: string, minutes: number): Plan {
+export function addSession(plan: Plan, course: string, date: string, minutes: number, note = ""): Plan {
   if (!plan.courses.some((c) => c.id === course)) throw new Error(`no course ${course}`);
   if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`not a date: ${date}`);
   if (!Number.isInteger(minutes) || minutes < 1 || minutes > 600) {
     throw new Error(`minutes must be a whole number from 1 to 600, not ${minutes}`);
   }
   const id = Math.max(0, ...plan.sessions.map((s) => s.id)) + 1;
-  return { ...plan, sessions: [...plan.sessions, { id, course, date, minutes, done: false }] };
+  const session = { id, course, date, minutes, done: false, ...(note ? { note } : {}) };
+  return { ...plan, sessions: [...plan.sessions, session] };
 }
 
 export function markDone(plan: Plan, id: number): Plan {
diff --git a/src/view.ts b/src/view.ts
index 31c6742..52e94e0 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -33,16 +33,23 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
       tick.addEventListener("click", () => update(markDone(plan, s.id)));
       item.append(tick);
     }
+    if (s.note) {
+      const note = el("p", "", "note");
+      note.innerHTML = s.note.replace(/\n/g, "<br>");
+      item.append(note);
+    }
     list.append(item);
   }
   const form = el("form", "", "add");
   form.innerHTML = `<label>Date <input name="date" type="date"></label>
     <label>Minutes <input name="minutes" type="number" min="1" max="600"></label>
+    <label>Note <textarea name="note"></textarea></label>
     <button>Add session</button>`;
   form.addEventListener("submit", (event) => {
     event.preventDefault();
     const data = new FormData(form);
-    update(addSession(plan, course.id, String(data.get("date")), Number(data.get("minutes"))));
+    const note = String(data.get("note") ?? "");
+    update(addSession(plan, course.id, String(data.get("date")), Number(data.get("minutes")), note));
   });
   root.append(list, form, el("p", `This week: ${weekTotal(plan, day, course.id)} min`, "week"));
 }
```

**Leia a linha com `innerHTML`.** Ela escreve a anotação na página como marcação, então qualquer marcação
que a anotação tenha é construída. Uma anotação é um texto que uma pessoa digitou e, mais tarde, quando as
sessões ficarem guardadas no servidor, um texto que veio de outro lugar. Um teste do recurso diz o que ele
precisa fazer, nos termos da aula 3: uma anotação aparece como o texto que foi digitado. Acrescente-o ao
fim do `src/view.test.ts`:

```typescript
// src/view.test.ts, below what is there
test("a note is shown as the text that was typed", async () => {
  const user = userEvent.setup();
  show("#/course/javascript");
  await user.type(screen.getByLabelText("Date"), "2026-10-23");
  await user.type(screen.getByLabelText("Minutes"), "15");
  await user.type(screen.getByLabelText("Note"), "chapter <b>3</b>, again");
  await user.click(screen.getByRole("button", { name: "Add session" }));
  expect(screen.getByText("chapter <b>3</b>, again")).toBeInTheDocument();
});
```

**A testemunha é o `<b>`**, a marcação mais simples que existe. Se a página mostrar os caracteres
`<b>3</b>`, a anotação continuou texto. Se mostrar um **3** em negrito, a página construiu um elemento a
partir do que uma pessoa digitou, e teria construído qualquer outro elemento do mesmo jeito, um script
inclusive. Nenhum script é necessário para provar isso, e nenhum é usado.

```
ana@dev:~/planner$ npx vitest run src/view.test.ts 2>&1 | grep -E -A3 "^ FAIL|Unable to find|class=\"note\""
 FAIL  src/view.test.ts > a note is shown as the text that was typed
TestingLibraryElementError: Unable to find an element with the text: chapter <b>3</b>, again. This could be because the text is broken up by multiple elements. In this case, you can provide a function for your text matcher to make your matcher more flexible.

Ignored nodes: comments, script, style
<body>
--
          class="note"
        >
          chapter 
          <b>
```

**Vermelho, e o despejo mostra por quê**: o parágrafo tem `chapter ` e depois um elemento `<b>`. A página
construiu um elemento a partir da anotação. Faça o commit da versão com falha como está, para a correção
ser um diff próprio:

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "A note on each session"
```
