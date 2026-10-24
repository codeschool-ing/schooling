---
title: Modos de histórico, e a parte do servidor
version: 1
---

**O router escreve o endereço de um de dois jeitos, e um deles precisa da ajuda do servidor.** Com
`createWebHistory()`, os endereços do planner são caminhos comuns, `/courses/spanish`. Com
`createWebHashHistory()`, eles são escritos depois de um `#`, `/#/courses/spanish`. Parece questão de
gosto, e a diferença está em quem responde quando o aluno recarrega a página.

## Um caminho de verdade pergunta ao servidor

Quando o aluno clica num `<RouterLink>`, nenhuma página nova é pedida, no máximo o código e os dados de
que a próxima tela precisa, como a seção de carregamento sob demanda mostrou: o router muda o endereço com a History API do
navegador e desenha a página. Quando o aluno **recarrega**, ou abre um favorito, o navegador pede
`/courses/spanish` ao servidor, e o servidor precisa responder com a aplicação, o mesmo `index.html` que
ele dá para `/`, para que o router possa começar e desenhar o curso.

O servidor de desenvolvimento faz isso, e a aula 2 o viu fazer isso com um arquivo de dados que faltava:

```
ana@dev:~/vue/planner$ curl -s http://localhost:5173/courses/spanish | grep -E '<title>|id="app"'
    <title>Study planner</title>
    <div id="app"></div>
```

**Ele respondeu `/courses/spanish` com o `index.html`.** Todo endereço para o qual ele não tem arquivo
recebe a aplicação, que é o **fallback** de que um router com caminhos de verdade precisa.

Um host estático nem sempre faz isso. Sirva os arquivos do build com um servidor web simples, o que vem
com o Python, iniciado num segundo terminal, e peça o mesmo endereço:

```
ana@dev:~/vue/planner$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/
200
ana@dev:~/vue/planner$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/courses/spanish
404
```

A raiz responde 200, com o `index.html` do build. **A página do curso responde 404.** Não existe arquivo
chamado `courses/spanish` em `dist`, e um servidor simples só responde por arquivos que existem. A
aplicação funciona quando o aluno começa em `/` e clica, e quebra no momento em que ele recarrega uma
página de curso ou compartilha o endereço dela. O terminal do próprio servidor registrou as duas
requisições; Ctrl-C o para:

```
ana@dev:~/vue/planner$ python3 -m http.server 8000 --directory dist
127.0.0.1 - - [23/Oct/2026 22:40:35] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 22:40:35] code 404, message File not found
127.0.0.1 - - [23/Oct/2026 22:40:35] "GET /courses/spanish HTTP/1.1" 404 -
```

## As duas correções

- **Configure o servidor para cair no `index.html`** em todo caminho que não é um arquivo. Todo host que
  serve aplicações de página única tem uma opção para isso, com um nome como *rewrites*, *redirects* ou
  *SPA mode*, e as aulas 1 e 4 de `front-delivery` tratam de hospedagem e redirecionamentos. O
  `npm run preview`, que serve o build com o Vite, já faz isso.
- **Use `createWebHashHistory()`.** A parte depois do `#` nunca é enviada ao servidor, então todo
  endereço é um pedido de `/`, e nenhum servidor precisa de configuração. O custo é o `#` em todo
  endereço, que parece antiquado e que os buscadores leem como uma página só.

**O planner usa caminhos de verdade**, como quase toda aplicação Vue, e o servidor dele, em
desenvolvimento e, a partir da aula 18, no Nuxt, é um que faz o fallback. Escolha o hash só quando você
não pode configurar o servidor de jeito nenhum, como numa aplicação aberta como arquivo do disco.
