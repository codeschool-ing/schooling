---
title: Templates são conferidos como código
version: 1
---

**A CLI confere os tipos de todo template contra a sua classe, na hora do build, com o mesmo rigor
com que confere o TypeScript.** A aula 2 apontou a opção, `strictTemplates`, no `tsconfig.json`. Esta
seção é o que ela compra: erros que chegariam ao navegador num framework que lê os templates em
tempo de execução. Quebre o template da bancada em três lugares de uma vez:

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<p>{{ minuts }} minutes</p>
<button type="button" (click)="add()">Add</button>
<progress [value]="minutes" [max]="'240'"></progress>
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -A1 ERROR
✘ [ERROR] TS2551: Property 'minuts' does not exist on type 'Bench'. Did you mean 'minutes'? [plugin angular-compiler]

--
✘ [ERROR] TS2554: Expected 1 arguments, but got 0. [plugin angular-compiler]
```

Dois erros, cada um com um código de erro do TypeScript da aula 1, agora apontando para HTML:

- **`TS2551`**, o campo escrito errado, com o mesmo *Did you mean* que o `tsc` ofereceu para `minuts`
  na aula 1. Um template que lesse um campo que ninguém tem mostraria um parágrafo vazio, e ninguém
  perceberia até um usuário perceber.
- **`TS2554`**, um método chamado sem o argumento que exige. O compilador sabe que o `add` recebe um
  número, porque leu a classe.

E um erro que ele deixou passar: `[max]="'240'"` entrega uma string a uma propriedade que guarda um
número. **Bindings a propriedades de elementos HTML puros não têm o tipo conferido**; o navegador
converte a string, e aqui converte certo, então a barra funciona. A conferência cobre o que é seu: os
campos e métodos da sua classe e, a partir da aula 8, os inputs dos seus componentes. Escreva
`[max]="240"`, sem as aspas de dentro, mesmo assim: diz o que você quer dizer.

Nenhum desses erros teria impedido a página de carregar. Cada um seria uma pequena coisa errada numa
tela, que é o tipo de bug mais caro de achar. **Um template que compila é um template em que todo nome
existe e toda chamada cabe no seu método.** Isso não quer dizer que a página diz a coisa certa; para
isso existem os testes.

O servidor de desenvolvimento relata os mesmos erros no terminal dele e os mostra sobre a página no
navegador, numa camada por cima, para você vê-los sem tirar os olhos do que estava conferindo. A
próxima seção remove a bancada, com erros e tudo.
