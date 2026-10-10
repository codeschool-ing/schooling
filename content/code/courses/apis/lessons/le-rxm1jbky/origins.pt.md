---
title: Origens e a política de mesma origem
version: 1
---

**Uma origem são três coisas juntas: o esquema, o host e a porta.** O navegador arquiva cada página
sob a origem dela, e não deixa uma página ler o que outra origem devolve, a não ser que essa origem
diga que pode. Essa regra é a política de mesma origem, e o CORS, assunto da maior parte desta lição,
é o jeito de um servidor dizer "pode".

Pegue a página que a próxima seção entrega, `http://localhost:8080/page.html`. A origem dela é
`http://localhost:8080`, e o caminho não entra na conta. Comparada com ela:

| endereço | mesma origem? | por quê |
|---|---|---|
| `http://localhost:8080/other.html` | sim | só o caminho muda |
| `http://localhost:8000/v1/books/1` | não | a porta muda |
| `https://localhost:8080/page.html` | não | o esquema muda |
| `http://127.0.0.1:8080/page.html` | não | o host muda, embora seja a mesma máquina |
| `http://api.localhost:8080/` | não | outro nome de host é outro host |

A quarta linha surpreende quase todo mundo. O navegador compara os nomes como strings; ele nunca
pergunta se dois nomes levam ao mesmo computador. **A API do shelf e a página dela estão numa máquina
só, com um nome só, e ainda assim são duas origens**, porque a porta faz parte da origem.

## O que a política bloqueia, e o que não bloqueia

A crença comum é que a política impede uma página de mandar requisições para outro site. Não impede,
e nunca impediu. Uma página sempre pôde mostrar uma imagem de qualquer lugar, carregar um script de
qualquer lugar e enviar um formulário para qualquer lugar, e o navegador envia tudo isso. **O que a
política bloqueia é a leitura.** Um script de uma origem pode causar uma requisição a outra, mas a
resposta fica longe dele.

São três casos, então:

- **Uma requisição que um formulário poderia mandar** (um GET, ou um POST de campos de formulário)
  sai na hora, e o servidor responde. Se a resposta não nomeia a origem da página, o navegador a
  esconde do script. O servidor fez o trabalho; só a página ficou sem o resultado.
- **Uma requisição que um formulário não poderia mandar** (um PATCH, um corpo JSON, um cabeçalho
  `Authorization`) é perguntada antes, com uma requisição separada que a seção sobre preflight
  desmonta. Se a resposta à pergunta for não, a requisição de verdade nunca é enviada.
- **Incorporar** uma imagem ou um script de outra origem continua funcionando, e o script da página
  continua sem conseguir ler os bytes.

O motivo da regra é a pessoa diante do teclado. O navegador manda os cookies de um site em toda
requisição a esse site, seja qual for a página que a causou; a lição 8 é sobre esses cookies. Sem a
política, qualquer página aberta numa aba poderia chamar a API do seu banco em seu nome e ler a
resposta. **A política protege quem usa o navegador, não o servidor**, e essa diferença está na raiz
da maioria dos erros de CORS.

Ela também explica quem a aplica. O `curl`, um script Python, um app de celular e outro servidor não
têm cookies de usuário para proteger nem política para aplicar: leem tudo o que volta. Só o navegador
aplica a política de mesma origem, e é por isso que os comandos curl das lições anteriores nunca
toparam com ela.
