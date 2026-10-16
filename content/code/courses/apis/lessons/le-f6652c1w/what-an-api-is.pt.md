---
title: O que é uma API
version: 1
---

**Uma API é uma promessa que um programa faz a outro.** Ela diz quais perguntas podem ser feitas,
como fazê-las e que forma a resposta vai ter. A página que uma pessoa lê pode mudar toda semana; uma
API não pode, porque do outro lado existe o código de outra pessoa, escrito contra a promessa, que vai
quebrar no dia em que ela deixar de ser verdade.

Essa é toda a dificuldade do assunto, e é por isso que este curso gasta tanto tempo com **contratos**
quanto com código. A aula 2 trata da forma do que vai e volta, a aula 6 de escrever a promessa de um
jeito que uma máquina consiga conferir, e todas as aulas de segurança, da 7 à 13, de quem tem permissão
para perguntar.

## Quatro estilos, um trabalho

Há mais de um jeito de fazer a promessa. Os quatro que este curso cobre estão em uso hoje, muitas
vezes dentro da mesma empresa:

| estilo | o que uma requisição nomeia | o que viaja | aula |
|---|---|---|---|
| **REST** | um recurso, pelo endereço dele | JSON sobre HTTP, na maioria das vezes | esta |
| **GraphQL** | os campos que o cliente quer | uma consulta, uma resposta JSON | 3 |
| **gRPC** | um procedimento de um serviço | Protocol Buffers sobre HTTP/2 | 4 |
| **SOAP** | uma operação de um WSDL | um envelope XML | 5 |

REST vem primeiro porque os outros três se entendem melhor como respostas a algo que o REST faz mal, e
porque a maioria das APIs que você vai encontrar no primeiro emprego é REST.

## O que REST é, e o que não é

REST não é um protocolo nem uma biblioteca. É um **estilo de arquitetura**, descrito por Roy Fielding
na tese de doutorado dele em 2000, e a ideia central cabe numa frase: **o servidor expõe recursos, cada
um com um endereço, e os clientes agem sobre eles com o pequeno conjunto de métodos que o HTTP já
tem.** Um livro é um recurso. O endereço dele é `/v1/books/3`. Ler é `GET`, alterar é `PUT` ou
`PATCH`, remover é `DELETE`.

A imagem errada mais comum é que REST quer dizer "JSON sobre HTTP". Muitas APIs mandam JSON sobre HTTP
e não são REST de jeito nenhum: um endereço só, `/api`, e toda requisição é um `POST` cujo corpo diz o
que fazer. Esse desenho funciona, e é o formato das chamadas de procedimento remoto que a aula 4
descreve. O que ele perde é tudo o que o HTTP já sabe fazer com um recurso: guardar um `GET` em cache,
repetir um `PUT` com segurança, dizer "não encontrado" de um jeito que qualquer cliente do mundo
entende.

Mais duas restrições importam na prática. **Cada requisição carrega tudo o que é preciso para
respondê-la**, então o servidor não guarda memória da conversa entre uma requisição e outra; é isso que
permite rodar dez cópias de um servidor atrás de um balanceador de carga. E **o que viaja é uma
representação**, não a coisa em si: o livro no banco é uma linha, e o que o cliente recebe é um
documento JSON montado a partir dela. Os dois podem mudar de forma independente, e a seção sobre
versionamento desta aula depende disso.

## Uma troca, desmontada

Tudo neste curso se apoia na mesma troca, então vale ver as partes dela uma vez. O cliente envia uma
**requisição**: uma linha com o método, o caminho e a versão do protocolo, depois os cabeçalhos, depois,
às vezes, um corpo. O servidor envia uma **resposta**: uma linha de status, cabeçalhos e, quase
sempre, um corpo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"Uma requisição vai do curl ao shelf: a linha GET /v1/books/3 HTTP/1.1, depois cabeçalhos como Host e Accept, depois um corpo opcional. A resposta volta: a linha de status HTTP/1.1 200 OK, cabeçalhos como Content-Type e Content-Length, depois o corpo JSON.\"><defs><marker id=\"rr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"105\" width=\"110\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curl</text><text x=\"75.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o cliente</text><rect x=\"570\" y=\"105\" width=\"110\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rest.py</text><text x=\"625.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o servidor</text><rect x=\"170\" y=\"20\" width=\"360\" height=\"105\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"182\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">requisição</text><text x=\"182\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET /v1/books/3 HTTP/1.1</text><text x=\"182\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Host: localhost:8000</text><text x=\"182\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Accept: */*</text><text x=\"182\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">(um corpo, para POST, PUT e PATCH)</text><text x=\"518\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">linha</text><text x=\"518\" y=\"87\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">cabeçalhos</text><rect x=\"170\" y=\"145\" width=\"360\" height=\"110\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"182\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">resposta</text><text x=\"182\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HTTP/1.1 200 OK</text><text x=\"182\" y=\"203\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Content-Type: application/json</text><text x=\"182\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Content-Length: 128</text><text x=\"182\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{&quot;id&quot;: 3, &quot;title&quot;: &quot;A Hora da Estrela&quot;, …}</text><text x=\"518\" y=\"183\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">status</text><text x=\"518\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">cabeçalhos</text><text x=\"518\" y=\"241\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">corpo</text><line x1=\"130\" y1=\"125\" x2=\"168\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#rr-ah)\"></line><line x1=\"532\" y1=\"90\" x2=\"568\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#rr-ah)\"></line><line x1=\"568\" y1=\"150\" x2=\"532\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#rr-ah)\"></line><line x1=\"168\" y1=\"190\" x2=\"130\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#rr-ah)\"></line></svg>", "caption": "Uma troca. Tudo o que uma API diz viaja nestas três partes, nos dois sentidos.", "same": ["status"]}
```

Os cabeçalhos são onde acontece a maior parte do trabalho interessante, e eles voltam muitas vezes.
`Content-Type` diz o que é o corpo, e `Location`, onde algo novo foi parar. `Authorization` leva uma
credencial na aula 7, e `Retry-After` diz ao cliente quanto esperar na aula 12.
