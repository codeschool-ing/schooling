---
title: Uma sincronização que pode parar em qualquer passo
version: 1
---

**Uma sincronização em segundo plano precisa ser escrita para ser interrompida: ela faz um passo por
vez, salva depois de cada um e lê na próxima execução onde a anterior parou.** As três seções de
plataforma terminaram na mesma exigência com três grafias: uma corrotina cancelada, um
`expirationHandler`, uma tarefa que o sistema para. Nenhuma diz à sincronização com antecedência
quanto tempo ela tem. Então o programa não consegue planejar o trabalho para caber; só consegue
fazer de cada ponto entre dois passos um lugar seguro para parar.

Este programa é essa sincronização, com o sistema representado por dois argumentos. O primeiro é
quantos passos esta execução ganha; o segundo, se vier, é um passo durante o qual o processo é morto
de vez, como um celular Android ou o iOS faz com um app que passa do tempo. A caixa de saída de seis
edições e o cursor de puxada moram no SQLite, em `background.db`, então sobrevivem de uma execução
para a outra exatamente como sobreviveriam de uma abertura em segundo plano para a outra. O lado do
servidor é feito por uma tabela no mesmo arquivo, `received`, que lembra a chave de idempotência de
toda operação que recebeu, como o servidor da aula 10 faz. Crie a pasta `~/planner/background` e
salve isto nela como `bg.ts`:

```typescript
// bg.ts: a sync that does what it can in the steps it is given, and resumes where it stopped.
import Database from "better-sqlite3";

const db = new Database("background.db");
db.exec(`
  create table if not exists outbox (seq integer primary key, key text not null, op text not null, sent integer not null default 0);
  create table if not exists state (name text primary key, value integer not null);
  create table if not exists received (key text primary key); -- the server's side, played here
`);
// The first run finds the week's edits waiting, as lesson 8's outbox would hold them.
if (!db.prepare("select 1 from outbox").get()) {
  const add = db.prepare("insert into outbox (key, op) values (?, ?)");
  for (const [key, op] of [["k1", "add session s7"], ["k2", "mark s3 done"], ["k3", "set s5 to 50 minutes"],
    ["k4", "add session s8"], ["k5", "delete session s6"], ["k6", "mark s4 done"]]) add.run(key, op);
}
const serverChanges = ["c1", "c2", "c3", "c4", "c5"]; // what the server has for this device to pull

const steps = Number(process.argv[2] ?? 3); // what the system grants this run
const killAt = Number(process.argv[3] ?? 0); // a step during which the system kills the process
const cursor = () => (db.prepare("select value from state where name = 'cursor'").get() as { value: number } | undefined)?.value ?? 0;

console.log(`run with ${steps} steps` + (killAt ? `, killed during step ${killAt}` : ""));
for (let step = 1; step <= steps; step++) {
  const next = db.prepare("select seq, key, op from outbox where sent = 0 order by seq").get() as
    { seq: number; key: string; op: string } | undefined;
  if (next) {
    const fresh = db.prepare("insert or ignore into received (key) values (?)").run(next.key).changes === 1;
    if (step === killAt) {
      console.log(`  step ${step}: sent ${next.key}, killed before it was marked sent`);
      process.kill(process.pid, "SIGKILL"); // what the system does: no warning, no cleanup
    }
    db.prepare("update outbox set sent = 1 where seq = ?").run(next.seq); // the checkpoint
    console.log(`  step ${step}: sent ${next.key} ${next.op}` + (fresh ? "" : " (the server had it: ignored)"));
    continue;
  }
  const from = cursor();
  if (from >= serverChanges.length) {
    console.log(`  step ${step}: nothing left to do`);
    break;
  }
  const page = serverChanges.slice(from, from + 2);
  db.prepare("insert into state (name, value) values ('cursor', ?) on conflict (name) do update set value = excluded.value")
    .run(from + page.length); // the checkpoint for pulls
  console.log(`  step ${step}: pulled ${page.join(", ")}, cursor ${from} -> ${from + page.length}`);
}
const left = (db.prepare("select count(*) as n from outbox where sent = 0").get() as { n: number }).n;
console.log(`stopped: ${left} to send, pull cursor at ${cursor()}`);
```

Há dois pontos de salvamento, e os dois estão marcados em comentários. Depois que uma operação é
mandada, a linha dela é marcada como enviada; depois que uma página é puxada, o cursor anda. Num app,
as linhas puxadas e o novo cursor vão numa transação só, como a aula 11 os grava, para a página e o
cursor nunca discordarem.

## Quatro execuções

A primeira execução ganha quatro passos, a segunda três mas é morta no segundo passo, e as duas
últimas ganham quantos quiserem:

```
ana@dev:~/planner/background$ node bg.ts 4
run with 4 steps
  step 1: sent k1 add session s7
  step 2: sent k2 mark s3 done
  step 3: sent k3 set s5 to 50 minutes
  step 4: sent k4 add session s8
stopped: 2 to send, pull cursor at 0
ana@dev:~/planner/background$ node bg.ts 3 2; echo "exit status $?"
run with 3 steps, killed during step 2
  step 1: sent k5 delete session s6
  step 2: sent k6, killed before it was marked sent
bash: line 1: 30438 Killed                  node bg.ts 3 2
exit status 137
ana@dev:~/planner/background$ node bg.ts 10
run with 10 steps
  step 1: sent k6 mark s4 done (the server had it: ignored)
  step 2: pulled c1, c2, cursor 0 -> 2
  step 3: pulled c3, c4, cursor 2 -> 4
  step 4: pulled c5, cursor 4 -> 5
  step 5: nothing left to do
stopped: 0 to send, pull cursor at 5
ana@dev:~/planner/background$ node bg.ts 10
run with 10 steps
  step 1: nothing left to do
stopped: 0 to send, pull cursor at 5
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l16-runs\" aria-label=\"Quatro execuções da sincronização, uma por linha, cada caixa um passo. Execução 1, quatro passos: manda k1, k2, k3, k4, e o tempo acaba. Execução 2, três passos: manda k5; durante o segundo passo k6 chega ao servidor e o processo é morto antes de a caixa de saída marcá-lo como enviado. Execução 3: manda k6 de novo, que o servidor ignora, depois puxa c1 e c2, c3 e c4, c5, e não acha mais nada. Execução 4: nada a fazer, em um passo. Um ponto de salvamento segue cada passo concluído.\"><text x=\"20\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">execução 1</text><rect x=\"110\" y=\"20\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"158.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">k1</text><rect x=\"220\" y=\"20\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"268.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">k2</text><rect x=\"330\" y=\"20\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"378.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">k3</text><rect x=\"440\" y=\"20\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"488.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">k4</text><text x=\"554\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">tempo acabou</text><text x=\"20\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">execução 2</text><rect x=\"110\" y=\"64\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"158.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">k5</text><rect x=\"220\" y=\"64\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"268.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">k6</text><text x=\"334\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">morto</text><text x=\"20\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">execução 3</text><rect x=\"110\" y=\"108\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"158.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">k6, ignorado</text><rect x=\"220\" y=\"108\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"268.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">c1, c2</text><rect x=\"330\" y=\"108\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"378.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">c3, c4</text><rect x=\"440\" y=\"108\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"488.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">c5</text><rect x=\"550\" y=\"108\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"598.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nada a fazer</text><text x=\"20\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">execução 4</text><rect x=\"110\" y=\"152\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"158.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nada a fazer</text><text x=\"110\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">cada passo concluído é salvo antes de o próximo começar</text></svg>", "caption": "Ser parado custa no máximo um passo: o que estava em andamento quando veio a morte, mandado de novo e ignorado pela chave de idempotência do servidor."}
```

Leia a segunda e a terceira execuções juntas. **A morte veio depois de `k6` chegar ao servidor e
antes de a caixa de saída saber**, que é o pior momento que existe: o trabalho foi feito e o
registro dele não. A execução seguinte então mandou `k6` de novo, e o servidor, achando a chave já
recebida, a ignorou. Sem a chave, o planner teria agora `s4` marcada como feita duas vezes, ou, para
uma operação que acrescenta uma sessão, duas sessões. O programa fez o papel do sistema mandando a
si mesmo um `SIGKILL`, o sinal que nem o Android nem o iOS deixam um app capturar. O `137` é o status
que um shell informa para um processo que morreu disso, embaixo da linha `Killed` do próprio shell
com o ID do processo, que vai ser outro na sua máquina. Nada no programa teve chance de arrumar a
casa, e nada precisava.

O lado da puxada nunca precisou ser refeito: cada página andou com o cursor, e a execução seguinte
começou dele. E a quarta execução não achou nada para fazer e disse isso em um passo, que é o caso
que uma execução em segundo plano encontra mais vezes e em que deveria gastar menos.

## O que o programa deixa para a plataforma

- **Quando rodar.** O orçamento de passos aqui é um argumento. Num celular, são os dez minutos do
  WorkManager, os trinta segundos do iOS, ou o que o sistema permitir antes de cancelar.
- **A rede.** Todo passo aqui dá certo. Um passo de verdade falha, e a nova tentativa e o recuo da
  aula 9 decidem o que acontece em seguida, dentro do orçamento.

O que ele não deixa para ninguém é a forma: passos pequenos, um ponto de salvamento depois de cada
um, envios idempotentes. **Com essa forma, ser parado custa um passo repetido; sem ela, ser parado
custa a execução.**
