---
title: O que uma biblioteca de componentes custa, e quando compensa
version: 1
---

**Uma biblioteca é código que o navegador baixa.** O mesmo build do começo da aula:

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -E 'Initial total|courses-routes'
                      | Initial total  | 313.73 kB |                86.23 kB
chunk-ODVGTZAK.js     | courses-routes | 196.97 kB |                37.46 kB
```

O primeiro download cresceu uns 20 kB, a maior parte os estilos do tema, de que toda página precisa. O
chunk da área do curso cresceu de 45 kB para 197 kB: a caixa de seleção, o diálogo e as partes do CDK
que eles trazem só são usados nas páginas de um curso, então foram para o chunk lazy dela, e uma visita
só à semana não os baixa. A divisão da aula 18 está se pagando aqui.

| escolha | quando |
|---|---|
| Angular Material | a aplicação pode parecer Material, e você quer os componentes prontos, acessíveis e mantidos por outros |
| o CDK, com estilos próprios | a aplicação tem design próprio, e você quer o comportamento de controles difíceis sem a aparência |
| componentes seus | o controle é simples, e um elemento nativo estilizado com CSS resolve, como todo controle do planner até esta aula |

**O que não fazer é metade de cada um**: um componente do Material reestilizado até parecer outra coisa
briga com o próprio tema a cada atualização. O tema do Material são as propriedades CSS customizadas,
as que o `mat.theme` escreveu, e mudá-las é o jeito suportado de torná-lo seu.

```
ana@dev:~/planner$ git status --short
 M angular.json
 M package-lock.json
 M package.json
 M src/app/add-session/add-session.ts
 M src/app/session-row/session-row.ts
 M src/app/unsaved-work.ts
?? src/app/confirm-leave/
?? src/material-theme.scss
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Material and the CDK: a checkbox, a dialog, an announcement"
```
