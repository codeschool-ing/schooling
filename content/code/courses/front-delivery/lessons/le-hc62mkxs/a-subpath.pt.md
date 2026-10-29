---
title: Um site numa pasta, e o caminho base
version: 1
---

**Um site servido de uma pasta, e não da raiz do seu endereço, precisa ser construído sabendo o nome da
pasta.** Esta é a diferença entre os quatro hosts que mais quebra primeiros deploys, e o GitHub Pages é
onde as pessoas a encontram. Um repositório chamado `planner` é publicado em
`https://<user>.github.io/planner/`, não na raiz de um domínio, e um build feito para `/` fica quebrado
ali de um jeito que parece nada: uma página em branco, e nenhum erro nela.

## Quebrado, de propósito

Um host estático servindo uma pasta é fácil de imitar: ponha o build dentro de uma pasta chamada
`planner` e sirva a pasta acima dela. Construa como antes, copie, e inicie o `host.mjs` na nova raiz:

```
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ rm -rf site && mkdir site && cp -r dist site/planner
ana@dev:~/planner$ grep -o 'src="[^"]*"' site/planner/index.html
src="/assets/index-BVi82VJx.js"
```

Depois peça a página, e o script que a página cita, como um navegador pediria:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/planner/
200
ana@dev:~/planner$ js=$(grep -o '/assets/[^"]*\.js' site/planner/index.html); echo $js
/assets/index-BVi82VJx.js
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:8080$js"
404
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um site publicado na pasta planner do seu endereço. A pasta tem index.html e assets. Uma página construída para a raiz pede /assets/index.js, que se resolve a partir da raiz do endereço, fora da pasta, onde não há nada: 404. Construída com base /planner/, pede /planner/assets/index.js, dentro da pasta: 200.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">https://ana.github.io/</text><rect x=\"20\" y=\"40\" width=\"340\" height=\"170\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a raiz do endereço</text><rect x=\"130\" y=\"80\" width=\"210\" height=\"115\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">planner/</text><text x=\"150\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">index.html</text><text x=\"150\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">assets/index.js</text><text x=\"150\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">courses.json</text><text x=\"72\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nada</text><text x=\"72\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">aqui</text><text x=\"390\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">construída para /</text><text x=\"390\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">src=\"/assets/index.js\"</text><path d=\"M 385 112 C 350 55, 60 50, 72 126\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"548\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">404</text><text x=\"390\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">construída com base /planner/</text><text x=\"390\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">src=\"/planner/assets/index.js\"</text><line x1=\"388\" y1=\"172\" x2=\"344\" y2=\"150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"344.0,150.0 352.0,150.5 349.2,156.1\" fill=\"var(--phosphor)\"></polygon><text x=\"592\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">200</text></svg>", "caption": "Um caminho que começa com / é resolvido a partir da raiz do endereço, então um site numa pasta precisa ser construído com o nome da pasta."}
```

**A página é achada e o script não.** O `index.html` diz `src="/assets/…"`, e um caminho que começa com
`/` é resolvido a partir da raiz do endereço, então o navegador pede `/assets/…` e não
`/planner/assets/…`. No navegador você ganha uma página em branco; o console diz que o script não
carregou, e nada na página diz coisa alguma. O registro do host diz exatamente qual requisição errou:

```
ana@dev:~/planner$ node host.mjs site
serving site on http://127.0.0.1:8080
200 GET /planner/
404 GET /assets/index-BVi82VJx.js
```

## Construído para a pasta

A opção `base` do Vite é o caminho de onde o site vai ser servido, e ela muda três coisas de uma vez: os
caminhos que o build grava no `index.html`, o valor de `import.meta.env.BASE_URL` com que todo link e o
`fetch` do planner começam, e nada mais. Passe-a na linha de comando:

```
ana@dev:~/planner$ npm run build -- --base=/planner/ > /dev/null
ana@dev:~/planner$ rm -rf site && mkdir site && cp -r dist site/planner
ana@dev:~/planner$ grep -o 'src="[^"]*"' site/planner/index.html
src="/planner/assets/index-Cch1FzyD.js"
ana@dev:~/planner$ js=$(grep -o '/planner/assets/[^"]*\.js' site/planner/index.html)
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:8080$js"
200
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/planner/courses.json
200
```

O `--` entrega o que vem depois ao script, e não ao `npm`. Agora a página cita `/planner/assets/…`, o
script é achado, e os dados que o script busca também, porque o `main.ts` pede `${base}courses.json`.
Abra `http://127.0.0.1:8080/planner/` no navegador e o planner funciona, com links para
`/planner/course/git` e o resto.

## Na linha de comando, ou na configuração

O guia do Vite define `base` no `vite.config.ts`. Isso está certo quando o site mora num lugar só. O
planner pode ser servido de `/planner/` pelo GitHub Pages e de `/` pelos outros três, então este curso
mantém o padrão no projeto e **põe o `--base` onde o deploy é decidido**, no workflow do GitHub Pages da
seção anterior. Assim um build feito para um host não vaza para outro.

Duas coisas que `base` não resolve, e as duas são da aula 4:

- **um caminho que o app montou à mão sem ele.** Um `fetch("/courses.json")` ou um `href="/course/git"`
  escrito literalmente ignora `base` e quebra na pasta. O planner não tem nenhum, porque todo caminho
  nele começa com `import.meta.env.BASE_URL`; uma busca por `"/` em `src/` acha algum que escape.
- **um endereço digitado ou salvo nos favoritos.** Aberto pelo próprio link, `/planner/course/git`
  funciona, porque foi o app que o desenhou. Digitado na barra de endereço, ou recarregado, ele é um
  pedido ao host por um arquivo chamado `course/git`, e não há nenhum:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/planner/course/git
404
ana@dev:~/planner$ rm -rf site
```

Esse 404 é o mesmo em todo host estático até que alguém o instrua do contrário, e cada um é instruído
do seu jeito. A aula 4 instrui os quatro. A pasta `site` era só uma imitação do host; o último comando a
removeu, e o próximo build sem `--base` grava a versão para `/` de novo.
