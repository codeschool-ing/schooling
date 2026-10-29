---
title: Onde o TypeScript custa alguma coisa
version: 1
---

**O TypeScript não é de graça, e o jeito honesto de decidir se um projeto o quer é saber quanto ele
custa.** Para o planner os custos são pequenos e mensuráveis, e os benefícios são os erros desta aula,
encontrados por um programa. Para certo código a balança pende para o outro lado, e os custos
específicos do Vue merecem ser conhecidos em particular.

## O que o planner pagou

O verificador, e o disco que ele ocupou:

```
ana@dev:~/vue/planner$ time npm run type-check

> planner@0.0.0 type-check
> vue-tsc --noEmit


real	0m2.086s
user	0m4.228s
sys	0m0.256s
```

```
ana@dev:~/vue/planner$ du -sh node_modules
126M	node_modules
ana@dev:~/vue/planner$ du -sh node_modules/typescript
24M	node_modules/typescript
```

**Cerca de dois segundos para conferir o planner inteiro**, na máquina da gravação, e um compilador
que é uma boa parte do que o `node_modules` guarda; nenhum dos dois chega ao navegador do estudante. E
o código: mudanças em nove arquivos do `src` além dos dois novos, quase todas parâmetros, `ref<…>()` e `?.`.
Nada no modo como o planner roda mudou, e o JavaScript do build é o mesmo, porque os tipos são
removidos antes de qualquer coisa ser empacotada.

## Onde custa mais do que parece

- **Bibliotecas sem bons tipos.** Uma biblioteca escrita em JavaScript sem tipos, ou com tipos
  errados, obriga você a escrever declarações para ela ou a aceitar `any` na borda dela. Vue, Vue
  Router, Pinia e Vite são escritos em TypeScript, então o planner não encontrou nada disso.
- **Tipos que descrevem o framework, e não o app.** `InstanceType<typeof PlannerDialog>` está certo e
  não é a ideia de legível de ninguém. Todo recurso do Vue que atravessa a fronteira de um componente,
  template refs para componentes, provide e inject (as chaves da aula 8 viram `InjectionKey<T>`),
  componentes genéricos, tem uma forma tipada, e cada uma é mais uma coisa para aprender.
- **O template é conferido por um segundo programa.** O `tsc`, o compilador TypeScript puro, não
  entende arquivos `.vue`; o `vue-tsc` entende, e ele precisa ser mantido numa versão que combine com
  o Vue e com o TypeScript. O TypeScript 7, reescrito em Go e muito mais rápido, é o atual no momento em
  que isto é escrito, e o `create-vue` 3.24.0 ainda instala o 6.0 por padrão, oferecendo o compilador
  em Go só atrás de uma flag própria, `--tsgo`; o planner segue o padrão.
- **Asserções escondem o que afirmam.** `as Something` e `!` mandam o verificador confiar em você.
  Cada uma é um lugar em que os tipos dizem algo que o código não prova, e uma base de código cheia
  delas tem o custo dos tipos e menos dos benefícios.

## Quando usar

Para uma aplicação que vai viver por anos, ser alterada por várias pessoas ou ter formas de dados
compartilhadas entre muitos componentes, o caso do planner: sim, desde o começo, porque acrescentar
tipos depois, como esta aula fez, significa ler todos os erros de uma vez. Para um protótipo de uma
tarde, um widget numa página (aula 1) ou o sandbox de um curso: JavaScript serve, e a conversão é
trabalho de uma tarde quando ele cresce. **O resto deste curso escreve o planner em TypeScript**: o
build da aula 17 o confere, e as aulas 18 a 21 partem de código tipado.
