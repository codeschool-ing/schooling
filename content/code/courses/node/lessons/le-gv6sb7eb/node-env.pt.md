---
title: NODE_ENV
version: 1
---

**O `NODE_ENV` é uma convenção, não um recurso do Node**: o próprio Node o ignora. As bibliotecas o
leem, e por um acordo antigo o único valor que significa algo é `production`. A aula 6 mostrou o que
ele muda no Express (a página de erro padrão para de imprimir o stack trace), e ele muda mais duas
coisas que vale saber:

| quem lê | o que o `NODE_ENV=production` muda |
|---|---|
| Express | erros respondem `Internal Server Error` sem stack; templates, se houver, ficam em cache |
| npm | `npm install` e `npm ci` deixam de fora as `devDependencies`, como faz o `--omit=dev` |
| muitas bibliotecas | logs mais quietos, menos conferências que custam tempo |

A segunda linha é a surpresa: um build que define `NODE_ENV=production` antes de instalar fica sem
executor de testes e sem formatador, e um passo do build que precisava de um falha. Instale primeiro,
com as ferramentas de desenvolvimento, e defina o `NODE_ENV` para rodar.

## Produção ou não, e nada mais

A convenção funciona porque tem duas posições. **Um código que se ramifica pelo `NODE_ENV` em muitos
lugares** (um timeout diferente aqui, uma conferência pulada ali) tem dois programas, e o que está em
produção é o que não rodou num notebook. A regra neste curso é que o `NODE_ENV` quer dizer "isto é
produção?" e nada mais, lido num lugar só:

```javascript
production: env.NODE_ENV === "production",
```

Essa linha do `config.js` é a única leitura. Valores como `staging` ou `qa` parecem organizados e
quebram a convenção: toda biblioteca que confere `=== "production"` os trata como desenvolvimento, com
stack traces e tudo. Um servidor de staging roda com `NODE_ENV=production` e só difere da produção nas
outras variáveis.
