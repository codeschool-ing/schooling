---
title: O que a 1.22 fechou, e o que deixou aberto
version: 1
---

Esta aula toma partido, e deve dizer qual antes de argumentar. **Para uma API HTTP nova em Go,
comece pela biblioteca padrão, acrescente bibliotecas pequenas para necessidades específicas e
adote um framework quando souber dizer o que ele faz que você teria de construir de outro jeito.**
O resto desta aula é a evidência disso, tirada do que as aulas 1 a 4 mediram. É um julgamento, não
uma lei, e a seção 06 trata de onde ele erra.

## A lacuna que criou os frameworks

A seção 02 da aula 4 disse por que o Go criou roteadores: até a 1.22 o mux padrão não sabia rotear
por método nem capturar parte de um caminho. Eis o que faltava então, e onde cada necessidade está
hoje:

| necessidade | antes do Go 1.22 | agora, na biblioteca padrão |
|---|---|---|
| rotear por método | um `if` em cada handler | `GET /events`, com um 405 e um cabeçalho `Allow` escritos para você |
| um valor do caminho | cortar o caminho à mão | `{id}` e `r.PathValue("id")` |
| o resto de um caminho | o padrão de subárvore e `TrimPrefix` | `{path...}` |
| um caminho exato, não a subárvore dele | impossível para `/` | `{$}` |
| qual rota vence | o padrão mais longo | o mais específico, e um pânico quando dois não podem ser ordenados |
| middleware | o formato `func(http.Handler) http.Handler` | o mesmo formato; ele nunca precisou de framework |
| grupos de rotas | um mux dentro de um mux | o mesmo, como o boxoffice faz para `/admin/` |

**As cinco primeiras linhas são o motivo de a maioria dos projetos ter buscado um roteador, e as
cinco estão fechadas.** As duas últimas nunca precisaram de um: uma cadeia de middlewares e um
sub-mux montado sempre foram Go puro.

## O que ainda não está lá

Algumas coisas que um framework dá ainda faltam no `net/http`, e são reais:

- **Decodificar e validar um corpo numa chamada só.** A aula 3 escreveu o `decodeJSON` e um método
  `validate` por tipo de requisição; o `ShouldBindJSON` do Gin e as tags dele fazem as duas coisas.
- **Um lugar central onde erros viram respostas.** Os erros devolvidos do Echo fazem isso; o
  boxoffice tem `fail` e `writeProblem`, chamados à mão em cada handler.
- **O 404 e o 405 do próprio mux no seu formato.** A seção 05 da aula 3 mostrou que um pega-tudo
  custa o 405, e que o `ServeMux` não tem configuração para isso.
- **Um catálogo de middlewares prontos**: limite de taxa, compressão, ids de requisição, timeouts,
  todos instalados com uma linha.
- **Gerar uma descrição da API** (OpenAPI) a partir das rotas e dos tipos.

Cada um desses é algumas dezenas de linhas, uma biblioteca pequena ou um motivo real para usar um
framework. **A pergunta desta aula não é "o framework tem mais?" — ele sempre tem — mas se o que
ele tem vale o que custa.** As duas próximas seções põem um número em cada lado.
