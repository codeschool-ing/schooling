---
title: Uma página por vez
version: 1
---

**O Vue consegue assumir um elemento de uma página que já existe e deixar o resto dela em paz.** É
isso que a documentação do próprio Vue quer dizer ao chamá-lo de framework *progressivo*, e é a única
coisa neste assunto em que o Vue difere dos outros três da trilha: React, Angular e Svelte esperam ser
donos da página inteira, ou pelo menos ser construídos pelas próprias ferramentas. O Vue pode ser
acrescentado a uma página que um servidor já renderiza, um widget por vez, sem nenhuma etapa de build.

Esta seção faz isso sem projeto, para mostrar o que a etapa de build estava acrescentando.

## A página

Crie uma pasta ao lado do planner e copie para ela o único arquivo do Vue que roda num navegador do
jeito que está. Ele veio no `node_modules` do planner, e é o Vue, compilador de templates incluído,
como um módulo só:

```
ana@dev:~/vue$ mkdir adopt && cd adopt
ana@dev:~/vue/adopt$ cp ../planner/node_modules/vue/dist/vue.esm-browser.prod.js .
ana@dev:~/vue/adopt$ ls
vue.esm-browser.prod.js
```

Depois a página. Imagine que os dois primeiros elementos já estavam lá, escritos por outra pessoa, e
que pediram a você para acrescentar um contador:

```schooling-example
{"language": "html", "file": "index.html", "parts": [
 {"code": "<!DOCTYPE html>\n<html lang=\"en\">\n  <head>\n    <meta charset=\"utf-8\">\n    <title>Our study group</title>\n  </head>\n  <body>\n    <h1>Our study group</h1>\n    <p>We meet on Thursdays. This paragraph is plain HTML.</p>", "note": "Uma página comum. Nada aqui sabe do Vue, e nada vai mexer nela."},
 {"code": "    <div id=\"counter\">\n      <p>{{ minutes }} minutes studied today</p>\n      <button @click=\"minutes += 25\">Add a 25-minute session</button>\n    </div>", "note": "O único elemento entregue ao Vue. O conteúdo dele é o template: o navegador o lê como HTML, e o Vue o compila ali mesmo."},
 {"code": "    <script type=\"module\">\n      import { createApp, ref } from './vue.esm-browser.prod.js'\n\n      createApp({\n        setup() {\n          return { minutes: ref(0) }\n        },\n      }).mount('#counter')\n    </script>\n  </body>\n</html>", "note": "Importado direto do arquivo ao lado da página. O `setup()` devolve o que o template pode ler, que é a forma longa do que o `<script setup>` faz por você."}
]}
```

Uma página aberta do disco não consegue importar um módulo, então sirva a pasta. O Python vem com o
Ubuntu, e isto inicia um servidor web simples num **segundo terminal**, dentro de `~/vue/adopt`:

```sh
python3 -m http.server 8000
```

Depois clique duas vezes no botão:

```
ana@dev:~/vue/adopt$ look http://localhost:8000/ --do 'click button' --do 'click button' --text body
-- click button
-- click button
== the text of body
Our study group

We meet on Thursdays. This paragraph is plain HTML.

50 minutes studied today

Add a 25-minute session
```

**O título e o primeiro parágrafo ficaram intactos, e o contador conta.** O `ref(0)` é assunto da
aula 2; aqui basta que mudar `minutes` mudou o parágrafo.

## Por que os projetos raramente ficam assim

Funciona, e para um widget numa página renderizada no servidor é a ferramenta certa. Para uma
aplicação deixa de escalar, por três motivos que dá para ver daqui:

| sem build | com o Vite e arquivos `.vue` |
|---|---|
| o template é compilado no navegador, a cada visita, por um build do Vue que carrega o compilador | compilado uma vez, na sua máquina; o navegador recebe o runtime, menor |
| um componente é um objeto num `<script>`, com o template numa string ou na página | um componente é um arquivo, com a marcação, a lógica e o estilo juntos |
| um erro no template aparece quando alguém abre a página | aparece no terminal no momento em que você salva, como as falhas da instalação mostraram |

O tamanho dá para medir. O arquivo que você copiou inclui o compilador, e o runtime que o planner
entrega na aula 17 não:

```
ana@dev:~/vue/adopt$ ls -l vue.esm-browser.prod.js ../planner/node_modules/vue/dist/vue.runtime.esm-browser.prod.js
-rw-r--r-- 1 ana ana 113290 Oct 23 19:33 ../planner/node_modules/vue/dist/vue.runtime.esm-browser.prod.js
-rw-r--r-- 1 ana ana 175436 Oct 23 19:33 vue.esm-browser.prod.js
```

**O compilador são 62 kB dos 175**, cerca de um terço, enviados a cada visitante para que o navegador
dele faça um trabalho que a sua máquina poderia ter feito uma vez. Pare o servidor com Ctrl-C; o
terminal dele mostra as duas requisições que a página fez:

```
ana@dev:~/vue/adopt$ python3 -m http.server 8000
127.0.0.1 - - [23/Oct/2026 19:33:54] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 19:33:54] "GET /vue.esm-browser.prod.js HTTP/1.1" 200 -
```

**O resto do curso trabalha no planner**, com o build, porque é assim que aplicações Vue são escritas.
Quando você encontrar uma página renderizada no servidor com Vue salpicado nela, vai saber o que está
vendo.
