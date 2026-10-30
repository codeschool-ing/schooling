---
title: Ids criados no aparelho
version: 1
---

**Uma linha criada offline precisa de um id antes de o servidor vê-la, então o aparelho tem de
criar um que nenhum outro aparelho consiga criar.** `INTEGER PRIMARY KEY AUTOINCREMENT` é o que a
maioria das pessoas pega, e é a única escolha que não tem como funcionar: um contador é único num
banco, e uma pessoa com um celular e um tablet tem dois.

O programa abaixo dá a dois aparelhos as mesmas seis sessões, o estado depois da última
sincronização, e então cada um adiciona mais uma offline, o celular uma sessão de Estatística e o
tablet uma de Violão. Uma vez com ids de um contador, outra com UUIDs. Salve como `ids.ts` na
`~/planner/model`:

```typescript
// ids.ts: two devices each add a session while offline, with ids from a counter and with UUIDs.
import Database from "better-sqlite3";
import { randomUUID } from "node:crypto";

type Kind = "counter" | "uuid";

// A device's sessions table, and its function for adding one: it returns the id the row got.
function device(kind: Kind): (course: string) => string {
  const db = new Database(":memory:");
  if (kind === "counter") {
    db.exec("CREATE TABLE sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, course TEXT NOT NULL)");
    const add = db.prepare("INSERT INTO sessions (course) VALUES (?)");
    return (course) => String(add.run(course).lastInsertRowid);
  }
  db.exec("CREATE TABLE sessions (id TEXT PRIMARY KEY, course TEXT NOT NULL)");
  const add = db.prepare("INSERT INTO sessions (id, course) VALUES (?, ?)");
  return (course) => {
    const id = randomUUID();
    add.run(id, course);
    return id;
  };
}

for (const kind of ["counter", "uuid"] as Kind[]) {
  const phone = device(kind);
  const tablet = device(kind);
  for (let n = 0; n < 6; n++) { phone("spanish"); tablet("spanish"); } // the six both already had
  const a = phone("statistics"); // offline, on the phone
  const b = tablet("guitar"); // offline, on the tablet, the same evening
  const detail = kind === "counter" ? `phone ${a}, tablet ${b}` : `${a.length} characters each`;
  console.log(`${kind.padEnd(7)}: statistics and guitar get ${a === b ? "the same id" : "different ids"} (${detail})`);
}
```

```
ana@dev:~/planner/model$ node ids.ts
counter: statistics and guitar get the same id (phone 7, tablet 7)
uuid   : statistics and guitar get different ids (36 characters each)
```

**Os dois aparelhos chamaram a sessão nova de 7.** Quando sincronizam, o servidor recebe duas
sessões diferentes sob um id só, e a que chega em segundo ou sobrescreve a primeira ou é recusada.
De um jeito ou de outro, uma sessão que a pessoa digitou some ou fica presa, e nada em nenhuma das
telas diz isso. Com UUIDs os dois ids diferem, e o servidor consegue guardar os dois. O programa
imprime o tamanho em vez dos ids, porque o `randomUUID` cria um novo a cada execução e a transcrição
precisa se repetir; os seus vão ser outros 36 caracteres.

## O que é um UUID, e de que tipo

`crypto.randomUUID()` devolve um UUID versão 4: 122 bits aleatórios escritos como 36 caracteres. A
chance de dois aparelhos criarem o mesmo é pequena o bastante para nenhum planner jamais ver isso.
Toda plataforma tem a mesma chamada: `UUID.randomUUID()` em Kotlin, `UUID()` em Swift e
`Crypto.randomUUID()` do `expo-crypto` no React Native.

Ids aleatórios têm um custo num aparelho: linhas consecutivas caem em lugares aleatórios do índice
da chave primária, então as inserções tocam mais páginas do que tocariam com uma chave sempre
crescente. A **versão 7**, definida na RFC 9562 em 2024, põe um timestamp em milissegundos nos
primeiros 48 bits e aleatoriedade no resto, então ids criados um depois do outro se ordenam um
depois do outro. O Node 22 não tem uma função pronta para ela; bibliotecas têm, e a escolha entre as
duas é uma medição para uma tabela grande, não uma regra.

## E os ids do próprio servidor

Algumas APIs insistem em criar o id elas mesmas. O aparelho então guarda dois: o próprio, criado
offline e usado em toda referência local, e o do servidor, guardado ao lado quando a primeira
sincronização responde. A caixa de saída da aula 8 precisa levar o id local exatamente por isso,
para que a resposta possa ser casada com a linha que perguntou.
