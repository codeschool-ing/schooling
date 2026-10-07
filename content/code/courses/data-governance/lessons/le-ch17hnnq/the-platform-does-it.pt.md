---
title: A mesma ideia, dentro de um programa
version: 1
---

Contratos não são só para dados que saem de uma empresa. A plataforma em que você estuda aplica a mesma
ideia entre as partes de um único programa, e o motivo é o mesmo com que esta aula começou: uma mudança
num lugar nunca deve quebrar outro lugar em silêncio.

O código dela é dividido em **módulos**, cada um dono das suas tabelas, e uma regra é garantida por um
teste que roda a cada mudança:

```go
// The dependency graph between modules, enforced rather than agreed.
//
// IT EXISTS FROM THE FIRST MODULE ON PURPOSE. A rule like this only works if
// it was there before the first violation: added later, it fails on code that
// already ships, and the pressure is then to weaken the rule rather than fix
// the dependency. Written now, while there are three packages, it costs
// nothing and it is what turns "extract this into its own service" from a
// rewrite into a day's work.
//
// # THE TWO RULES
//
//  1. `platform` imports nothing else from this repository. Whatever lands
//     there is available to every module, so anything with an opinion about the
//     product does not belong in it — and an import pointing outwards is how
//     that opinion would arrive.
//
//  2. No module imports another module. They talk through interfaces the
//     consumer defines, and are wired together in `cmd/`. `platform` is the
//     exception every module may depend on, because that is what it is for.
//
// When a second module needs something from a first, the answer is not an
// import: it is an interface where it is used, satisfied by the other and
// passed in from `cmd/`. That is the whole discipline, and it is the reason a
// binary this small can be split later without archaeology.
```

"Nenhum módulo importa outro módulo. Eles conversam por interfaces que o consumidor define." Nas
palavras desta aula: **nenhum time lê direto as tabelas de outro time; lê o que o outro time prometeu
servir.** A interface é o contrato; o teste é o verificador; e o comentário explica por que ele foi
escrito antes da primeira violação e não depois — acrescentada mais tarde, uma regra assim falha em
código que já está no ar, e a pressão então é para enfraquecer a regra.

## Por que isso importa para a governança

Todo argumento deste curso sobre tabelas vale aqui:

- **a posse** é clara, porque cada tabela pertence a um módulo, e esse módulo decide o que ela
  significa;
- **a linhagem** é legível, porque todo caminho entre dois módulos passa por uma interface declarada;
- **a eliminação** é possível, porque toda tabela é registrada com o que guarda e com o que eliminar uma
  pessoa faz a ela, e um teste falha numa tabela nova que ninguém registrou — a verificação da aula 6,
  no código da própria plataforma.

Um banco em que qualquer consulta pode juntar qualquer tabela é um banco em que ninguém consegue dizer o
que depende do quê. Contratos, entre empresas ou entre módulos, são como essa pergunta ganha resposta.
