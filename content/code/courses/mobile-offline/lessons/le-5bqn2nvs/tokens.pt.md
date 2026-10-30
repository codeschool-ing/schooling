---
title: "Tokens: de vida curta, guardados no cofre de chaves e apagados na saída"
version: 1
---

**O único segredo que um celular precisa guardar é o que prova quem a pessoa é, e ele é construído
para valer o mínimo possível se vazar.** Uma senha não é guardada: ela é digitada uma vez, enviada
uma vez e trocada por dois tokens. Nenhum dos dois é a senha, e cada um tem uma função.

| token | vive | guardado | se vazar |
|---|---|---|---|
| **token de acesso** | minutos; quinze é uma escolha comum | na memória, ou no cofre de chaves | funciona até expirar, e depois não vale nada |
| **token de renovação** | dias ou meses | no Android Keystore ou no Keychain do iOS, nunca em preferências ou num arquivo | o servidor pode revogá-lo, e a rotação mostra que ele foi copiado |

O token de acesso vai em toda requisição. O token de renovação só vai ao servidor para conseguir um
novo token de acesso, e o servidor o **rotaciona**: cada uso devolve um token de renovação novo e
gasta o antigo. Um token de renovação copiado serve então no máximo uma vez, e o segundo uso dele,
por quem ficou com o gasto, é um sinal sobre o qual o servidor pode agir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l20-tokens\" aria-label=\"Uma linha do tempo da entrada à saída. A senha é digitada uma vez, na entrada, e trocada por um token de acesso e um token de renovação. Cada token de acesso vive pouco; quando um expira, a próxima requisição recebe um 401, e o cliente gasta o token de renovação por um par novo, então cada token de renovação é usado uma vez. Na saída, o servidor revoga o último token de renovação e o aparelho apaga os tokens, o banco e o cache.\"><defs><marker id=\"l20-tokens-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M60 40 L60 218\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"66\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">entrada</text><text x=\"66\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">senha, digitada uma vez</text><text x=\"66\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">token de acesso</text><text x=\"66\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">token de renovação</text><rect x=\"66\" y=\"110\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"66\" y=\"176\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"236\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">401: expirou</text><text x=\"166\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">gasto, renovado</text><path d=\"M236 140 L264 172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-tokens-ah-paper-dim)\"></path><rect x=\"266\" y=\"110\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"266\" y=\"176\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"436\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">401: expirou</text><text x=\"366\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">gasto, renovado</text><path d=\"M436 140 L464 172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-tokens-ah-paper-dim)\"></path><rect x=\"466\" y=\"110\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"466\" y=\"176\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><path d=\"M40 228 L690 228\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-tokens-ah-paper-dim)\"></path><text x=\"690\" y=\"242\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tempo</text><path d=\"M670 60 L670 218\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"664\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">saída: revogar, depois apagar</text></svg>", "caption": "Nenhum dos dois tokens é a senha. O que vive muito é usado uma vez por vez, e a saída acaba com os dois, no servidor e no celular."}
```

## O servidor do planner, e o cliente dele

O servidor deixa a pessoa entrar, entrega os tokens e só responde a `/tip` com um token de acesso
válido, acrescentando do lado dele a chave do serviço de dicas. A chave vem do ambiente do servidor.
Salve na `~/planner/secrets` como `server.ts`:

```typescript
// server.ts: the planner's own server, on port 8020. It signs people in, hands out short-lived
// access tokens, and is the only place the tips service's key exists.
import { createServer } from "node:http";
import { randomBytes } from "node:crypto";

const TIPS_KEY = process.env.TIPS_API_KEY; // from the server's environment, never from the app
const TTL = Number(process.env.ACCESS_TTL ?? 900); // seconds an access token lives
const access = new Map<string, number>(); // token -> when it expires
const refresh = new Set<string>();
const token = () => randomBytes(24).toString("base64url");

// Stands in for the third-party service the key unlocks: it knows its own key.
const tipsService = (key: string | undefined, course: string) =>
  key === "tips_live_4f9c2a7e1b6d83a0" ? `${course}: review yesterday's mistakes first` : "refused: bad key";

function issue() {
  const a = token(), r = token();
  access.set(a, Date.now() + TTL * 1000);
  refresh.add(r);
  return { access: a, refresh: r, expiresIn: TTL };
}

createServer(async (req, res) => {
  let body = "";
  for await (const chunk of req) body += chunk;
  const url = new URL(req.url!, "http://localhost");
  const send = (status: number, value: unknown) => {
    console.log(`${req.method} ${url.pathname} -> ${status}`);
    res.writeHead(status, { "Content-Type": "application/json" }).end(JSON.stringify(value));
  };
  if (url.pathname === "/token") return send(200, issue()); // a real one checks the password
  if (url.pathname === "/refresh") {
    const old = JSON.parse(body).refresh;
    if (!refresh.delete(old)) return send(401, { error: "refresh token not valid" });
    return send(200, issue()); // rotated: the old refresh token is spent
  }
  if (url.pathname === "/revoke") {
    refresh.delete(JSON.parse(body).refresh);
    return send(200, { revoked: true });
  }
  if (url.pathname === "/tip") {
    const a = (req.headers.authorization ?? "").replace("Bearer ", "");
    if ((access.get(a) ?? 0) < Date.now()) return send(401, { error: "access token expired or unknown" });
    return send(200, { tip: tipsService(TIPS_KEY, url.searchParams.get("course") ?? "") });
  }
  send(404, { error: "no such route" });
}).listen(8020, "127.0.0.1");
```

O cliente guarda os dois tokens em `keystore/`, uma pasta no papel do Keystore ou do Keychain da
plataforma, onde as listagens de plataforma da aula 19 os poriam. Quando o servidor responde 401,
ele renova uma vez e pede de novo. Salve como `client.ts`:

```typescript
// client.ts: the planner's side of signing in, asking for a tip, and signing out.
// usage: node client.ts signin | node client.ts tip COURSE | node client.ts signout
import { mkdirSync, writeFileSync, readFileSync, existsSync, rmSync } from "node:fs";

const SERVER = "http://127.0.0.1:8020";
// keystore/ stands in for the Android Keystore or the iOS Keychain.
const keep = (name: string, value: string) => {
  mkdirSync("keystore", { recursive: true });
  writeFileSync(`keystore/${name}`, value);
};
const read = (name: string) => (existsSync(`keystore/${name}`) ? readFileSync(`keystore/${name}`, "utf8") : "");
const post = async (path: string, body: object) =>
  (await fetch(`${SERVER}${path}`, { method: "POST", body: JSON.stringify(body) })).json();
const ask = (course: string) =>
  fetch(`${SERVER}/tip?course=${course}`, { headers: { Authorization: `Bearer ${read("access")}` } });

const [cmd, arg] = process.argv.slice(2);
if (cmd === "signin") {
  const t = await post("/token", { email: "ana@example.org", password: "what the person typed" });
  keep("access", t.access);
  keep("refresh", t.refresh);
  console.log(`signed in: an access token for ${t.expiresIn} s, and a refresh token in the keystore`);
} else if (cmd === "tip") {
  let res = await ask(arg);
  if (res.status === 401 && read("refresh")) {
    console.log("401: the access token has expired, refreshing it");
    const t = await post("/refresh", { refresh: read("refresh") });
    keep("access", t.access);
    keep("refresh", t.refresh);
    res = await ask(arg);
  }
  console.log(`${res.status} ${JSON.stringify(await res.json())}`);
} else if (cmd === "signout") {
  await post("/revoke", { refresh: read("refresh") });
  for (const path of ["keystore", "planner.db", "cache"]) {
    if (existsSync(path)) {
      rmSync(path, { recursive: true });
      console.log(`removed ${path}`);
    }
  }
}
```

Para a captura, o servidor é iniciado com um token de acesso que vive **um segundo**, para a
expiração aparecer sem esperar quinze minutos:
`TIPS_API_KEY=tips_live_4f9c2a7e1b6d83a0 ACCESS_TTL=1 node server.ts`, num terminal só dele. Depois
entre, peça, espere dois segundos, peça de novo e saia:

```
ana@dev:~/planner/secrets$ node client.ts signin
signed in: an access token for 1 s, and a refresh token in the keystore
ana@dev:~/planner/secrets$ node client.ts tip statistics
200 {"tip":"statistics: review yesterday's mistakes first"}
ana@dev:~/planner/secrets$ sleep 2
ana@dev:~/planner/secrets$ node client.ts tip guitar
401: the access token has expired, refreshing it
200 {"tip":"guitar: review yesterday's mistakes first"}
ana@dev:~/planner/secrets$ node client.ts signout
removed keystore
removed planner.db
removed cache
ana@dev:~/planner/secrets$ node client.ts tip statistics
401 {"error":"access token expired or unknown"}
```

E o que o servidor viu:

```
ana@dev:~/planner/secrets$ TIPS_API_KEY=tips_live_4f9c2a7e1b6d83a0 ACCESS_TTL=1 node server.ts
POST /token -> 200
GET /tip -> 200
GET /tip -> 401
POST /refresh -> 200
GET /tip -> 200
POST /revoke -> 200
GET /tip -> 401
```

**O 401 depois da pausa foi o token de acesso expirando, e o cliente se recuperou sem a pessoa
notar**: uma renovação, uma nova tentativa, um par novo de tokens. Depois da saída, o mesmo pedido
foi recusado, porque o cliente não tinha mais nada a mandar e o servidor tinha revogado o token de
renovação.

## A saída apaga o aparelho

Sair da conta é o momento em que a pessoa entrega o celular a outra, ou o vende. Então a saída
remove **tudo o que a conta pôs ali**: os tokens, o banco, o cache, os arquivos baixados da aula 18.
O cliente acima remove três deles, e imprimiu cada um. Duas regras o tornam confiável:

- **Revogue no servidor primeiro**, para um token copiado antes parar de funcionar mesmo se a
  limpeza for interrompida.
- **Apague mesmo quando o servidor estiver fora de alcance.** Quem sai da conta num túnel espera
  ter saído. A revogação pode ir para a caixa de saída da aula 8; a limpeza não pode esperar por
  ela.

Uma coisa cabe à pessoa decidir: sessões ainda esperando na caixa de saída. Apagá-las perde
trabalho; mantê-las deixa o dado de uma pessoa para a próxima. O planner pergunta, dizendo quantas
são, antes de apagar.
