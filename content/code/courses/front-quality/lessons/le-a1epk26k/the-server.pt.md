---
title: Um servidor com uma conta
version: 1
---

**A API do planner é um arquivo só, escrito com nada além dos módulos do próprio Node, para que cada
linha do que acontece no login esteja diante de você.** Ela tem uma conta, `ana`, com a senha
`correct horse battery staple`, e responde a três endereços: fazer login, sair, e buscar o plano de
quem está logado. Salve como `server/api.mjs`:

```schooling-example
{"language": "javascript", "file": "server/api.mjs", "parts": [{"code": "// server/api.mjs\nimport http from \"node:http\";\nimport { randomBytes, scryptSync, timingSafeEqual } from \"node:crypto\";\nimport { readFileSync } from \"node:fs\";\n\nconst data = JSON.parse(readFileSync(new URL(\"../public/courses.json\", import.meta.url), \"utf8\"));\n", "note": "Os próprios dados do planner, lidos uma vez quando o servidor sobe. Tudo o que este servidor sabe vive na memória, então pará-lo esquece toda mudança, como recarregar a página fazia na aula 1."}, {"code": "const salt = randomBytes(16);\nconst users = new Map([[\"ana\", scryptSync(\"correct horse battery staple\", salt, 32)]]);\nconst plans = new Map([[\"ana\", structuredClone(data)]]);\nconst logins = new Map();\n", "note": "Uma conta, `ana`, cuja senha é guardada como um hash scrypt e nunca como ela mesma. O `plans` mantém as sessões dela separadas das de qualquer outra pessoa, e o `logins` liga cada login a quem o fez."}, {"code": "function passwordIsRight(name, password) {\n  const given = scryptSync(String(password), salt, 32);\n  const stored = users.get(name);\n  return stored !== undefined && timingSafeEqual(stored, given);\n}\n", "note": "Uma senha está certa se o hash dela confere. O hash é calculado até para um nome que não existe, então um nome errado e uma senha errada levam o mesmo tempo, e o `timingSafeEqual` compara num tempo que não depende de quantos bytes coincidem."}, {"code": "function cookie(req, name) {\n  for (const part of (req.headers.cookie ?? \"\").split(\";\")) {\n    const [key, value] = part.trim().split(\"=\");\n    if (key === name) return value;\n  }\n  return undefined;\n}\n", "note": "Lê um cookie do cabeçalho `Cookie` que o navegador manda, que traz todos os cookies deste site como pares `nome=valor` separados por ponto e vírgula."}, {"code": "async function readJson(req) {\n  let text = \"\";\n  for await (const chunk of req) text += chunk;\n  try {\n    return JSON.parse(text);\n  } catch {\n    return {};\n  }\n}\n\nfunction send(res, status, body, headers = {}) {\n  res.writeHead(status, { \"content-type\": \"application/json\", ...headers });\n  res.end(JSON.stringify(body) + \"\\n\");\n}\n", "note": "Dois ajudantes pequenos: ler um corpo JSON, tratando o que não dá para ler como vazio, e mandar uma resposta JSON com um status e os cabeçalhos extras."}, {"code": "export function createApi() {\n  return http.createServer(async (req, res) => {\n    const path = new URL(req.url, \"http://localhost\").pathname;\n    const user = logins.get(cookie(req, \"sid\"));\n", "note": "Toda requisição começa igual: descobrir quem está pedindo, pelo cookie `sid`, se ele aponta para um login de que o servidor se lembra."}, {"code": "    if (req.method === \"POST\" && path === \"/api/login\") {\n      const { name, password } = await readJson(req);\n      if (!passwordIsRight(name, password)) return send(res, 401, { error: \"wrong name or password\" });\n      const sid = randomBytes(32).toString(\"base64url\");\n      logins.set(sid, name);\n      return send(res, 200, { name }, { \"set-cookie\": `sid=${sid}; HttpOnly; SameSite=Lax; Path=/` });\n    }", "note": "O login. Uma senha certa ganha um id de sessão novo, 32 bytes aleatórios, guardado no servidor e mandado ao navegador num cookie que os scripts da página não conseguem ler."}, {"code": "    if (req.method === \"POST\" && path === \"/api/logout\") {\n      return send(res, 200, {}, { \"set-cookie\": \"sid=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0\" });\n    }", "note": "O logout manda o navegador descartar o cookie. Repare no que ele não faz; a aula 6 faz."}, {"code": "    if (req.method === \"GET\" && path === \"/api/plan\") {\n      if (!user) return send(res, 401, { error: \"sign in first\" });\n      return send(res, 200, plans.get(user));\n    }\n    send(res, 404, { error: \"no such address\" });\n  });\n}\n", "note": "O plano, para quem o cookie diz que está pedindo, e um 401 para ninguém. Todo o resto é 404."}, {"code": "if (import.meta.url === `file://${process.argv[1]}`) {\n  createApi().listen(3000, \"127.0.0.1\", () => console.log(\"api listening on http://127.0.0.1:3000\"));\n}", "note": "Escutar na porta 3000 quando o arquivo é rodado com `node`, e não quando um teste o importa, o que a aula 6 faz."}]}
```

**Dois sentidos de "sessão" se encontram neste arquivo**, então o código os mantém separados. Uma
*sessão* de estudo é do planner, uma data e alguns minutos. Um *login* é uma entrada: o id no cookie e a
conta a que ele pertence. Um texto de segurança chamaria o segundo de sessão também, e o nome do cookie
também, `sid`, que este curso mantém porque é o nome que você vai encontrar em toda parte.

Duas linhas, no `package.json` e no `vite.config.ts`, põem o servidor ao lado do app. Um script o sobe:

```
ana@dev:~/planner$ npm pkg set scripts.api="node server/api.mjs"
ana@dev:~/planner$ npm pkg get scripts.api
"node server/api.mjs"
```

E o servidor de desenvolvimento repassa toda requisição em `/api` para ele, então a página e a API
dividem um endereço, `http://localhost:5173`. A aula 7 é sobre por que isso importa. Acrescente o
`server` ao `vite.config.ts`:

```typescript
// vite.config.ts
import { configDefaults, defineConfig } from "vitest/config";

export default defineConfig({
  server: {
    proxy: { "/api": "http://127.0.0.1:3000" },
  },
  test: {
    exclude: [...configDefaults.exclude, "e2e/**"],
  },
});
```

**O servidor escuta só em `127.0.0.1`**, o endereço do próprio computador, então nada na sua rede
consegue alcançá-lo. Um servidor de desenvolvimento nunca precisa de mais, e a aula 8 é sobre do que um
servidor de verdade precisa.

```
ana@dev:~/planner$ npm run api

> planner@0.0.0 api
> node server/api.mjs

api listening on http://127.0.0.1:3000
```
