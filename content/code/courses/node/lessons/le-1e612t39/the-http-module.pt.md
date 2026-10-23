---
title: O que o node:http dá a você
version: 1
---

**O `node:http` transforma bytes num socket em dois objetos e os entrega à sua função: a requisição,
que você lê, e a resposta, que você escreve.** Todo o resto desta aula, e tudo o que o Express faz nas
aulas 6 e 7, é construído sobre esses dois objetos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Os bytes de uma requisição no socket, em ordem de tempo: a linha da requisição, os cabeçalhos, depois dois pedaços de corpo. Assim que os cabeçalhos estão completos, o Node chama o seu handler com req e res. Os pedaços do corpo chegam depois e são lidos do req como um stream. O handler escreve a resposta no res, que volta pelo mesmo socket.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">bytes chegando no socket</text><rect x=\"20\" y=\"36\" width=\"144\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"92.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /links HTTP/1.1</text><rect x=\"174\" y=\"36\" width=\"144\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"246.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cabeçalhos</text><rect x=\"330\" y=\"36\" width=\"114\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"387.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">corpo, pedaço 1</text><rect x=\"460\" y=\"36\" width=\"114\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"517.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">corpo, pedaço 2</text><line x1=\"20\" y1=\"80\" x2=\"700\" y2=\"80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"700.0,80.0 692.6,83.1 692.6,76.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"700\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><line x1=\"322\" y1=\"66\" x2=\"322\" y2=\"118\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"150\" y=\"120\" width=\"280\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">o evento 'request'</text><text x=\"290\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">handler(req, res)</text><text x=\"330\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">cabeçalhos completos</text><path d=\"M391 66 C 391 100, 451 110, 481 140\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"479\" y1=\"137\" x2=\"481\" y2=\"140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"481.0,140.0 474.3,135.6 479.5,132.1\" fill=\"var(--phosphor)\"></polygon><path d=\"M521 66 C 521 100, 581 110, 611 140\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"609\" y1=\"137\" x2=\"611\" y2=\"140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"611.0,140.0 604.3,135.6 609.5,132.1\" fill=\"var(--phosphor)\"></polygon><rect x=\"500\" y=\"140\" width=\"200\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">for await (chunk of req)</text><rect x=\"150\" y=\"210\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">res.writeHead(…)   res.end(…)</text><line x1=\"290\" y1=\"174\" x2=\"290\" y2=\"208\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"290.0,208.0 286.9,200.6 293.1,200.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"440\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">volta pelo mesmo socket</text></svg>", "caption": "O seu handler roda quando os cabeçalhos chegam, antes do corpo. O corpo é lido do req à medida que chega."}
```

Em ordem, para uma requisição:

1. Um cliente abre uma conexão TCP com a porta onde o servidor escuta. A libuv entrega o socket ao
   loop, como a aula 2 mostrou, e nenhuma thread espera por ele.
2. Bytes chegam. O **llhttp**, o parser embutido no Node, lê a linha da requisição e os cabeçalhos.
3. Assim que os cabeçalhos estão completos — **antes de o corpo chegar** — o Node cria um
   `http.IncomingMessage` e um `http.ServerResponse` e emite o evento `'request'` do servidor, que
   chama a sua função com os dois.
4. A sua função lê o que precisa da requisição, decide, e escreve o status, os cabeçalhos e o corpo na
   resposta.
5. O `res.end()` encerra a resposta. A conexão continua aberta para a próxima requisição do cliente,
   a não ser que um dos lados diga o contrário.

O passo 3 tem uma consequência sobre a qual a aula 8 constrói: **a requisição é um stream de leitura e
a resposta é um stream de escrita.** O corpo chega em pedaços, depois de a sua função já ter sido
chamada, e você o lê à medida que vem, que é o que a seção sobre ler um corpo faz. Uma resposta
também pode ser escrita em pedaços.

## O que ele não dá

O `node:http` lê o protocolo e mais nada. Não há roteamento: toda requisição, para todo caminho e
todo método, chega à mesma função. Não há leitura de corpo, nem JSON, nem cookies, nem arquivos
estáticos, nem erros transformados em respostas. **É isso que esta aula escreve à mão**, em pouco mais
de cem linhas, para que a aula 6 possa mostrar exatamente quais dessas linhas o Express escreve por
você. O serviço é o encurtador de links da organização da aula 3, construído numa pasta própria,
`~/server/native`, sem dependência nenhuma no `package.json`.
