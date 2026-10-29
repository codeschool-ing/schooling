---
title: O payload, o que atravessa do servidor para o navegador
version: 1
---

**O payload são os dados que o servidor buscou ao renderizar uma página, escritos na página como um
`<script>` que o navegador lê antes de hidratar.** É assim que o `useFetch` do lado do navegador acha
a sua resposta sem perguntar, e ele está no HTML de toda página renderizada no servidor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"O que uma visita à página da semana faz com o useFetch. No servidor, renderizar a página roda o useFetch, que chama GET /api/courses dentro do servidor, e a resposta é usada duas vezes: para desenhar o HTML, e escrita na página como o payload, o script __NUXT_DATA__. O navegador recebe o HTML e o payload juntos, mostra o HTML, e quando hidrata, o useFetch no navegador acha a resposta no payload sob a mesma chave e não faz requisição. Um $fetch simples no setup não tem chave nem payload, então o navegador pergunta à API uma segunda vez.\"><rect x=\"20\" y=\"30\" width=\"300\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"170\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o servidor</text><rect x=\"40\" y=\"62\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useFetch(...)</text><rect x=\"190\" y=\"62\" width=\"110\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/api/courses</text><line x1=\"162\" y1=\"79\" x2=\"188\" y2=\"79\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"188.0,79.0 180.6,82.1 180.6,75.9\" fill=\"var(--wire)\"></polygon><rect x=\"40\" y=\"130\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">HTML</text><rect x=\"180\" y=\"130\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">__NUXT_DATA__</text><line x1=\"100\" y1=\"98\" x2=\"100\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"100.0,128.0 96.9,120.6 103.1,120.6\" fill=\"var(--wire)\"></polygon><line x1=\"245\" y1=\"98\" x2=\"240\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"240.0,128.0 238.1,120.2 244.3,121.2\" fill=\"var(--wire)\"></polygon><text x=\"170\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a resposta, usada duas vezes</text><rect x=\"400\" y=\"30\" width=\"300\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"550\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o navegador</text><rect x=\"420\" y=\"62\" width=\"260\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mostra o HTML na hora</text><rect x=\"420\" y=\"120\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useFetch(...)</text><text x=\"550\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">acha a chave no payload</text><line x1=\"322\" y1=\"147\" x2=\"418\" y2=\"142\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,142.0 410.8,145.5 410.5,139.3\" fill=\"var(--amber)\"></polygon><line x1=\"322\" y1=\"100\" x2=\"418\" y2=\"79\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,79.0 411.5,83.6 410.1,77.5\" fill=\"var(--phosphor)\"></polygon><text x=\"550\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nenhuma requisição: nada a perguntar</text></svg>", "caption": "O payload é a resposta do servidor levada dentro da página, para o navegador não perguntar de novo."}
```

Aqui está ele no HTML da semana:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/ | grep -o '<script type="application/json"[^>]*>'
<script type="application/json" data-nuxt-logs="nuxt-app">
<script type="application/json" data-nuxt-data="nuxt-app" data-ssr="true" id="__NUXT_DATA__">
```

O segundo, `__NUXT_DATA__`, é o payload. O começo dele:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/ | grep -o 'id="__NUXT_DATA__">[^<]*' | cut -c1-420
id="__NUXT_DATA__">[["ShallowReactive",1],{"data":2,"state":45,"once":47,"_errors":48,"serverRendered":24,"path":50},["ShallowReactive",3],{"session-count":4,"$f7xzspbwcnt2l":5},6,{"courses":6,"sessions":19},[7,11,15],{"id":8,"title":9,"goal":10},"statistics","Statistics",180,{"id":12,"title":13,"goal":14},"spanish","Spanish",120,{"id":16,"title":17,"goal":18},"guitar","Guitar",90,[20,25,29,32,37,41],{"id":21,"course
```

**É JSON num formato próprio**, escrito por uma biblioteca chamada `devalue`: um array só, em que
cada valor é escrito uma vez e todo o resto aponta para ele pela posição. `{"data":2,…}` quer dizer
*os dados são o item 2*; o item 3 liga cada chave ao seu item, e os cursos vêm depois dele. O formato
consegue dizer o que o JSON não consegue, um `Date`, um `Map`, um ref, e um valor usado duas vezes é
guardado uma vez. Procure as duas chaves da seção anterior:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/ | grep -o 'id="__NUXT_DATA__">[^<]*' | grep -o '"session-count":-\?[0-9]*\|"\$f[a-z0-9]*":-\?[0-9]*'
"session-count":4
"$f7xzspbwcnt2l":5
"session-count":-1
"$f7xzspbwcnt2l":-1
```

`session-count` é a chave do layout, e `$f…` a chave que o `useFetch` fez a partir da URL, cada uma
apontando para o item que guarda os seus dados; o item 4 é `6`, os dados do layout, um número, porque
o `transform` rodou no servidor antes de o payload ser escrito. O segundo par é o mapa de erros, e
`-1` é como o `devalue` escreve `undefined`: nenhuma das buscas falhou. **O que a função devolve, e só
isso, é o que atravessa.**

## O payload é público

O payload faz parte da página, então qualquer pessoa que consegue abrir a página consegue lê-lo, com
*ver código-fonte* ou com `curl`, e tudo o que o servidor buscou ao renderizar está nele, o template
usando ou não. Meça a página, o payload dentro dela e a resposta da própria API:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/ | wc -c
5081
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/ | grep -o 'id="__NUXT_DATA__">[^<]*' | wc -c
956
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/api/courses | wc -c
1051
```

**O payload tem 956 bytes dos 5.081 da página**, menos que a resposta de 1.051 da API porque o
`devalue` escreve cada valor repetido uma vez, e todo valor daquela resposta está nele. No planner,
cada byte da resposta da API é para o leitor. A coisa muda quando uma rota do servidor devolve um
registro inteiro, uma conta com o e-mail e o hash da senha, e a página mostra um nome: o template
esconde o resto da tela, e o payload o entrega a cada visitante. O `transform`, ou `pick: ['name']`
no caso simples, roda no servidor e deixa um campo assim fora do payload. Eles não o deixam fora da
rota, que responde a qualquer um que chame `/api/…` diretamente, com `curl` como aqui. **Então uma
rota do servidor devolve o que quem a chama pode ver, e nada mais**, e um campo que precisa ficar
privado para na rota.
