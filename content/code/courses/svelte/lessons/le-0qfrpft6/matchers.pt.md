---
title: Matchers, para parâmetros com formato
version: 1
---

**Um parâmetro casa com qualquer texto entre duas barras, a menos que um matcher diga outra coisa.** O
`[id]` aceitou `piano` na seção anterior, o que estava certo, já que um curso chamado piano poderia
existir. Ele também aceita `Linear%20algebra`, `1`, `..` e qualquer coisa que uma pessoa ou um crawler
possa digitar. A página deu conta dizendo "No such course", mas alguns endereços não valem nem a
renderização de uma página: um id de curso no planner é feito de letras minúsculas e hífens, e qualquer
outra coisa não é um id.

Um matcher declara isso. No SvelteKit 3, os matchers de um projeto são declarados juntos em
`src/params.js`. Salve:

```schooling-example
{"language": "javascript", "file": "src/params.js", "parts": [
 {"code": "// params.js: the shapes a route parameter may take.\nimport { defineParams } from '@sveltejs/kit/params';\n\nexport const params = defineParams({", "note": "`defineParams` declara matchers com nome. Cada um é uma função do texto no endereço para o valor que a página recebe, ou `undefined` se não casar."},
 {"code": "\tslug: (param) => (/^[a-z][a-z-]*$/.test(param) ? param : undefined)\n});", "note": "Um slug: letras minúsculas, depois letras ou hífens. O valor repassado é o próprio texto."}
]}
```

e dê o nome do matcher na pasta, depois de um `=`:

```
ana@dev:~/planner$ mv 'src/routes/(planner)/courses/[id]' 'src/routes/(planner)/courses/[id=slug]'
```

O código da página não muda: o parâmetro continua se chamando `id`. O que muda é quais endereços chegam
até ela:

```
ana@dev:~/planner$ look http://localhost:5173/courses/Algebra
at /courses/Algebra
- main:
  - heading "404" [level=1]
  - paragraph: Not Found
```

**Um 404, antes de a página rodar.** `Algebra` não é um slug, então a rota não casa, o SvelteKit tenta
as outras rotas, não acha nenhuma e responde que não há nada naquele endereço. `piano` ainda chega à
página, porque tem o formato de um id de curso; se o curso existe é uma pergunta sobre os dados, que um
matcher não consegue responder e não deveria tentar.

## O que mudou no SvelteKit 3

Antes da versão 3, cada matcher era um arquivo próprio numa pasta `src/params/`, exportando uma função
`match` que devolvia `true` ou `false`. Você vai ver isso em projetos mais antigos. O arquivo único com
`defineParams` é o substituto, e as funções dele devolvem um valor em vez de um sim ou não, então um
matcher também pode converter: um matcher para números pode entregar à página um número em vez da string
que estava no endereço.
