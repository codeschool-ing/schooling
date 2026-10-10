---
title: A cópia que sobrevive a um deploy
version: 1
---

Um worker cache-first responde o shell com a sua própria cópia, e nada no worker da quitanda
substitui essa cópia, nunca. **Então, depois de um deploy, um visitante que já esteve aqui continua
rodando o shell velho**, e continua até algo mudar o próprio worker. A aula 4 tratou de um cache que
o servidor controla com cabeçalhos. Este é controlado por um script, e os cabeçalhos não chegam a
ele.

Essa é a crença a abandonar: *o servidor manda `Cache-Control: no-cache`, então o navegador sempre
confere.* A aula 1 pôs esse cabeçalho em todo arquivo que a loja serve, e ele governa o **cache
HTTP** do navegador. Um service worker guarda as suas cópias em outro lugar, o **Cache Storage**, e
responde com elas antes de o cache HTTP ser sequer consultado. O `caches.match` de `sw.js` não lê
cabeçalho nenhum e não confere com ninguém.

## Um deploy, encenado à mão

Abra `app/public/spa/spa.js` no seu editor e troque o título da tela de frutas de `Fruit` para
`Fresh fruit`, como a próxima versão de um desenvolvedor poderia fazer. Inicie a loja, e o servidor
tem o arquivo novo:

```
ana@laptop:~/quitanda$ curl -s http://localhost:3000/spa/spa.js | grep -n 'Fresh fruit'
9:    view.innerHTML = '<h1>Fresh fruit</h1><ul></ul>';
```

Agora inicie a loja com o log ligado e rode `spa-look.mjs` uma terceira vez, ainda com o perfil das
execuções anteriores:

```
ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start
ana@laptop:~/quitanda$ node spa-look.mjs
   20 ms  document   /spa/  from the service worker
   40 ms  stylesheet /style.css  from the service worker
   40 ms  script     /spa/spa.js  from the service worker
   70 ms  fetch      /api/products  from the server
   95 ms  heading: Fruit
  104 ms  service worker ready; click Basket
  137 ms  fetch      /api/basket  from the server
  157 ms  heading: Basket, address: http://localhost:3000/spa/basket
```

E o lado do servidor:

```

> start
> node app/server.js

quitanda is listening on http://localhost:3000
GET /api/products 200
GET /api/basket 200
```

`Fruit`. O documento, a folha de estilos e o script vieram todos do service worker, e o log do
servidor tem duas linhas, ambas sob `/api/`: ninguém pediu `spa.js` ao servidor, e nesta execução o
navegador também não pediu `sw.js`. A versão nova está no servidor, e este visitante não a vê.

Volte o título para `Fruit` antes de seguir, para que as próximas aulas encontrem o arquivo como
esperam.

## O que isso significa para uma suíte

**Uma suíte de testes não vê isso por padrão.** Todo teste do Playwright começa num contexto de
navegador novo, sem worker e sem cópias, então todo teste é uma primeira visita, e uma primeira
visita sempre recebe a versão nova. O defeito mora inteiro no visitante que volta, que é quem os
seus usuários são.

Pegá-lo exige duas versões do app e um navegador que conheceu a primeira: abrir o site na versão
velha, publicar a nova, abrir de novo no mesmo perfil e verificar o que está na tela. O
`spa-look.mjs` acabou de fazer isso à mão. Numa equipe, isso pertence ao lugar onde duas versões se
encontram, um ambiente de homologação por onde uma versão passa; a aula 21 de `manual-testing` trata
de ambientes e a aula 5 de `testing-cicd` do pipeline que rodaria isso.

O remédio é do desenvolvedor, e depende do que o app promete. Os comuns são um worker que pergunta
primeiro à rede pela página e só recorre à cópia sem rede, ou um worker que nomeia o cache por
versão e apaga as cópias velhas quando uma versão nova assume, muitas vezes com um aviso de que *há
uma nova versão disponível*. Seja qual for, a pergunta do testador é a mesma que esta seção fez:
**depois de um deploy, o que vê quem esteve aqui ontem?**

## Vendo isso no navegador

Nas ferramentas de desenvolvedor do Chrome, o painel **Network** marca uma resposta que veio de um
worker como `(ServiceWorker)` na coluna **Size**, então o recarregamento de uma página velha parece
diferente ali de um recarregamento novo. O painel **Application** lista os workers instalados, com um
botão para desregistrar um, e a entrada **Cache storage** mostra o que cada cache guarda:
`shell-v1`, com os seus três arquivos. Quando alguém relata que ainda vê a página de ontem, esses
dois lugares dizem se a resposta é o cache da aula 4 ou este.
