---
title: TypeScript, parte 2, classes, genéricos e decorators
version: 1
---

**Todo componente, serviço, pipe e diretiva do Angular é uma classe com um decorator em cima.** A
seção anterior deu tipos aos valores; esta cobre as três peças de TypeScript que um arquivo Angular
usa na primeira linha e em todas as seguintes: classes com modificadores de acesso, genéricos e
decorators.

## Uma classe, com o que o TypeScript acrescenta

`javascript` ensinou classes: um construtor, campos, métodos, `get`. O TypeScript acrescenta palavras
que dizem quem pode mexer em quê e, como os tipos, elas são conferidas pelo compilador e apagadas
depois.

```schooling-example
{"language": "typescript", "file": "week.ts", "parts": [
 {"code": "interface Session {\n  courseId: string;\n  minutes: number;\n  done: boolean;\n}", "note": "O formato de uma sessão, reduzido ao que este exemplo precisa."},
 {"code": "class Week {\n  private readonly sessions: Session[] = [];", "note": "`private` quer dizer que só código de dentro de `Week` pode usar o campo, e `readonly`, que nem esse código pode apontá-lo para outro array depois de definido. Dar `push` no array continua permitido: o campo é fixo, o array não."},
 {"code": "  constructor(readonly label: string) {}\n\n  add(s: Session): void {\n    this.sessions.push(s);\n  }", "note": "Uma **propriedade de parâmetro**: `readonly` na frente de um parâmetro do construtor declara um campo e o preenche de uma vez. Código Angular usa esse formato o tempo todo, então aprenda a lê-lo."},
 {"code": "  get total(): number {\n    return this.sessions.reduce((sum, s) => sum + s.minutes, 0);\n  }\n}\n\nconst week = new Week(\"19 to 25 October\");\nweek.add({ courseId: \"javascript\", minutes: 60, done: true });\nweek.add({ courseId: \"git\", minutes: 25, done: false });\nconsole.log(week.label, week.total);", "note": "Um getter: lido como `week.total`, sem parênteses, e calculado a cada leitura."},
 {"code": "week.sessions = [];", "note": "De fora da classe, as duas regras valem ao mesmo tempo, e o compilador recusa esta linha."}
]}
```

```
ana@dev:~/ts$ npx tsc --noEmit --strict week.ts
week.ts(22,6): error TS2341: Property 'sessions' is private and only accessible within class 'Week'.
week.ts(22,6): error TS2540: Cannot assign to 'sessions' because it is a read-only property.
```

Duas mensagens para uma linha, porque a linha quebra duas regras. Apague-a e a conferência passa.
`private` é uma promessa que o compilador cumpre, não o navegador: no JavaScript que roda, o campo é
uma propriedade comum. A aula 6 mostra código Angular usando `protected` e `readonly` juntos em quase
todo campo que um template lê.

## Genéricos: um tipo com uma lacuna

Algum código funciona do mesmo jeito para qualquer tipo de valor. Uma função que devolve o primeiro
item de uma lista não se importa com o que são os itens, mas quem a chama se importa: o primeiro de
uma lista de números é um número. Um **genérico** mantém essa ligação com um parâmetro de tipo,
escrito entre sinais de menor e maior:

```typescript
// first.ts
function first<T>(list: T[]): T | undefined {
  return list[0];
}

const minutes = first([45, 60]);
const course = first(["git", "javascript"]);
const wrong: string | undefined = first([45, 60]);
```

Leia `<T>` como "para algum tipo T". Chamada com `[45, 60]`, T é `number`, então `minutes` é
`number | undefined`; chamada com strings, T é `string`. A terceira linha pede uma string e recebe um
número:

```
ana@dev:~/ts$ npx tsc --noEmit --strict first.ts
first.ts(8,7): error TS2322: Type 'number | undefined' is not assignable to type 'string | undefined'.
  Type 'number' is not assignable to type 'string'.
```

Você vai escrever poucos genéricos neste curso, e vai lê-los em toda página. O `signal<number>(0)` do
Angular, na aula 6, é um valor que guarda números; o `input<Session>()` da aula 8 é um input que
recebe uma sessão; e o `http.get<Course[]>(url)` da aula 12 é uma requisição cuja resposta *se diz*
uma lista de cursos. A aula 12 também é onde você aprende por que "se diz" é a expressão certa.

## Decorators: uma função aplicada a uma classe

Um **decorator** é o `@Alguma(...)` escrito acima de uma classe. É uma função, chamada uma vez
quando a classe é definida, que recebe a classe e pode registrar algo sobre ela. Este imprime o que
recebeu:

```typescript
// label.ts
function Labelled(label: string) {
  return function (target: Function) {
    console.log(`${label} is ${target.name}`);
  };
}

@Labelled("the planner")
class Planner {}

console.log(new Planner());
```

O suporte de TypeScript embutido no Node só remove tipos; ele não reescreve sintaxe, e um decorator é
uma sintaxe que o JavaScript do Node 22 não tem:

```
ana@dev:~/ts$ node label.ts
/home/ana/ts/label.ts:8
@Labelled("the planner")
^

SyntaxError: Invalid or unexpected token
    at wrapSafe (node:internal/modules/cjs/loader:1638:18)
    at Module._compile (node:internal/modules/cjs/loader:1680:20)
    at Object..js (node:internal/modules/cjs/loader:1839:10)
    at Module.load (node:internal/modules/cjs/loader:1441:32)
    at Function._load (node:internal/modules/cjs/loader:1263:12)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49

Node.js v22.22.0
```

Então este arquivo precisa ser compilado antes. O `--experimentalDecorators` escolhe o tipo de
decorator que o Angular usa, o `--target es2022` a versão de JavaScript a gerar, e o `--outDir out`
onde gravar:

```
ana@dev:~/ts$ npx tsc --strict --target es2022 --experimentalDecorators --outDir out label.ts
ana@dev:~/ts$ node out/label.js
the planner is Planner
Planner {}
```

O decorator rodou antes do `new Planner()`, enquanto a classe era definida. **O `@Component` é
isto**, com mais coisa dentro: ele recebe a sua classe e uma descrição dela, o seletor, o template,
os estilos, e o Angular lê essa descrição para saber como construir e desenhar a classe. O
`@Labelled` acima imprime; o `@Component` registra. A aula 3 lê cada campo da descrição.

Mais uma coisa acontece num build Angular de verdade. O compilador da CLI lê os decorators
**antecipadamente** (ahead of time), na hora do build, e transforma cada template em JavaScript que
cria o DOM diretamente. O navegador nunca vê o `@Component`, e esse é um dos motivos pelos quais uma
aplicação Angular pode ser menor do que o código-fonte sugere.
