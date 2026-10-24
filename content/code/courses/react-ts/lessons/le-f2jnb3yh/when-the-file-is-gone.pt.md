---
title: Quando o arquivo sumiu
version: 1
---

**Uma parte lazy é uma requisição, e uma requisição pode falhar.** O caso interessante não é uma
conexão caída, mas um deploy. Um estudante abre o planejador de manhã; ao meio-dia sai uma versão nova,
com nomes de hash novos, e os arquivos antigos são apagados do servidor. À tarde o estudante, que nunca
recarregou, clica num curso, e a página dele pede um arquivo que não existe mais.

O servidor de preview pode fazer esse papel. Abra o planejador e, três segundos depois, pare o servidor,
como um deploy remove os arquivos antigos; então clique num curso:

```
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 --do 'wait 5000' --do 'click button Statistics'
-- wait 5000
-- click button Statistics
[error] Failed to load resource: net::ERR_CONNECTION_REFUSED
[error] TypeError: Failed to fetch dynamically imported module: http://localhost:4173/assets/CourseScreen-rKGK0gfi.js
[error] ErrorBoundary: Failed to fetch dynamically imported module: http://localhost:4173/assets/CourseScreen-rKGK0gfi.js
    at Lazy (<anonymous>)
    at Suspense (<anonymous>)
    at main (<anonymous>)
    at Vt (http://localhost:4173/assets/index-BDKi8Zd8.js:9:55405)
    at Wt (http://localhost:4173/assets/index-BDKi8Zd8.js:9:56812)
    at _ (http://localhost:4173/assets/index-BDKi8Zd8.js:1:9662)
    at Et (http://localhost:4173/assets/index-BDKi8Zd8.js:9:51785)
- main:
  - heading "Study planner" [level=1]
  - alert: Something went wrong, and the planner stopped. Reload the page to start again.
```

O import falhou, e **um import que falha é um erro lançado onde o componente lazy renderiza**. Ele subiu
além do `Suspense`, que só cuida de esperas, e chegou ao primeiro error boundary acima dele, o que a
aula 12 pôs em volta da aplicação inteira. O estudante vê a reserva da raiz, e desta vez o conselho dela
está exatamente certo: recarregar busca o `index.html` novo, que nomeia os arquivos novos.

Dois detalhes no console:

- **Nenhuma mensagem longa do React desta vez.** Este é o build de produção, que relata um erro
  capturado com `console.error` e só o erro; o parágrafo do build de desenvolvimento sobre qual
  boundary assumiu só existe em desenvolvimento.
- **A pilha de componentes está minificada.** `Vt`, `Wt` e `Et` são componentes do planejador,
  renomeados pelo bundler para poupar bytes; só o `Lazy` e o `Suspense` do próprio React, e o elemento
  HTML `main`, mantêm os nomes. Em produção, as pilhas precisam dos **source maps** que um build pode
  emitir para serem lidas de volta com os nomes que você escreveu; a aula 20 trata do que um build
  produz.

A correção que importa não está no código que carrega o arquivo, mas em como os arquivos são
publicados: **mantenha os arquivos da versão anterior no servidor por um tempo depois de um deploy**,
para que uma página já aberta ainda consiga buscá-los. Algumas plataformas de hospedagem fazem isso por
você e outras substituem a pasta inteira; vale descobrir o que a sua faz antes da primeira reclamação
sobre uma página que quebrou sozinha.
