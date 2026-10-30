---
title: O que um crawler lê
version: 1
---

**Um programa que lê a sua página sem rodar os seus scripts vê exatamente o que o
`look.ts --no-js` imprimiu.** Para o planner renderizado no cliente, isso é nada; para o
renderizado no servidor, é a página inteira. Quais programas são esses, e quanto isso importa, é
menos resolvido do que costuma parecer, então esta seção separa o que está documentado do que é
folclore.

## Buscadores

O folclore diz que buscadores não conseguem indexar um site renderizado no cliente. **A
documentação do Google diz que o Googlebot roda JavaScript**: ele busca a página, a põe numa fila
para renderizar, a renderiza com um Chromium recente e indexa o resultado. O que a mesma
documentação também diz é que a renderização é uma segunda etapa, que pode vir depois da primeira
busca, e que renderizar no servidor ou pré-renderizar continua sendo uma boa ideia, porque deixa o
site mais rápido para as pessoas e para os crawlers. Outros buscadores documentam menos, e um
crawler que não roda scripts vê um `<main>` vazio.

Então a posição honesta é esta: uma página renderizada no cliente pode ser indexada pelo maior
buscador, e todo crawler que lê a primeira resposta vê na hora uma página renderizada no servidor.
**Se ser encontrado importa, renderize no servidor ou no build**, e nada na página depende da
paciência de um crawler.

## Prévias de link

Quando um link é colado num app de mensagens ou numa rede social, um programa nos servidores
daquela empresa busca a página e procura um título, uma descrição e uma imagem para mostrar. Eles
são escritos como tags `<meta>` no `<head>`, geralmente no vocabulário Open Graph:

```html
<meta property="og:title" content="Git · Study planner">
<meta property="og:description" content="2 sessions planned this week">
```

**Esses programas não rodam JavaScript.** A prévia de uma página renderizada no cliente mostra o
que o `index.html` estático diz, o mesmo para todo endereço do site. Uma página renderizada no
servidor consegue pôr um título e uma descrição para cada endereço na resposta, porque sabe qual
endereço está desenhando. O `server.ts` do planner troca só o `<main>`; fazer o mesmo com o
`<title>` e com essas tags é um segundo `replace` na mesma string.

## Todo o resto que lê HTML

Leitores de tela e extensões do navegador leem a página depois de os scripts rodarem, então o lugar
da renderização não muda o que eles veem depois que a página carregou. Um modo de leitura, um
serviço de tradução e um programa que guarda a página para depois podem ler a primeira resposta. E
uma pessoa num trem atravessando um túnel vê a primeira resposta pelo tempo que o script levar. Esse
último leitor é o que a próxima seção mede.
