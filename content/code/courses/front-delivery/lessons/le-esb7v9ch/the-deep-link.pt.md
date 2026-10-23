---
title: O link profundo, e o servidor que o escondeu
version: 1
---

**Um app cujos endereços são caminhos de verdade precisa que o host responda a cada um desses caminhos com
o `index.html`, e as ferramentas de desenvolvimento escondem essa necessidade até o primeiro deploy.** A
aula 1 terminou nisso: um link clicado dentro do planner funciona, porque o app desenha a tela; o mesmo
endereço digitado ou recarregado é um pedido ao host por um arquivo chamado `course/git`, e não há nenhum.

## Dois servidores, duas respostas

Peça o mesmo endereço ao servidor de preview do Vite e ao host do planner:

```
ana@dev:~/planner$ npm run preview

> planner@0.0.0 preview
> vite preview

  ➜  Local:   http://localhost:4173/
  ➜  Network: use --host to expose
```

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4173/course/git
200
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/course/git
404
```

**O servidor de preview respondeu 200 e o host 404.** O `vite preview` trata o projeto como um app de
página única e responde a qualquer caminho para o qual não tem arquivo com o `index.html`, o que é
conveniente e é exatamente o motivo de ele não ser um servidor de produção: ele perdoa um erro que todo
host estático vai punir. Um site conferido só com `npm run preview` é um site cujos links profundos nunca
foram testados.

## Uma reescrita

O conserto é uma regra com status 200, uma reescrita: para qualquer caminho, sirva `/index.html`, no
mesmo endereço.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Duas respostas a um pedido de /course/git. Um redirecionamento responde 301 com um novo endereço, e o navegador pede de novo em outro lugar, o que muda a barra de endereço. Uma reescrita responde 200 com o conteúdo de index.html no mesmo endereço, e o app lê o endereço e desenha o curso.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um redirecionamento</text><rect x=\"20\" y=\"52\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /course/git</text><line x1=\"180\" y1=\"70\" x2=\"260\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"260.0,70.0 252.6,73.1 252.6,66.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"262\" y=\"52\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"282\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">301</text><text x=\"320\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">location: /</text><text x=\"480\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a barra de endereço muda</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma reescrita</text><rect x=\"20\" y=\"132\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /course/git</text><line x1=\"180\" y1=\"150\" x2=\"260\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"260.0,150.0 252.6,153.1 252.6,146.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"262\" y=\"132\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"282\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">200</text><text x=\"320\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">index.html</text><text x=\"480\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mesmo endereço, o app desenha o curso</text></svg>", "caption": "Um redirecionamento manda o navegador para outro lugar; uma reescrita serve outro arquivo onde o navegador já está."}
```

Acrescente-a abaixo do redirecionamento, porque a primeira regra que bate decide e `/*` bate com tudo:

```
ana@dev:~/planner$ echo '/* /index.html 200' >> public/_redirects
ana@dev:~/planner$ cat public/_redirects
# public/_redirects
/courses/* /course/:splat 301
/* /index.html 200
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code} %{content_type}\n' http://127.0.0.1:8080/course/git
200 text/html; charset=utf-8
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code} %{content_type}\n' http://127.0.0.1:8080/course/nothing
200 text/html; charset=utf-8
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code} %{content_type}\n' http://127.0.0.1:8080/assets/nothing.js
200 text/html; charset=utf-8
```

O host ainda estava rodando e não precisou reiniciar: ele lê as regras a cada requisição. Agora
`/course/git` é um 200 com a página, o navegador roda o script do planner, e o script lê o endereço e
desenha o curso. Recarregar funciona, um favorito funciona, um link colado numa conversa funciona.

## Os dois preços de uma regra que pega tudo

A última linha daquela transcrição é o primeiro preço. `/assets/nothing.js` não existe, e a regra o
respondeu com a página, como HTML, com um 200. **Um script que falta agora parece uma página para toda
ferramenta que confere códigos de status**, e o navegador que pediu um script e recebeu HTML se recusa a
rodá-lo, com um erro sobre o tipo MIME, e não sobre um arquivo faltando. Esse erro é o que um visitante
recebe quando um `index.html` velho pede scripts de um build anterior, que a aula 1 chamou de motivo para
uma versão publicada ser a pasta inteira de uma vez.

O segundo preço é a tela *Not found* do próprio planner. `/course/nothing` também é um 200 agora, porque o
host não tem como saber quais cursos existem; só o app sabe, e ele desenha *Not found* numa página que o
servidor chamou de sucesso. Isso se chama **soft 404**: certo para uma pessoa, errado para um robô de busca
ou um monitor que lê códigos de status. Para um app como este é a troca aceita, e vale saber que ela foi
feita.

## Um host sem regras

O GitHub Pages não lê arquivo de regras, então não consegue reescrever. O que ele faz é servir o
`404.html` do site para qualquer caminho para o qual não tem arquivo. Uma cópia do `index.html` salva como
`404.html` é então o app, servido para todo caminho desconhecido, com o status 404. Faça uma cópia do
build do jeito que o GitHub Pages a guardaria, sem o arquivo de regras que ele ignoraria, sirva-a com
`node host.mjs /tmp/pages 8081` em outro terminal, e peça um curso:

```
ana@dev:~/planner$ rm -rf /tmp/pages && cp -r dist /tmp/pages && rm /tmp/pages/_redirects
ana@dev:~/planner$ cp /tmp/pages/index.html /tmp/pages/404.html
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code} %{size_download}\n' http://127.0.0.1:8081/course/git
404 482
ana@dev:~/planner$ wc -c < /tmp/pages/index.html
482
```

A página chega inteira, os mesmos bytes do `index.html`, e o planner desenha o curso. O status é 404, em
todo link profundo. Uma pessoa nunca percebe; um buscador trata cada uma dessas páginas como ausente, e um
verificador de links diz que o site inteiro está quebrado. É o contorno padrão para o GitHub Pages e é um
contorno: um app que precisa dos links profundos indexados pertence a um host com regras, ou a endereços
com hash como `#/course/git`, que nunca chegam ao servidor.
