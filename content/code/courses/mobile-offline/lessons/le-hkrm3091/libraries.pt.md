---
title: As bibliotecas, e o que um CRDT custa
version: 1
---

**Um CRDT paga por nunca perguntar com a história que precisa carregar.** Toda regra de mescla desta
aula funciona porque alguma coisa lembra mais do que o valor atual: uma contagem por aparelho, uma
etiqueta por adição, o id de cliente e a posição de todo item inserido. Essa memória se chama
**metadado**, e os itens apagados de que ela ainda precisa saber são as **lápides** (*tombstones*).
Quanto disso um documento carrega depende do que o app pede à biblioteca, e dá para medir.

## Medido numa sessão

Este programa cria um documento, muda os minutos de `s3` mil vezes, depois acrescenta mil anotações
e apaga todas. Ele imprime o tamanho do documento contra o mesmo dado em JSON. Salve como `costs.ts`
na `~/planner/crdt`:

```typescript
// costs.ts: what a Yjs document weighs after many edits, against the same data as JSON.
import * as Y from "yjs";

// `keep-history` turns off Yjs's garbage collection, which an app does to offer undo or
// to show earlier versions: deleted content is then kept rather than discarded.
const doc = new Y.Doc({ gc: process.argv[2] !== "keep-history" });
doc.clientID = 1;
const s3 = new Y.Map<unknown>();
doc.getMap("sessions").set("s3", s3);
const notes = doc.getArray<string>("notes");
const size = () => Y.encodeStateAsUpdate(doc).length;
const json = () => JSON.stringify({ sessions: doc.getMap("sessions").toJSON(), notes: notes.toJSON() }).length;

s3.set("minutes", 20);
console.log(`fresh               ${String(size()).padStart(6)} bytes as Yjs, ${json()} as JSON`);
for (let m = 1; m <= 1000; m++) s3.set("minutes", m);
console.log(`1000 edits later    ${String(size()).padStart(6)} bytes as Yjs, ${json()} as JSON`);
for (let n = 0; n < 1000; n++) notes.push([`note ${n}`]);
notes.delete(0, 1000);
console.log(`1000 notes, deleted ${String(size()).padStart(6)} bytes as Yjs, ${json()} as JSON`);
```

```
ana@dev:~/planner/crdt$ node costs.ts
fresh                   35 bytes as Yjs, 45 as JSON
1000 edits later        47 bytes as Yjs, 47 as JSON
1000 notes, deleted     61 bytes as Yjs, 47 as JSON
ana@dev:~/planner/crdt$ node costs.ts keep-history
fresh                   35 bytes as Yjs, 45 as JSON
1000 edits later      2983 bytes as Yjs, 47 as JSON
1000 notes, deleted  12887 bytes as Yjs, 47 as JSON
```

Com a coleta de lixo ligada, que é o padrão do Yjs, o documento quase não cresce: mil sobrescritas
custam 12 bytes, e mil anotações apagadas deixam mais 14, porque o Yjs descarta o conteúdo apagado e
junta o que sobra dele. **Com a coleta desligada, as mesmas edições pesam 12.887 bytes** contra 47
bytes de JSON. Essa é a configuração de que um app precisa para oferecer desfazer entre sessões ou
mostrar a versão de ontem, porque as duas coisas exigem que o conteúdo apagado ainda esteja lá.
Multiplique por todo curso e toda semana de um ano, e é a história, não o dado, que enche o banco.

## As bibliotecas

| biblioteca | o que é | onde roda |
|---|---|---|
| **Yjs** | mapas, listas e texto compartilhados, feitos para editores | JavaScript, então React Native e a web; o Yrs é a versão dele em Rust, com ligações para outras linguagens |
| **Automerge** | um documento parecido com JSON com história completa, feito para apps local-first | um núcleo em Rust com pacotes para JavaScript e Swift, entre outros |
| **cr-sqlite** | regras de mescla de CRDT acrescentadas a tabelas SQLite comuns | uma extensão do SQLite, onde o SQLite puder carregar uma |

*Nenhuma das três foi rodada aqui num celular. O Yjs foi rodado no Node, acima; o resto da tabela vem
da documentação de cada projeto.* Os pacotes para Kotlin e Swift mudam mais rápido que este curso,
então confira a página do próprio projeto antes de escolher um para a sua plataforma.

## Quando um CRDT é a ferramenta errada

- **Uma regra que precisa valer em todos os aparelhos.** Dois aparelhos offline podem reservar cada
  um a última vaga; nenhuma mescla desfaz isso depois. Só um servidor consegue recusar.
- **Uma linha em que o mesmo campo raramente muda duas vezes.** As sessões do planner são esse caso:
  o número de versão e a mescla da aula 14 custam um inteiro por linha e guardam os conflitos que não
  resolvem para a pessoa ver. Um CRDT os resolveria em silêncio.
- **Dado que o servidor precisa consultar.** Um documento guardado como bytes não pode ser buscado
  com SQL até ser decodificado; um relatório sobre os minutos de todos os alunos precisa de linhas
  comuns em algum lugar.
- **Permissões.** Todo aparelho que tem o documento pode escrever qualquer parte dele, e o servidor
  recebe bytes mesclados em vez de pedidos que possa aprovar um a um.

**Então recorra a um CRDT onde o dado é texto compartilhado ou uma lista que várias pessoas editam**,
as anotações do planner, e onde toda soma precisa contar, os minutos estudados. Mantenha linhas,
versões e a palavra do servidor para todo o resto.
