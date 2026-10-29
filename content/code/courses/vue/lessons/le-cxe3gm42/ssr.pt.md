---
title: Renderização no servidor, e hidratação
version: 1
---

**Uma página do Nuxt é renderizada primeiro no servidor: o servidor roda os componentes da página,
transforma o que eles desenham em HTML e manda isso.** O navegador mostra o HTML na hora, depois baixa
os mesmos componentes, os executa e os liga aos elementos que já estão na tela, em vez de desenhar
novos. A segunda metade se chama **hidratação**, e depois dela a página é uma aplicação Vue comum,
igual à do planner do Vite. Suba de novo o servidor de desenvolvimento do Nuxt e olhe a semana com o
JavaScript desligado:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --no-js --text 'main section:nth-child(3)'
== the text of main section:nth-child(3)
Week of 19 October 2026
Previous weekNext week
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
75 of 195 minutes done
```

**A semana inteira, com os totais, sem script nenhum rodar.** O servidor chamou o `useFetch`, que
pediu `/api/courses` sem sair do servidor, rodou o `weekTotal`, renderizou as linhas e mandou o
resultado. O que uma página sem JavaScript não consegue fazer é qualquer coisa que precise do Vue
escutando:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --no-js --do 'check label:has-text("21 October") input' --do 'goto /' --text 'main section:nth-child(3) footer'
-- check label:has-text("21 October") input
-- goto /
== the text of main section:nth-child(3) footer
75 of 195 minutes done
```

A caixa foi marcada, porque uma caixa de seleção marca sozinha, e nada avisou o servidor; a página
carregada de novo continua dizendo 75. O `@change` que manda o `PATCH` é ligado pela hidratação, e até
a hidratação acontecer a página *parece* pronta e não está. Essa lacuna é o preço de renderizar no
servidor: o leitor vê a página mais cedo, e consegue clicar nela antes de ela conseguir responder. Num
celular lento, isso chega a um ou dois segundos.

## A página e o que vem depois dela

Com JavaScript, o navegador faz estas requisições, fora os módulos do Nuxt e do Vue:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --network --text - | grep -v '^net  GET /_nuxt/@' | grep -c '^net'
20
```

Um servidor de desenvolvimento não é lugar para contar requisições, porém, como a aula 17 mostrou com
o do Vite. Pare-o e faça o build do planner do jeito que ele iria para produção:

```
ana@dev:~/vue/planner-nuxt$ npm run build 2>&1 | tail -3
[nitro] ✔ You can preview this build using node .output/server/index.mjs
config 301ms · modules 62ms · app 409ms · types 404ms · client 974ms · server 419ms · nitro 3.80s
◆ ✨ Build complete in 6.37s!
```

O resultado é o `.output`, e ele é bem diferente do `dist` do planner do Vite:

```
ana@dev:~/vue/planner-nuxt$ du -sh .output
3.1M	.output
ana@dev:~/vue/planner-nuxt$ ls .output .output/server/node_modules
.output:
nitro.json
public
server

.output/server/node_modules:
@babel
@vue
devalue
entities
estree-walker
fnv1a-64
hookable
nostics
object-identity
source-map-js
ufo
unhead
vue
vue-bundle-renderer
vue-router
```

**`public` é o que o navegador baixa, e `server` é um programa**, o Nitro com as páginas e as rotas de
API do planner compiladas dentro dele, e os pacotes de que ele precisa em tempo de execução copiados
ao lado, quinze entradas de um `node_modules` pequeno. O `node-forge` não está entre elas: o alerta
de segurança da aula 18 estava nas ferramentas do servidor de desenvolvimento e nunca chega a um
build. Rode-o:

```
ana@dev:~/vue/planner-nuxt$ node .output/server/index.mjs
Listening on http://0.0.0.0:3000
```

**`0.0.0.0` quer dizer todas as redes em que o computador está**, não só `localhost`, que é do que um
servidor atrás do proxy de um host precisa, e também é por isso que os endpoints da aula 18, que não
perguntam a ninguém quem é, não devem rodar assim num computador que outras pessoas alcançam. A página
da semana, no servidor do build:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --network --text - | grep '^net'
net  GET /  200
net  GET /_nuxt/entry.DM7gLlzw.css  200
net  GET /_nuxt/DqJQdDDH.js  200
net  GET /_nuxt/P0c8VxyF.js  200
net  GET /_nuxt/D5BqGcD9.js  200
net  GET /_nuxt/VuPL-ScY.js  200
net  GET /_nuxt/Ay1E5qCJ.js  200
net  GET /_nuxt/fetch.B5cEvZ0E.css  200
net  GET /_nuxt/pages.B5v9DPLB.css  200
net  GET /_nuxt/default.CF8CboJV.css  200
net  GET /_nuxt/DIj-9ZNw.js  200
```

**Onze requisições, e nenhuma delas é `/api/courses`.** A página chegou com os dados dentro: o servidor
mandou o que o `useFetch` recebeu junto com o HTML, para que a cópia da página no navegador
hidratasse com os mesmos dados sem pedi-los de novo. Essa cópia é o *payload*, e a aula 20 trata dele.
O resto são as folhas de estilo e os pedaços do código, alguns a mais que os quatro do build do Vite
porque o Nuxt separa o layout, a página e o próprio runtime.
