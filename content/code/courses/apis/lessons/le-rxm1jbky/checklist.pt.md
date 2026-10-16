---
title: Antes de uma API entrar no ar
version: 1
---

**Uma lista de verificação só vale a pena se toda linha dela puder ser conferida.** "A API é segura"
não pode; "uma origem desconhecida não recebe `Access-Control-Allow-Origin`" pode, com um comando curl.
Esta reúne o curso inteiro em linhas do segundo tipo, cada uma com a aula que construiu a defesa.
Percorra-a contra a API implantada, de fora, do jeito que um cliente a vê, e não contra o código.

## O contrato

| verificação | como você vê | aula |
|---|---|---|
| todo erro é um código de status com que o cliente consegue agir, nunca um 200 com um erro dentro | mande cada erro de propósito e leia o código | 1 |
| campos desconhecidos ou de tipo errado são recusados | um PATCH com um campo a mais responde 422 | 1, 2 |
| a representação é montada campo a campo, e nada interno vaza para ela | leia uma resposta e pergunte por que cada campo está ali | 2 |
| todo endpoint e toda versão que responde está no contrato escrito | compare o documento OpenAPI com o que responde | 6 |
| versões antigas têm data para parar de responder, e param | peça a versão aposentada e espere uma recusa | 1, 6 |

## Quem pergunta, e o que pode fazer

| verificação | como você vê | aula |
|---|---|---|
| todo endpoint que não é público recusa uma requisição sem credenciais | 401 sem elas | 7 |
| tokens e sessões expiram, e sair da conta os encerra | use um depois de ele dever ter morrido | 7, 8 |
| senhas são guardadas só como hash lento e com sal | leia a tabela: nenhuma senha, só um hash com os parâmetros dele | 10 |
| todo objeto é conferido contra quem chama, não só o tipo de objeto | peça o objeto de outra pessoa com um token válido | 11 |
| toda função administrativa confere o papel ou o escopo | chame-a como conta comum | 11 |

## Volume

| verificação | como você vê | aula |
|---|---|---|
| cada cliente tem um limite, e passar dele responde 429 dizendo quando tentar de novo | um laço de requisições de um cliente só | 12 |
| listas são paginadas e têm um tamanho máximo de página | peça um milhão de linhas | 2 |

## Transporte e navegador

| verificação | como você vê | aula |
|---|---|---|
| só HTTPS, com um certificado de uma autoridade em que os clientes já confiam | `curl` sem opções funciona; `http://` simples não serve a API | 13 |
| `Strict-Transport-Security` em toda resposta HTTPS | o cabeçalho no `curl -si` de qualquer endereço | 13 |
| o CORS nomeia origens exatas, ou `*` só para dados públicos sem credenciais | uma origem desconhecida e `Origin: null` não recebem `Access-Control-Allow-Origin` | 13 |
| `Vary: Origin` em toda resposta que depende dele | procure-o na resposta a uma origem recusada | 13 |
| preflights respondem 2xx, com os métodos e cabeçalhos que as páginas usam de fato, `Authorization` incluído | `curl -X OPTIONS` com os três cabeçalhos de requisição | 13 |
| os cabeçalhos de segurança estão em toda resposta, erros incluídos | peça um endereço que não existe e um método desconhecido | 13 |
| nenhuma versão no `Server`, nenhum stack trace num erro | as mesmas duas requisições | 13 |

## Quando a API é o cliente

| verificação | como você vê | aula |
|---|---|---|
| todo endereço que a API busca está numa lista de permissões, e endereços privados são recusados | dê a ela `http://127.0.0.1/` e espere uma recusa | 13 |
| a resposta de todo parceiro é validada antes do uso, com a verificação de TLS ligada | o código que chama o parceiro, e os testes dele | 2, 13 |

Duas linhas que a tabela não comporta. **Cada uma destas é conferida de novo depois de toda mudança**,
não uma vez antes do lançamento. Um cabeçalho perdido numa refatoração não falha teste nenhum nem
quebra página nenhuma, e é por isso que as verificações acima estão escritas como requisições que dá
para automatizar. E nada disso substitui manter o software atualizado, que é a defesa contra toda
falha que ninguém achou no seu código ainda.
