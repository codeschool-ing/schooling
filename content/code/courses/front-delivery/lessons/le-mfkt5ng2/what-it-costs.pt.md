---
title: Quanto custa
version: 1
---

**O Apollo Client é uma biblioteca à parte, e o navegador baixa ela inteira antes de o planner poder
perguntar qualquer coisa.** O planner sem ele tinha poucos kilobytes de JavaScript. Meça os dois builds, o
estático e um feito com a variável definida, como um deploy que tem servidor o faria:

```
ana@dev:~/planner$ npm run build 2>&1 | grep 'assets/.*js'
dist/assets/index-Cm5GLo6w.js   3.54 kB │ gzip: 1.57 kB
ana@dev:~/planner$ VITE_GRAPHQL_URL=/graphql npm run build 2>&1 | grep 'assets/.*js'
dist/assets/index-DYKvyMM5.js     5.27 kB │ gzip:  2.27 kB
dist/assets/apollo-CGBmoQ9B.js  192.66 kB │ gzip: 56.54 kB
```

O build estático tem 3,54 kB, a poucos bytes do da aula 9, porque nada nele importa o Apollo. O build com
servidor ganha dois arquivos: o planner, um pouco maior, e um pedaço com o nome de `apollo.ts`, de cerca
de 190 kB, ou cerca de 56 kB comprimidos, que é o que atravessa a rede. O Vite o separou sozinho, porque o
`apollo.ts` só é alcançado por `import()`; o navegador o busca quando o `watch` roda pela primeira vez.

## O import que desfaria isso

A separação depende de uma regra: **nada chega ao Apollo por um `import` comum a partir do código que todo
build roda.** Uma linha a quebra. Ponha de volta um import de `queries.ts` no topo do `api.ts`, como uma
pessoa caprichosa faria, e construa a versão estática de novo:

```
ana@dev:~/planner$ sed -i '1a import "./queries";' src/api.ts
ana@dev:~/planner$ head -3 src/api.ts
// src/api.ts
import "./queries";
import type { Course, Session } from "./planner";
ana@dev:~/planner$ npm run build 2>&1 | grep 'assets/.*js'
dist/assets/index-CsC4EW2X.js   38.14 kB │ gzip: 10.39 kB
```

O build estático ficou dez vezes maior, sem que uma linha dele jamais rode. O `queries.ts` chama o `gql`
quando carrega, e uma chamada é algo que o bundler precisa manter, então o `gql` e o parser por trás dele
vieram junto. Uma conferência de tamanho no pipeline da aula 3 teria pegado isso antes de ir para o ar; é
para isso que conferências assim existem. Devolva o arquivo:

```
ana@dev:~/planner$ git restore src/api.ts
ana@dev:~/planner$ git status --short
```

## Se 56 kB é muito

Depende do que ele substitui. Contra as doze linhas da aula 9 é muita coisa; contra o código que uma
equipe escreveria para fazer cache, compartilhar pedidos e desfazer mudanças à mão, é barato, e esse código
teria bugs que o Apollo já corrigiu. **Um app pequeno, com poucas telas, muitas vezes fica melhor com um
cliente pequeno**, ou com as doze linhas da aula 9; o argumento a favor do Apollo cresce com o número de
telas que mostram os mesmos objetos. As duas próximas seções são sobre as outras escolhas.
