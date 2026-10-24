---
title: Depois de instalado
version: 1
---

**Um planner instalado é o mesmo planner numa moldura diferente.** Toda aula anterior continua valendo, e algumas
coisas mudam.

- **A janela** é a do manifesto: sem barra de endereço com `standalone`, a cor do tema na barra de título, o nome e o
  ícone na lista de janelas do sistema. Um link para um endereço fora do `scope` abre no navegador em vez de dentro
  do app.
- **O começo** é o `start_url`, seja de que página a pessoa o instalou. O do planner é `/`, então o app sempre abre
  na lista de cursos.
- **A página consegue saber.** A media query de CSS `(display-mode: standalone)`, e a mesma no `matchMedia` de um
  script, é verdadeira dentro do app instalado, e é assim que uma página esconde o botão de instalar, ou um link que
  só faz sentido num navegador, depois de instalada.
- **As atualizações são do service worker.** Não há loja nem versão para baixar: na próxima vez que o app abre, o
  navegador confere o `/sw.js` como a aula 10 descreveu, e as páginas novas vêm do servidor como sempre vieram. O
  próprio manifesto também é conferido de tempos em tempos, e um ícone ou nome mudado chega ao app instalado, no
  Chromium depois de um atraso e às vezes com uma pergunta à pessoa.

## Um armazenamento que fica

**Um navegador pode apagar os dados de um site quando o disco fica cheio**, os caches do service worker inclusive, e
um app instalado é um que a pessoa disse que quer manter. O `navigator.storage.persist()` pede que os dados do site
sejam mantidos a menos que a própria pessoa os apague; o Chromium concede isso com mais facilidade a apps instalados,
e o `navigator.storage.estimate()` diz quanto o site usa e pode usar. O planner não guarda nada que não possa buscar
de novo, então não pede; um app que guarda o trabalho de uma pessoa offline deveria pedir.

## Desinstalando

Pelo menu do próprio app, ou pela lista de aplicativos do sistema, como qualquer outro. **O que vai junto é a janela e
o ícone, não os dados**: os dados do site pertencem ao site, no navegador, e ficam até a pessoa apagá-los lá.
