---
title: Três jeitos de escrever um formulário, e qual usar
version: 1
---

**Use formulários reativos para tudo o que vai crescer, e reconheça os outros dois quando os
encontrar.** Os três não são estilos concorrentes da mesma coisa; cada um põe o modelo do formulário
num lugar diferente, e isso decide o que fica fácil.

| | template-driven | reativo | Signal Forms |
|---|---|---|---|
| situação no Angular 21 | estável | estável | experimental |
| o modelo | valores na classe, controles feitos pelo template | `FormGroup`, `FormArray`, `FormControl` na classe | um signal de um objeto simples, e uma árvore de campos sobre ele |
| tipos | `any` | deduzidos dos controles | deduzidos do modelo |
| regras | atributos e diretivas | funções validadoras | uma função de schema sobre caminhos |
| ler o estado | o template, ou o `NgForm` depois de um instante | `value`, `status`, `valueChanges` | signals: `value()`, `errors()`, `valid()` |
| onde você o encontra | código antigo, formulários pequenos | a maior parte do código Angular dos últimos dez anos | código novo que aceita o risco |

O **template-driven** serve para uma caixa de busca ou um cadastro de newsletter: um ou dois campos,
nenhuma regra entre eles, nada que a classe precise ler. O **reativo** é o padrão para todo o resto, e
o que o planner usa. Os **Signal Forms** valem uma tentativa num formulário novo onde uma mudança de
API custaria uma tarde, e valem ser acompanhados, porque devem virar o padrão quando ficarem estáveis.

O bench sai, e o planner fica como estava:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts
```

```
ana@dev:~/planner$ git status --short
```
