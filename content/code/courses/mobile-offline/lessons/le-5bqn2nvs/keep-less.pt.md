---
title: "Guardar menos: o dado de que o planner não precisa"
version: 1
---

**O dado mais barato de proteger é o que nunca foi coletado.** Cada campo que o planner guarda,
envia ou registra em log é mais uma coisa para cifrar, para declarar nas lojas (a próxima seção),
para exportar e apagar quando a pessoa pede, e para explicar depois de um vazamento. A pergunta para
cada um não é "isto poderia ser útil", e sim "o que quebra sem isto".

Feita ao planner, ela tem respostas curtas:

| o planner guarda | precisa? |
|---|---|
| cursos, sessões, datas, minutos, feito | sim: é o app |
| um id de conta | sim: é por ele que o servidor junta as coisas |
| o endereço de e-mail | no servidor, para entrar; no aparelho, não depois da entrada |
| a localização da pessoa quando ela adiciona uma sessão | não: nada no planner a usa |
| os contatos, para sugerir colegas de estudo | não, e seria um recurso com consentimento próprio |
| as anotações livres de uma sessão num relatório de falha | não, e a próxima parte desta seção é esse erro |

## A linha de log que vazou um endereço

Os logs são onde a minimização de dados falha em silêncio, porque ninguém revisa uma linha de log
como dado. Uma sincronização falha, alguém do desenvolvimento quer saber de quem, e escreve a coisa
mais identificadora que tem à mão. A linha vai para um serviço de relatório de falhas, um terceiro,
com cada relatório. Salve isto como `log.ts`:

```typescript
// log.ts: the line the planner writes when a sync fails, as a crash reporter would send it.
import { appendFileSync } from "node:fs";

const account = { id: "acc-0193", email: "ana@example.org", name: "Ana Lima" };
const session = { id: "s5", course: "statistics", notes: "ask about the exam on Friday" };

appendFileSync("app.log",
  `sync failed for ${account.email} (${account.name}): session ${JSON.stringify(session)}\n`);
```

Rode, e depois procure no log qualquer coisa com formato de endereço:

```
ana@dev:~/planner/secrets$ node log.ts
ana@dev:~/planner/secrets$ grep -E -o '[a-z.]+@[a-z.]+' app.log
ana@example.org
ana@dev:~/planner/secrets$ cat app.log
sync failed for ana@example.org (Ana Lima): session {"id":"s5","course":"statistics","notes":"ask about the exam on Friday"}
```

**Uma falha de sincronização, e o relatório levou um nome, um endereço de e-mail e uma anotação
sobre uma prova.** Nada disso ajuda a corrigir uma sincronização: o id da conta e o da sessão dizem
que linhas olhar, e o dado da pessoa já está no servidor para quem tem permissão de olhar. Aqui está
a linha escrita desse jeito, o mesmo arquivo com a última linha trocada:

```typescript
// log.ts: the line the planner writes when a sync fails, as a crash reporter would send it.
import { appendFileSync } from "node:fs";

const account = { id: "acc-0193", email: "ana@example.org", name: "Ana Lima" };
const session = { id: "s5", course: "statistics", notes: "ask about the exam on Friday" };

// An id says which row to look at. The address, the name and the notes are not needed to fix a sync.
appendFileSync("app.log", `sync failed for account ${account.id}: session ${session.id}\n`);
```

```
ana@dev:~/planner/secrets$ node log.ts
ana@dev:~/planner/secrets$ grep -E -c '[a-z.]+@[a-z.]+' app.log
0
ana@dev:~/planner/secrets$ cat app.log
sync failed for account acc-0193: session s5
```

**O mesmo `grep`, rodado como verificação antes de cada versão, pega o próximo.** Um padrão para um
endereço, um telefone ou o formato de um token tem poucos caracteres, e ele roda sobre os logs que
uma suíte de testes produziu. Ele não consegue provar que um log está limpo; ele acha, sem falhar, o
erro que esta seção cometeu.
