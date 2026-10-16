---
title: Variáveis, e qual delas vence
version: 1
---

**Uma variável é um nome entre chaves duplas que o Postman substitui antes de a requisição sair.**
Escreva `{{baseUrl}}/v1/shows` e o Postman procura `baseUrl`, encontra `http://localhost:8080` e
manda `http://localhost:8080/v1/shows`. O servidor nunca vê as chaves. Variáveis funcionam em
qualquer parte de uma requisição: o endereço, um cabeçalho, o corpo, a autorização.

A primeira variável que toda coleção ganha é o endereço do servidor, e o motivo é o dia em que o
servidor muda de lugar. Vinte requisições que escrevem `http://localhost:8080` por extenso são vinte
edições quando os mesmos testes precisam rodar num servidor de teste. Vinte requisições que dizem
`{{baseUrl}}` são uma.

## Cinco lugares onde uma variável pode morar

**Um nome pode estar definido em mais de um lugar ao mesmo tempo, e vence o lugar mais estreito**,
não importa qual foi definido por último. A maioria das pessoas espera o contrário, que vale o valor
escrito mais recentemente, e perde uma tarde com isso. O Postman tem cinco escopos, do mais amplo ao
mais estreito:

| escopo | definido em | dura | serve para |
|---|---|---|---|
| global | o workspace | até ser apagado | quase nada; toda coleção o enxerga |
| coleção | a própria coleção | junto com a coleção | valores que pertencem a esta API: um id que as requisições compartilham |
| ambiente | o ambiente escolhido na lista do canto superior direito | até você trocar | o que muda de um servidor para outro: o endereço, as credenciais |
| dados | um CSV ou JSON entregue a uma execução | uma linha, uma iteração | muitos casos por uma requisição (lição 5) |
| local | um script, enquanto uma requisição roda | só aquela requisição | um valor calculado logo antes de mandar (lição 5) |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 276\" role=\"img\" aria-label=\"Cinco escopos empilhados do mais amplo ao mais estreito: global, coleção, ambiente, dados e local. showId está definida na coleção como sh-103 e no ambiente como sh-101, e não nos outros três. A requisição envia sh-101, porque o ambiente é o mais estreito dos dois escopos que a definem.\"><defs><marker id=\"f04scopes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"250\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">onde showId pode estar definida</text><text x=\"560\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o valor dela ali</text><rect x=\"100\" y=\"30\" width=\"300\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">global</text><text x=\"250\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o workspace</text><text x=\"540\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não definida</text><rect x=\"115\" y=\"70\" width=\"270\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">coleção</text><text x=\"250\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o arquivo da coleção</text><rect x=\"500\" y=\"74\" width=\"120\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"560\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sh-103</text><rect x=\"130\" y=\"110\" width=\"240\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ambiente</text><text x=\"250\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o ambiente ativo</text><rect x=\"500\" y=\"114\" width=\"120\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"560\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sh-101</text><rect x=\"145\" y=\"150\" width=\"210\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dados</text><text x=\"250\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma linha de um arquivo de dados</text><text x=\"540\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não definida</text><rect x=\"160\" y=\"190\" width=\"180\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">local</text><text x=\"250\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um script, para uma requisição</text><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não definida</text><line x1=\"40\" y1=\"34\" x2=\"40\" y2=\"218\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04scopes-ah)\"></line><text x=\"48\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mais estreito</text><rect x=\"470\" y=\"238\" width=\"180\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">enviado: sh-101</text><line x1=\"605\" y1=\"140\" x2=\"605\" y2=\"236\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f04scopes-ah)\"></line><text x=\"250\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vence o escopo mais estreito que define o nome</text></svg>", "caption": "O mesmo nome em dois escopos: vai o do mais estreito, não importa qual foi definido por último.", "same": ["global", "local"]}
```

Então um `showId` definido na coleção como `sh-103` e no ambiente como `sh-101` é mandado como
`sh-101`, porque o ambiente é mais estreito. Apague o do ambiente e o da coleção reaparece. Isso é
uma vantagem: a coleção traz um padrão razoável, e um ambiente sobrescreve só o que difere no
servidor dele.

**Uma variável que existe com valor vazio também vence.** Um `token` vazio no ambiente esconde um
`token` preenchido na coleção, e a requisição sai sem nada onde o token deveria estar. A lição 5
cai nisso de propósito, e mostra como fica visto de fora.

## Um nome que ninguém definiu

Quando nenhum escopo define um nome, o Postman o pinta de vermelho na requisição. Se você mandar
mesmo assim, ele manda as chaves como estão. `{{baseUrl}}/v1/shows` não é um endereço, e a
requisição falha antes de chegar a qualquer servidor. Quem testa confere também a outra direção:
**que nomes uma coleção usa, e cada um está definido em algum lugar?** A seção 06 pergunta isso da
coleção que você salvar, com uma linha de grep.
