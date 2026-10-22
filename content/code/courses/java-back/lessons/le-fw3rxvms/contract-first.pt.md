---
title: Código primeiro ou contrato primeiro
version: 1
---

Tudo nesta aula até aqui foi **código primeiro**: os controllers vieram antes e o documento foi
derivado deles. O contrário é **contrato primeiro**: a equipe escreve o documento OpenAPI, combina-o
com quem vai chamar a API, e só depois escreve código que o respeite. As duas formas são comuns, e a
diferença está em qual dos dois tem o direito de mudar o outro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 316\" role=\"img\" aria-label=\"Código primeiro: seus controllers, anotados, são lidos pelo springdoc em tempo de execução, e o documento OpenAPI segue o que o código fizer. Contrato primeiro: o openapi.yaml é escrito e revisado antes, e o OpenAPI Generator o transforma em interfaces do servidor, que seus controllers implementam, e numa biblioteca cliente na linguagem de quem chama. Em cada linha, a caixa de borda âmbar é onde uma mudança começa.\"><defs><marker id=\"l17b-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Código primeiro</text><rect x=\"20\" y=\"48\" width=\"170\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">seus controllers</text><text x=\"105.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">@GetMapping, @Operation</text><rect x=\"250\" y=\"48\" width=\"150\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"325.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">springdoc</text><text x=\"325.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">em tempo de execução</text><rect x=\"460\" y=\"48\" width=\"220\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o documento OpenAPI</text><text x=\"570.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">segue o que o código fizer</text><path d=\"M 190 76 L 248 76\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17b-ah)\"></path><path d=\"M 400 76 L 458 76\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17b-ah)\"></path><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Contrato primeiro</text><rect x=\"20\" y=\"190\" width=\"170\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">openapi.yaml</text><text x=\"105.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">escrito e revisado antes</text><rect x=\"250\" y=\"190\" width=\"150\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"325.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">OpenAPI Generator</text><text x=\"325.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">gera código</text><rect x=\"460\" y=\"168\" width=\"220\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">interfaces do servidor</text><text x=\"570.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">seus controllers as implementam</text><rect x=\"460\" y=\"226\" width=\"220\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma biblioteca cliente</text><text x=\"570.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">na linguagem de quem chama</text><path d=\"M 190 218 L 248 218\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17b-ah)\"></path><path d=\"M 400 210 C 430 210, 430 190, 458 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17b-ah)\"></path><path d=\"M 400 226 C 430 226, 430 248, 458 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17b-ah)\"></path><rect x=\"20\" y=\"292\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"297\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">onde uma mudança começa</text></svg>", "caption": "Os mesmos dois artefatos, o código e o documento, com a seta no sentido contrário.", "same": ["OpenAPI Generator"]}
```

## O que o código primeiro não pega

Um documento derivado do código sempre bate com o código, e isso é tanto o ponto fraco quanto o
ponto forte dele. Renomeie o parâmetro de busca de `q` para `text`, uma mudança que parece
arrumação:

```
ana@vm:~/bookshop$ sed -i 's/String q)/String text)/; s/search(q)/search(text)/; s/@param q the/@param text the/' src/main/java/com/example/bookshop/catalogue/BookController.java && grep -n 'text' src/main/java/com/example/bookshop/catalogue/BookController.java
57:     * Books whose title contains the text, ignoring case.
59:     * @param text the text to look for
64:    public List<BookResponse> search(@RequestParam String text) {
65:        return books.search(text);
```

Gere o build, reinicie e baixe o documento num segundo arquivo. O `~/api.json` ainda guarda o que
foi salvo na seção sobre anotações, então o `diff` pode comparar os dois:

```
ana@vm:~/bookshop$ curl -s localhost:8080/v3/api-docs | python3 -m json.tool > ~/api-renamed.json
ana@vm:~/bookshop$ diff ~/api.json ~/api-renamed.json
262c262
<                         "name": "q",
---
>                         "name": "text",
```

Uma linha do documento mudou, e a aplicação subiu sem dizer nada a respeito. Todo cliente que busca
com `?q=` agora está quebrado:

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' 'localhost:8080/books/search?q=time'
400
ana@vm:~/bookshop$ curl -s -w '\n' 'localhost:8080/books/search?text=time'
[{"id":2,"isbn":"9786500000023","title":"The Time Machine","author":"H. G. Wells","priceCents":2950,"stock":5}]
```

Nada no código primeiro recusa isso, porque o documento segue o que o código fizer. O que transforma
isso em algo que um revisor vê é guardar o documento ao lado do código: salvá-lo no repositório,
gerá-lo de novo a cada mudança e deixar a revisão mostrar o diff dele, como o `diff` acima fez. Um
nome de parâmetro mudado no documento de um pull request vira uma pergunta que alguém faz antes do
merge, e não depois da versão publicada.

Volte o parâmetro antes de seguir: substitua de novo o `BookController.java` pela versão da seção
anterior, gere o build e reinicie.

## Contrato primeiro

Uma equipe de contrato primeiro começa por um arquivo, em geral `openapi.yaml`, escrito à mão e
revisado como código pelas pessoas dos dois lados. Um gerador, quase sempre o **OpenAPI Generator**,
o lê e escreve as partes que precisam concordar com ele: no servidor, interfaces Java com as
anotações de mapeamento já colocadas, que seus controllers implementam; do lado do cliente, uma
biblioteca na linguagem de quem chama a API. Renomear `q` passa a ser uma mudança no contrato, feita
de propósito e revisada, e um controller que ainda diz `q` deixa de bater com a interface que
implementa.

Isso tem um custo. O gerador é mais uma ferramenta para configurar e atualizar, o código gerado é
escrito no estilo dele e não no seu, e uma regra como o dígito verificador do ISBN continua escrita
à mão no servidor, porque um schema consegue descrever uma string de treze dígitos, mas não a conta
feita sobre eles.

Qual caminho serve a uma equipe depende de quem chama a API. Uma API com um cliente só, escrito pelas
mesmas pessoas na mesma semana, vai bem com código primeiro e um documento guardado no repositório.
Uma API sobre a qual várias equipes, ou outras empresas, constroem antes de ela existir precisa do
contrato primeiro, porque essas pessoas não podem esperar o seu código para descobrir o que ele vai
dizer. A aula 6 de `apis` leva a especificação e o fluxo de contrato primeiro muito mais longe.
