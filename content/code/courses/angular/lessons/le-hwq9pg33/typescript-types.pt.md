---
title: TypeScript, parte 1, tipos nos valores
version: 1
---

**TypeScript é JavaScript com os tipos escritos ao lado dos valores, e um compilador que os confere
antes de o programa rodar.** Depois os tipos são jogados fora. Nada deles sobrevive até o
navegador: o que roda é o JavaScript que você já conhece de `javascript`, sem as anotações. Esse
fato sozinho explica quase tudo o que surpreende as pessoas no TypeScript, então esta seção o mostra
antes de qualquer outra coisa.

## Uma pasta para experimentar

O TypeScript é um pacote do npm. O projeto da aula 2 vai trazer a própria cópia; esta é só para
estas duas seções, na mesma versão que o Angular 21 usa:

```
ana@dev:~$ mkdir ~/ts
ana@dev:~$ cd ~/ts
ana@dev:~/ts$ npm init -y > /dev/null
ana@dev:~/ts$ npm install --save-exact typescript@5.9.3

added 1 package, and audited 2 packages in 759ms

found 0 vulnerabilities
ana@dev:~/ts$ du -sh ~/ts
23M	/home/ana/ts
```

O `--save-exact` grava `5.9.3` no `package.json` em vez de `^5.9.3`, para que o próximo
`npm install` nesta pasta pegue a mesma versão e não a mais nova do dia. A aula 2 faz a mesma escolha
para o projeto inteiro.

## Tipos são conferidos, depois apagados

Salve isto como `~/ts/hello.ts`. A última linha está errada de propósito: `label` pede um número e
recebe uma string.

```typescript
// hello.ts
const minutes: number = 45;

function label(m: number): string {
  return m + " min";
}

console.log(label(minutes));
console.log(label("45"));
```

`: number` depois de um nome é uma **anotação de tipo**: diz o que o valor pode ser. Depois dos
parênteses de uma função, diz o que a função devolve. O Node 22 consegue rodar um arquivo `.ts`
direto, e é isto o que ele faz com este:

```
ana@dev:~/ts$ node hello.ts
45 min
45 min
```

As duas linhas foram impressas. **O Node removeu as anotações e rodou o resto**, e o resto é
JavaScript válido: `"45" + " min"` é uma string como outra qualquer. Rodar não é conferir. Quem lê os
tipos é o compilador, o `tsc`:

```
ana@dev:~/ts$ npx tsc --noEmit --strict hello.ts
hello.ts(9,19): error TS2345: Argument of type 'string' is not assignable to parameter of type 'number'.
ana@dev:~/ts$ echo $?
2
```

`hello.ts(9,19)` é a linha 9, coluna 19: o `"45"`. O `--noEmit` pede a conferência sem gravar
JavaScript nenhum, e o `--strict` liga as conferências que todo projeto Angular tem ligadas; o
`tsconfig.json` da aula 2 diz isso na primeira linha das opções. O código de saída 2 é como um script
de build sabe que a conferência falhou.

**O acordo inteiro é este.** Você escreve mais, e uma categoria de erros para de chegar ao navegador.
Num projeto Angular você nunca chama o `tsc` diretamente: o `ng build` e o `ng serve` fazem a mesma
conferência em todos os arquivos, e em todos os templates também, a partir da aula 4.

## A maioria dos tipos é inferida

Escrever `: number` em `minutes` não era necessário. O TypeScript vê o `45` e decide; passar o mouse
sobre o nome num editor mostra `const minutes: 45`, um tipo mais estreito ainda que `number`, porque
uma `const` nunca pode ser outra coisa. Anote os lugares onde o compilador não enxerga a resposta:
parâmetros de função, e tudo o que começa vazio e é preenchido depois.

## O formato de um objeto

O planner que este curso constrói guarda sessões de estudo. Uma **interface** dá nome ao formato de
uma delas:

```typescript
// session.ts
interface Session {
  id: number;
  courseId: string;
  date: string;
  minutes: number;
  done: boolean;
  note?: string;
}

const sessions: Session[] = [
  { id: 1, courseId: "javascript", date: "2026-10-20", minutes: 60, done: true },
  { id: 2, courseId: "git", date: "2026-10-22", minutes: 25, done: false },
];

function total(list: Session[]): number {
  return list.reduce((sum, s) => sum + s.minutes, 0);
}

function pending(list: Session[]): Session[] {
  return list.filter((s) => !s.done);
}

console.log(total(sessions), pending(sessions).length);
console.log(sessions[0].minuts);
```

`note?:` é opcional: um objeto sem ela continua sendo um `Session`. `Session[]` é um array deles. A
última linha tem um erro de digitação, e o compilador o aponta e adivinha o que você quis dizer:

```
ana@dev:~/ts$ npx tsc --noEmit --strict session.ts
session.ts(25,25): error TS2551: Property 'minuts' does not exist on type 'Session'. Did you mean 'minutes'?
```

O Node teria impresso `undefined` nessa linha e seguido em frente. Numa aplicação, esse `undefined`
é um espaço em branco onde devia haver um número, achado por alguém olhando para a tela.

## Várias possibilidades, e estreitamento

Um tipo pode ser uma lista de valores exatos. O estado de uma sessão poderia ser escrito

```typescript
type State = "planned" | "done" | "skipped";
```

e uma variável do tipo `State` aceita então essas três strings e recusa `"Done"`. O `|` se lê como
*ou*: `string | undefined` é uma string ou nada, que é o que o TypeScript diz que `sessions.find(...)`
devolve, porque a busca pode não achar nada. Antes de usar o resultado, você confere:

```typescript
const next = sessions.find((s) => !s.done);
if (next) {
  console.log(next.minutes); // inside the if, next is a Session
}
```

Dentro do `if`, o compilador sabe que `next` não é `undefined` e deixa você ler `.minutes`; fora, ele
recusa. Isso se chama **estreitamento** (narrowing), e com o `--strict` ligado você o encontra em
toda aula: um input que talvez ainda não tenha valor, um parâmetro de rota que pode faltar, uma
resposta do servidor que pode ser um erro.
