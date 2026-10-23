---
title: O planner de estudos, o app que este curso carrega
version: 1
---

**Cada aula deste curso leva a mesma pequena aplicação web para outro lugar**: para um projeto Android
e um iOS, para uma janela de desktop, para um instalador. É um **planner de estudos**. Você lista os
seus cursos, abre um, acrescenta sessões de estudo com data e duração, marca as que fez e vê quantos
minutos a semana tem. Ele é escrito em TypeScript puro com Vite, sem framework, então nada nele
pertence a React, Angular, Vue ou Svelte, e qualquer que seja o framework que você aprendeu, os mesmos
passos valem para o seu app.

Se você construiu o planner em `front-quality`, use o seu e pule para a seção seguinte quando `npm run
build` funcionar. Se não construiu, esta seção dá ele inteiro: cinco arquivos curtos.

## Criando o projeto

O Vite tem um modelo inicial para um app TypeScript sem framework, chamado `vanilla-ts`. O `npm create`
roda o programa do próprio modelo sem instalar nada de forma permanente. As últimas linhas dele dizem o
que fazer em seguida, e o `ls` mostra o que ele escreveu:

```
ana@dev:~$ npm create vite@9.3.1 planner -- --template vanilla-ts --no-interactive | tail -n 6
└  Done. Now run:

  cd planner
  npm install
  npm run dev

ana@dev:~$ ls -A planner planner/src
planner:
.gitignore
index.html
package.json
public
src
tsconfig.json

planner/src:
assets
counter.ts
main.ts
style.css
```

O modelo escreve uma página de demonstração com um contador e algumas figuras. O planner substitui
tudo isso, então remova os arquivos da demonstração e depois instale as duas ferramentas de que o
projeto precisa, nas versões com que este curso foi gravado:

```
ana@dev:~$ cd planner
ana@dev:~/planner$ rm -r src public
ana@dev:~/planner$ npm install -E -D vite@8.3.5 typescript@6.0.3

added 16 packages, and audited 17 packages in 2s

found 0 vulnerabilities
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "typescript": "6.0.3",
    "vite": "8.3.5"
  }
}
```

**`-E` escreve versões exatas.** Sem ele, o npm escreve `^8.3.5`, que quer dizer "8.3.5 ou qualquer 8
posterior", e um projeto que compila hoje pode instalar outra coisa no mês que vem. Com ele, e com o
`package-lock.json` que o npm escreve ao lado, duas pessoas instalando o mesmo projeto recebem os
mesmos arquivos. O lockfile vai para o git; a `node_modules` não.

## Os cinco arquivos

Salve cada arquivo com o nome que está na primeira linha dele. **`src/planner.ts` guarda as regras** e
não toca em página nenhuma: ele acrescenta uma sessão, marca uma como feita e soma uma semana.
Mantê-lo livre do DOM é o que deixa a aula 7 reaproveitá-lo sem mudança num app que não tem DOM
nenhum.

```typescript
// src/planner.ts: the study planner's rules, with no DOM in them.
export type Course = { id: string; name: string };
export type Session = { id: string; course: string; date: string; minutes: number; done: boolean };
export type Plan = { courses: Course[]; sessions: Session[] };

export function addSession(plan: Plan, course: string, date: string, minutes: number): Plan {
  if (!plan.courses.some((c) => c.id === course)) throw new Error(`no course ${course}`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`not a date: ${date}`);
  if (!Number.isInteger(minutes) || minutes <= 0) throw new Error(`not a duration: ${minutes}`);
  const id = `s${plan.sessions.length + 1}`;
  return { ...plan, sessions: [...plan.sessions, { id, course, date, minutes, done: false }] };
}

export function markDone(plan: Plan, id: string): Plan {
  return { ...plan, sessions: plan.sessions.map((s) => (s.id === id ? { ...s, done: true } : s)) };
}

// The Monday of the week a date falls in, as YYYY-MM-DD.
export function mondayOf(date: string): string {
  const d = new Date(`${date}T12:00:00Z`);
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
  return d.toISOString().slice(0, 10);
}

// Minutes planned in the week that starts on `monday`, and how many are done.
export function weekTotal(plan: Plan, monday: string): { planned: number; done: number } {
  const end = new Date(`${monday}T12:00:00Z`);
  end.setUTCDate(end.getUTCDate() + 7);
  const last = end.toISOString().slice(0, 10);
  const week = plan.sessions.filter((s) => s.date >= monday && s.date < last);
  return {
    planned: week.reduce((n, s) => n + s.minutes, 0),
    done: week.filter((s) => s.done).reduce((n, s) => n + s.minutes, 0),
  };
}
```

**`src/view.ts` desenha o plano** e informa o que a pessoa fez. Todo controle é um `<button>` de
verdade ou um `<input>` com rótulo, então um teclado e um leitor de tela alcançam tudo sem trabalho
extra:

```typescript
// src/view.ts: draws the plan, and tells main.ts what the person did.
import { weekTotal, type Plan } from "./planner";

export type Actions = {
  open: (course: string | null) => void;
  add: (course: string, date: string, minutes: number) => void;
  done: (session: string) => void;
};

function el<K extends keyof HTMLElementTagNameMap>(tag: K, text = ""): HTMLElementTagNameMap[K] {
  const e = document.createElement(tag);
  e.textContent = text;
  return e;
}

export function render(root: HTMLElement, plan: Plan, monday: string, open: string | null, act: Actions) {
  root.replaceChildren();
  const total = weekTotal(plan, monday);
  const week = el("p", `This week: ${total.done} of ${total.planned} minutes done`);
  week.id = "week";
  const course = plan.courses.find((c) => c.id === open);
  if (!course) {
    root.append(el("h1", "Study planner"), week);
    const list = el("ul");
    for (const c of plan.courses) {
      const b = el("button", c.name);
      b.addEventListener("click", () => act.open(c.id));
      const li = el("li");
      li.append(b);
      list.append(li);
    }
    root.append(list);
    return;
  }
  const back = el("button", "All courses");
  back.addEventListener("click", () => act.open(null));
  root.append(back, el("h1", course.name), week);
  const list = el("ul");
  for (const s of plan.sessions.filter((s) => s.course === course.id)) {
    const li = el("li", `${s.date}, ${s.minutes} min `);
    if (s.done) li.append(el("span", "done"));
    else {
      const b = el("button", "Mark done");
      b.addEventListener("click", () => act.done(s.id));
      li.append(b);
    }
    list.append(li);
  }
  const form = el("form");
  form.innerHTML = `<label>Date <input name="date" type="date" required></label>
<label>Minutes <input name="minutes" type="number" min="1" required></label>
<button>Add session</button>`;
  form.addEventListener("submit", (e) => {
    e.preventDefault();
    const f = new FormData(form);
    act.add(course.id, String(f.get("date")), Number(f.get("minutes")));
  });
  root.append(list, form);
}
```

**`src/main.ts` liga os dois.** Ele carrega os dados, guarda o plano atual e redesenha depois de cada
mudança. O `?today=` no endereço é para este curso: ele faz toda transcrição mostrar a mesma semana,
seja qual for o dia em que você a lê. Sem ele, o planner usa a data real.

```typescript
// src/main.ts: loads the plan, keeps it, and redraws it after every change.
import { addSession, markDone, mondayOf, type Plan } from "./planner";
import { render } from "./view";

const root = document.querySelector<HTMLElement>("#app")!;
const today = new URLSearchParams(location.search).get("today") ?? new Date().toISOString().slice(0, 10);
let plan: Plan = await (await fetch("courses.json")).json();
let open: string | null = null;

function draw() {
  render(root, plan, mondayOf(today), open, {
    open: (c) => { open = c; draw(); },
    add: (c, d, m) => { plan = addSession(plan, c, d, m); draw(); },
    done: (s) => { plan = markDone(plan, s); draw(); },
  });
}
draw();
```

A própria página substitui a do modelo, como `index.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
  </head>
  <body>
    <main id="app"></main>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

E os dados, três cursos e seis sessões na segunda metade de outubro de 2026, salvos como
`public/courses.json`:

```json
{
  "courses": [
    { "id": "spanish", "name": "Spanish A2" },
    { "id": "statistics", "name": "Statistics" },
    { "id": "guitar", "name": "Guitar" }
  ],
  "sessions": [
    { "id": "s1", "course": "spanish", "date": "2026-10-19", "minutes": 30, "done": true },
    { "id": "s2", "course": "statistics", "date": "2026-10-20", "minutes": 45, "done": true },
    { "id": "s3", "course": "guitar", "date": "2026-10-21", "minutes": 20, "done": false },
    { "id": "s4", "course": "spanish", "date": "2026-10-22", "minutes": 30, "done": false },
    { "id": "s5", "course": "statistics", "date": "2026-10-26", "minutes": 60, "done": false },
    { "id": "s6", "course": "guitar", "date": "2026-10-28", "minutes": 20, "done": false }
  ]
}
```

O Vite copia o que estiver em `public/` para o site construído do jeito que está, então o app busca o
arquivo pelo nome simples, `courses.json`.

## Construindo

`npm run build` roda os dois comandos que o `package.json` nomeia: `tsc`, que confere os tipos e não
escreve nada, e `vite build`, que escreve o site pronto em `dist/`:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 6 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                0.32 kB │ gzip: 0.23 kB
dist/assets/index-kF5hUKai.js  2.90 kB │ gzip: 1.34 kB

✓ built in 150ms
```

**A `dist/` é o que toda aula seguinte embrulha.** O Capacitor a copia para um projeto Android e um
iOS, o Electron e o Tauri a carregam numa janela. Se `npm run build` falhar, nada depois dele funciona,
então este comando vem primeiro sempre que algo parecer errado.

Por fim, faça do projeto um repositório git, para que cada aula seguinte possa mostrar exatamente o
que uma ferramenta acrescentou a ele:

```
ana@dev:~/planner$ git init -q
ana@dev:~/planner$ git add .
ana@dev:~/planner$ git commit -q -m "The study planner, as lesson 1 gives it"
ana@dev:~/planner$ git log --oneline
558b1c0 The study planner, as lesson 1 gives it
```
