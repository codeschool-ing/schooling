---
title: "Sob demanda: quando os dados dizem"
version: 1
---

**Um timer regenera uma página porque o tempo passou. A revalidação sob demanda a regenera porque
alguém disse que os dados mudaram**, e entre uma mudança e outra não acontece nada. O programa que
muda os dados, o botão de salvar de um editor ou um job que importa preços, chama um endereço do site
que marca as cópias afetadas como desatualizadas.

No Next.js as cópias são achadas por uma **tag**. O `cacheTag("plan")` dentro do `getPlan()` rotula
tudo o que foi renderizado a partir do plano, e o `revalidateTag("plan", …)` marca tudo de uma vez,
página inicial e páginas de curso juntas. Isso também resolve o problema de duas páginas que
discordam. Substitua o `lib/plan.ts`:

```typescript
// lib/plan.ts: the planner's data, read on the server, cached and tagged.
import { readFile } from "node:fs/promises";
import { cacheLife, cacheTag } from "next/cache";

export interface Plan {
  courses: { slug: string; title: string }[];
  sessions: { id: number; course: string; date: string; minutes: number; done: boolean }[];
}

export async function getPlan(): Promise<Plan> {
  "use cache";
  cacheLife("hours");
  cacheTag("plan");
  return JSON.parse(await readFile("courses.json", "utf8"));
}
```

E o endereço que faz a marcação, um **route handler** num arquivo novo,
`app/api/revalidate/route.ts`:

```typescript
// app/api/revalidate/route.ts: POST here after changing courses.json.
import { revalidateTag } from "next/cache";

export async function POST(request: Request) {
  const secret = process.env.REVALIDATE_SECRET;
  if (!secret || request.headers.get("x-revalidate-secret") !== secret) {
    return new Response("forbidden\n", { status: 403 });
  }
  revalidateTag("plan", { expire: 0 });
  return new Response("revalidated\n");
}
```

**O segredo não é opcional.** Um endereço que joga fora todas as páginas em cache é um endereço que
qualquer um na internet pode chamar sem parar, transformando cada requisição numa renderização
completa; a conferência recusa quem não tem o segredo, e um servidor ligado sem segredo nenhum
recusa todo mundo. O `{ expire: 0 }` pede que as cópias velhas não sejam mais servidas depois de marcadas.

Faça o build, e ligue o servidor com o segredo no ambiente dele, no segundo terminal:

```sh
npm run build && REVALIDATE_SECRET=s3cret npx next start -p 3001
```

Depois mude os dados, chame o endereço sem o segredo e com ele, e peça as páginas:

```
ana@dev:~/meta/next$ sed -i 's/"title": "Git"/"title": "Git and GitHub"/' courses.json
ana@dev:~/meta/next$ curl -s -X POST http://localhost:3001/api/revalidate
forbidden
ana@dev:~/meta/next$ curl -s -X POST -H 'x-revalidate-secret: s3cret' http://localhost:3001/api/revalidate
revalidated
ana@dev:~/meta/next$ curl -s http://localhost:3001/courses/git | grep -o '<h1>[^<]*</h1>'
<h1>Git</h1>
ana@dev:~/meta/next$ curl -s http://localhost:3001/courses/git | grep -o '<h1>[^<]*</h1>'
<h1>Git and GitHub</h1>
ana@dev:~/meta/next$ curl -s http://localhost:3001/ | grep -o '>Git[^<]*</a>'
>Git and GitHub</a>
```

A chamada sem o segredo foi recusada e não mudou nada. Depois da chamada com ele, a página do curso
e a página inicial trazem as duas o título novo, sem timer nenhum envolvido.

**Leia de novo as duas requisições da página do curso: a primeira ainda dizia *Git*.** A
documentação do `revalidateTag` diz que com `{ expire: 0 }` a próxima requisição espera uma
renderização nova; no Next.js 16.4.3, neste computador, a primeira requisição depois da chamada
recebeu a página velha e iniciou a renderização, e a segunda recebeu a nova, exatamente como com uma
idade. É por isso que se confere a promessa de um framework com uma requisição em vez de confiar
nela: uma página que precisa estar certa já na próxima requisição, depois de um pagamento ou de uma
exclusão, não deve depender deste comportamento sem um teste que falhe quando ele não estiver lá.

`s3cret` é um marcador para esta transcrição. Num site de verdade o segredo é um valor longo e
aleatório guardado nas configurações da hospedagem e no programa que chama o endereço, nunca no
código, e a aula 2 de `front-delivery` é sobre onde esses valores moram. Devolva o título depois.
