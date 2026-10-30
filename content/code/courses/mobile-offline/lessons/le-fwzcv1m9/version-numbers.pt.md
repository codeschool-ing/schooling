---
title: Números de versão, e a escrita que diz o que leu
version: 1
---

**Uma escrita que diz de qual versão partiu deixa o servidor ver um conflito em vez de adivinhá-lo.**
A aula 13 terminou na pergunta que nenhum relógio respondia: quem escreveu por segundo tinha visto a
primeira escrita? Um número de versão responde numa comparação. Toda linha carrega um número, o
servidor o aumenta a cada escrita que aceita, e um aparelho devolve o número que leu. Se o número
andou nesse meio-tempo, alguém escreveu antes, e o aparelho não sabia.

Isso é **concorrência otimista**: ninguém trava a linha enquanto edita, porque num celular offline
por uma hora uma trava ficaria presa por uma hora. As escritas podem seguir em frente, e a rara que
colide é pega quando chega.

## Um servidor que confere a versão

O servidor abaixo guarda uma sessão, `s3`, na versão 1. O `GET` a devolve; o `PUT` só aceita uma
cópia nova se ela citar a versão que o servidor tem, e responde **409 Conflict** se não. A resposta traz a linha atual no corpo, para o aparelho não precisar de uma segunda requisição para ver o que mudou. Crie a
pasta `~/planner/versions` e salve isto nela como `server.ts`:

```typescript
// server.ts: sessions with a version number; a write must name the version it read.
import { createServer } from "node:http";

type Session = { id: string; course: string; date: string; minutes: number; done: boolean; version: number };
const sessions = new Map<string, Session>([
  ["s3", { id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: false, version: 1 }],
]);

createServer(async (req, res) => {
  const send = (status: number, body: unknown) => {
    res.writeHead(status, { "content-type": "application/json" });
    res.end(JSON.stringify(body) + "\n");
  };
  const id = req.url?.match(/^\/sessions\/(\w+)$/)?.[1] ?? "";
  const current = sessions.get(id);
  if (!current) return send(404, { error: "no such session" });
  if (req.method === "GET") return send(200, current);
  if (req.method !== "PUT") return send(405, { error: "GET or PUT" });

  let raw = "";
  for await (const chunk of req) raw += chunk;
  const write = JSON.parse(raw) as Session;
  if (write.version !== current.version) {
    return send(409, { error: `you read version ${write.version}, the server has ${current.version}`, current });
  }
  const { version: _read, ...fields } = write;
  const next = { id, ...fields, version: current.version + 1 };
  sessions.set(id, next);
  send(200, next);
}).listen(8014, () => console.log("sessions on http://localhost:8014"));
```

Inicie-o num terminal só dele e deixe rodando; `Ctrl+C` o para. Aqui ele foi parado depois de um
segundo, para mostrar a linha que imprime:

```
ana@dev:~/planner/versions$ timeout 1 node server.ts
sessions on http://localhost:8014
```

Num segundo terminal, encene a manhã da aula 13 com `curl`. O tablet lê a linha e manda a marcação
com a versão que leu. O celular, que leu a mesma versão 1 antes de ficar offline, manda os 30
minutos dele:

```
ana@dev:~/planner/versions$ curl -s http://localhost:8014/sessions/s3
{"id":"s3","course":"guitar","date":"2026-10-21","minutes":20,"done":false,"version":1}
ana@dev:~/planner/versions$ curl -s -X PUT http://localhost:8014/sessions/s3 -d '{"course":"guitar","date":"2026-10-21","minutes":20,"done":true,"version":1}' -w '%{http_code}\n'
{"id":"s3","course":"guitar","date":"2026-10-21","minutes":20,"done":true,"version":2}
200
ana@dev:~/planner/versions$ curl -s -X PUT http://localhost:8014/sessions/s3 -d '{"course":"guitar","date":"2026-10-21","minutes":30,"done":false,"version":1}' -w '%{http_code}\n'
{"error":"you read version 1, the server has 2","current":{"id":"s3","course":"guitar","date":"2026-10-21","minutes":20,"done":true,"version":2}}
409
```

**A escrita do celular foi recusada, e ele soube por quê.** Essa é a diferença inteira para a
última escrita vence: o servidor não substitui mais a linha do tablet, e o celular fica sabendo, na
resposta, que a versão 2 existe e o que ela diz. O `-w '%{http_code}\n'` no fim de cada `curl`
imprime o status depois do corpo.

## O que a versão não faz

Um 409 é uma pergunta devolvida ao aparelho, não uma resposta. O celular ainda tem os 30 minutos e
agora tem também a linha do servidor; precisa decidir o que mandar em seguida. Mandar a cópia de
novo com a versão 2 seria a última escrita vence com uma ida e volta a mais, e perderia a marcação.
A seção depois da próxima mescla as duas direito.

O HTTP tem uma grafia padrão para a mesma conferência. O servidor manda a versão no cabeçalho
`ETag`, e o cliente a devolve em `If-Match`; uma divergência é **412 Precondition Failed**. O curso
usa um campo no corpo porque a caixa de saída da aula 8 guarda operações em JSON, e a versão
pertence à operação. De um jeito ou de outro a regra é a mesma: a escrita carrega o que leu.
