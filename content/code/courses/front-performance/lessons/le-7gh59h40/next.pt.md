---
title: Next.js
version: 1
---

**No Next.js uma pasta é um endereço e o `page.tsx` dentro dela é a página.** `app/page.tsx` atende
`/`, `app/courses/[slug]/page.tsx` atende `/courses/` seguido de qualquer coisa, e os colchetes
fazem de `slug` um parâmetro. Todo componente em `app/` é um **server component**, um componente de
servidor, a não ser que o seu arquivo diga o contrário: ele roda no servidor, pode ler um arquivo
ou um banco de dados diretamente, e manda ao navegador o seu HTML, não o seu código.

Os dados são lidos num lugar só. Salve isto como `lib/plan.ts`:

```typescript
// lib/plan.ts: the planner's data, read on the server.
import { readFile } from "node:fs/promises";
import { cacheLife } from "next/cache";

export interface Plan {
  courses: { slug: string; title: string }[];
  sessions: { id: number; course: string; date: string; minutes: number; done: boolean }[];
}

export async function getPlan(): Promise<Plan> {
  "use cache";
  cacheLife("hours");
  return JSON.parse(await readFile("courses.json", "utf8"));
}
```

**`"use cache"` é a linha que decide como este app renderiza.** Projetos Next.js 16 são criados com
os *Cache Components* ligados (está no `next.config.ts` que o criador escreveu), e com eles todo
dado que uma página lê ou está em cache, com um tempo de vida, ou é lido a cada requisição. Esta
função fica em cache por `"hours"`, um dos tempos de vida que o Next.js nomeia, então uma página que
só lê dela pode ser renderizada uma vez, no build, e guardada. A aula 3 é sobre o que acontece
quando esse tempo de vida acaba.

A página em volta de toda rota substitui o `app/layout.tsx` do criador:

```tsx
// app/layout.tsx: the page around every route.
export const metadata = { title: "Study planner" };

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en">
      <body>
        <main>{children}</main>
      </body>
    </html>
  );
}
```

A página inicial, no lugar de `app/page.tsx`. Ela é uma função `async`, porque um server component
pode esperar pelos seus dados:

```tsx
// app/page.tsx: the address /.
import Link from "next/link";
import { getPlan } from "@/lib/plan";

export default async function Home() {
  const plan = await getPlan();
  return (
    <>
      <h1>Study planner</h1>
      <ul>
        {plan.courses.map((c) => (
          <li key={c.slug}>
            <Link href={`/courses/${c.slug}`}>{c.title}</Link> ·{" "}
            {plan.sessions.filter((s) => s.course === c.slug).length} sessions
          </li>
        ))}
      </ul>
    </>
  );
}
```

E um curso, num arquivo novo, `app/courses/[slug]/page.tsx`. **`generateStaticParams` lista os
valores de `slug` que existem**, para que o build saiba quais páginas de curso pode renderizar antes.
`params` chega como uma promise, e `notFound()` responde a um slug desconhecido com um 404:

```tsx
// app/courses/[slug]/page.tsx: the address /courses/<slug>, one per course.
import Link from "next/link";
import { notFound } from "next/navigation";
import { getPlan } from "@/lib/plan";

export async function generateStaticParams() {
  const plan = await getPlan();
  return plan.courses.map((c) => ({ slug: c.slug }));
}

export default async function Course({ params }: PageProps<"/courses/[slug]">) {
  const { slug } = await params;
  const plan = await getPlan();
  const course = plan.courses.find((c) => c.slug === slug);
  if (!course) notFound();
  return (
    <>
      <p><Link href="/">All courses</Link></p>
      <h1>{course.title}</h1>
      <ul>
        {plan.sessions.filter((s) => s.course === slug).map((s) => (
          <li key={s.id}>{s.date} · {s.minutes} min{s.done ? " · done" : ""}</li>
        ))}
      </ul>
    </>
  );
}
```

`LayoutProps` e `PageProps` são tipos que o Next.js escreve para você a partir das pastas, então o
parâmetro fica tipado sem uma linha sua. `Link` é um `<a>` que o Next.js também trata no navegador,
como o `mount` fazia na aula 1.

## O build diz o que decidiu

O `next build` termina com uma tabela de cada rota e de como ela foi renderizada:

```
ana@dev:~/meta/next$ npm run build 2>&1 | sed -n '/^Route/,$p'
Route (app)                Revalidate  Expire
┌ ○ /                              1h      1d
├ ○ /_not-found
└   /courses/[slug]
  ├ ◐ /courses/[slug]
  ├ ○ /courses/html-css            1h      1d
  ├ ○ /courses/javascript          1h      1d
  └ ○ /courses/git                 1h      1d


○  (Static)             prerendered as static content
◐  (Partial Prerender)  prerendered as static HTML with dynamic server-streamed content
```

**`○` é uma página renderizada no build, num arquivo.** A página inicial e os três cursos são. As
duas colunas da direita vêm de `cacheLife("hours")`: uma hora depois de uma cópia ser feita, a
próxima requisição ainda recebe essa cópia enquanto o Next.js faz uma nova em segundo plano, e
depois de um dia sem requisições a cópia antiga não é mais servida. A quarta linha embaixo de
`/courses/[slug]` é a de um slug que o build não listou, e o seu `◐` diz que ela foi
pré-renderizada em parte: o Next.js guarda uma casca para ela e renderiza o resto quando alguém
pede. A aula 3 visita essa linha de propósito. Ligue o servidor de produção no segundo terminal:

```sh
npx next start -p 3001
```
