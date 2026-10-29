---
title: Uma pilha de produção
version: 1
---

**O build que as pessoas rodam é minificado: cada função renomeada para uma ou duas letras, e o planner
inteiro em poucas linhas compridas.** Uma pilha vinda dele é exata e inútil, até alguma coisa desfazer
isso. Para ver uma, o planner precisa de um erro no próprio código, num build de produção, então esta seção
põe um bug no ar de propósito e o tira de novo no fim.

Faça antes o commit do monitor e do coletor, para o bug ter um estado limpo para onde ser desfeito:

```
ana@dev:~/planner$ git add -A && git commit -qm "Report errors to a collector"
```

O bug: o `render` lança um erro quando o endereço termina em `?bug`. É uma linha só, e é o tipo de linha
que chega à produção quando uma conferência feita para depurar fica esquecida:

```
ana@dev:~/planner$ sed -i 's/^function render(): void {/&\n  if (location.search === "?bug") throw new Error("A bug, on purpose");/' src/main.ts
```

## Um build como o de verdade

Um deploy com servidor definiria as variáveis ao construir, e a release seria o commit sendo publicado. O
`git rev-parse --short HEAD` imprime o hash curto desse commit:

```
ana@dev:~/planner$ VITE_GRAPHQL_URL=/graphql VITE_ERRORS_URL=/errors VITE_RELEASE=$(git rev-parse --short HEAD) npm run build 2>&1 | grep assets/
dist/assets/index-BU4yu1tj.css    2.11 kB │ gzip:  0.64 kB
dist/assets/index-BzxC4LxE.js     5.70 kB │ gzip:  2.47 kB │ map:    13.51 kB
dist/assets/apollo-C4i3kjo7.js  192.68 kB │ gzip: 56.59 kB │ map: 1,088.02 kB
```

Cada arquivo JavaScript agora tem um **map** ao lado; a seção depois desta é sobre eles. Sirva o build com
`vite preview` na porta 4173, com o servidor GraphQL e o coletor ainda rodando, e abra
`http://localhost:4173/course/git?bug`. A página fica vazia, e o terminal do coletor imprime mais uma
linha, com o commit como release. Leia o relatório de volta do arquivo, a release, a origem e o caminho,
e depois a pilha que o navegador registrou:

```
ana@dev:~/planner$ tail -1 api/errors.jsonl | node -e 'process.stdin.on("data", (d) => { const r = JSON.parse(d); console.log(r.release, r.source, r.path); console.log(r.stack); })'
7ce2a66 error /course/git
Error: A bug, on purpose
    at A (http://localhost:4173/assets/index-BzxC4LxE.js:1:5016)
    at http://localhost:4173/assets/index-BzxC4LxE.js:1:5661
    at Object.next (http://localhost:4173/assets/apollo-C4i3kjo7.js:85:261)
    at e.next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:3846)
    at t._next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:3448)
    at t.next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:3072)
    at Object.next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:46412)
    at e.next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:3846)
    at t._next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:3448)
    at t.next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:3072)
```

A release é o commit, e a origem é `error`: nada no planner capturou este erro, então quem o capturou foi o
listener da janela.

`A`, na linha 1, coluna 5016, de `index-…js`, chamada por uma função anônima no mesmo arquivo, chamada por
oito frames no pedaço do Apollo, onde o navegador parou em dez frames, o padrão dele. Tudo isso é
verdade, e não diz qual linha do `main.ts` abrir. Um build minificado tem poucas linhas, então o número da
linha sozinho quase não diz nada; a coluna diz onde, num arquivo que ninguém escreveu.
