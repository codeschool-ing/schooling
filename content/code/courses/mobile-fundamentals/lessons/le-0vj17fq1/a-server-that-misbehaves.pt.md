---
title: Um servidor que se comporta mal de propósito
version: 1
---

**Para ver o que um app faz quando a rede dá errado, você precisa de uma rede que dê errado quando
você pede.** Um elevador é difícil de arranjar na mesa de trabalho. Um servidor que responde
atrasado, que nunca responde, ou que falha algumas vezes antes de funcionar cabe em vinte linhas de
Node.js, e produz os mesmos três sintomas que um celular encontra na rua. Ele roda no seu próprio
computador, na porta 8014, e nada fora dele consegue alcançá-lo.

Ele serve a semana do planner, as mesmas cinco sessões com que a aula 1 terminou, e responde em
quatro caminhos:

| caminho | o que faz | o que representa |
|---|---|---|
| `/week` | responde na hora com os totais da semana | um dia bom |
| `/slow` | responde o mesmo, três segundos atrasado | um sinal fraco, ou um servidor ocupado |
| `/hang` | lê a requisição e nunca responde | o elevador: a requisição saiu, e nada volta |
| `/flaky` | falha duas chamadas em cada três com status 503, e responde a terceira | um servidor reiniciando, ou sobrecarregado por um instante |

Salve-o em `~/planner` como `api.ts`:

```typescript
// api.ts: a small server for the planner's week, and three ways for it to misbehave
import { createServer } from "node:http";
import { weekTotal, type Plan } from "./planner.ts";

const plan: Plan = {
  courses: [
    { id: "sql", title: "SQL Databases" },
    { id: "mobile", title: "Mobile Fundamentals" },
  ],
  sessions: [
    { id: "s1", courseId: "sql", date: "2026-10-19", minutes: 50, done: true },
    { id: "s2", courseId: "mobile", date: "2026-10-20", minutes: 40, done: true },
    { id: "s3", courseId: "sql", date: "2026-10-23", minutes: 60, done: false },
    { id: "s4", courseId: "mobile", date: "2026-10-27", minutes: 45, done: false },
    { id: "s5", courseId: "mobile", date: "2026-10-22", minutes: 30, done: true },
  ],
};
let flaky = 0; // how many times /flaky has been asked since the server started

createServer((req, res) => {
  const path = new URL(req.url ?? "/", "http://localhost").pathname;
  console.log(req.method, path);
  const send = (status: number, body: unknown) => {
    res.writeHead(status, { "content-type": "application/json" });
    res.end(JSON.stringify(body));
  };
  const week = () => send(200, weekTotal(plan, "2026-10-21"));

  if (path === "/week") return week();
  if (path === "/slow") return void setTimeout(week, 3000); // answers, three seconds late
  if (path === "/hang") return; // reads the request and never answers it
  if (path === "/flaky") return ++flaky % 3 !== 0 ? send(503, { error: "busy" }) : week();
  send(404, { error: "no such path" });
}).listen(8014, "127.0.0.1", () => console.log("listening on http://127.0.0.1:8014"));
```

**`/hang` é uma linha só, e é a mais importante.** O handler retorna sem escrever nada, então a
conexão fica aberta, a requisição chegou, e a resposta nunca começa. É exatamente assim que uma
requisição enviada de dentro de um elevador parece do lado do celular. Nada ali é um erro, e nada no
Node.js vai fechá-la por um bom tempo, como a próxima etapa mede.

O `127.0.0.1` no `listen` mantém o servidor no seu próprio computador: outra máquina no seu Wi-Fi
não consegue alcançá-lo. O status 503 quer dizer *service unavailable*, serviço indisponível, a
resposta que um servidor dá quando está temporariamente sem condições de fazer o trabalho, e a que
o cliente tem permissão para tentar de novo.

## Dois terminais

**Um servidor roda até você pará-lo**, então ele precisa de um terminal só dele. Inicie-o num
terminal e deixe esse terminal em paz; abra um segundo para todo o resto. Conforme as requisições
chegam, o primeiro terminal imprime uma linha para cada uma. Foi isto que ele mostrou até o fim
desta etapa e das duas seguintes:

```
ana@dev:~/planner$ node api.ts
listening on http://127.0.0.1:8014
GET /week
GET /slow
GET /flaky
GET /flaky
GET /flaky
GET /hang
GET /hang
GET /hang
GET /hang
GET /slow
GET /slow
GET /flaky
GET /flaky
GET /flaky
GET /flaky
```

Cada `GET /hang` nesse log é uma requisição que nunca recebeu resposta. O servidor não caiu e não
reclamou. Ele simplesmente manteve a conexão aberta, e cabe ao cliente decidir quanto tempo esperar.

## Perguntando com o curl

No segundo terminal, o `curl` pergunta a cada caminho. O `-sS` esconde o medidor de progresso do
curl e ainda mostra um erro, e o `-w` imprime, depois do corpo, o código de status e quanto tempo a troca inteira levou:

```
ana@dev:~/planner$ curl -sS -w "  %{http_code} in %{time_total} s\n" http://127.0.0.1:8014/week
{"monday":"2026-10-19","planned":180,"done":120}  200 in 0.002107 s
ana@dev:~/planner$ curl -sS -w "  %{http_code} in %{time_total} s\n" http://127.0.0.1:8014/slow
{"monday":"2026-10-19","planned":180,"done":120}  200 in 3.003513 s
ana@dev:~/planner$ curl -sS -w "  %{http_code} in %{time_total} s\n" http://127.0.0.1:8014/flaky
{"error":"busy"}  503 in 0.002077 s
ana@dev:~/planner$ curl -sS -w "  %{http_code} in %{time_total} s\n" http://127.0.0.1:8014/flaky
{"error":"busy"}  503 in 0.001430 s
ana@dev:~/planner$ curl -sS -w "  %{http_code} in %{time_total} s\n" http://127.0.0.1:8014/flaky
{"monday":"2026-10-19","planned":180,"done":120}  200 in 0.001318 s
ana@dev:~/planner$ curl -sS --max-time 3 -w "  %{http_code} in %{time_total} s\n" http://127.0.0.1:8014/hang; echo "exit $?"
curl: (28) Operation timed out after 3002 milliseconds with 0 bytes received
  000 in 3.002319 s
exit 28
```

O `/week` respondeu em poucos milissegundos, o `/slow` em pouco mais de três segundos, e o `/flaky`
falhou duas vezes antes de responder na terceira chamada. Para o `/hang` a transcrição dá ao curl um
limite, `--max-time 3`, e o curl desistiu e disse isso com o código de saída 28, *operation timed
out*. **Sem o `--max-time`, aquele comando ainda estaria esperando**, porque o curl não põe limite
numa transferência inteira a menos que alguém peça. Os tempos no seu computador vão diferir destes
nos últimos dígitos. O que não muda é qual responde, qual falha e qual nunca termina.
