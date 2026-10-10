---
title: Introspecção
version: 1
---

**Um servidor GraphQL responde perguntas sobre o próprio esquema, em GraphQL.** Dois campos existem
em toda raiz de consulta sem terem sido declarados: `__schema`, o esquema inteiro, e
`__type(name:)`, um tipo. As respostas são dados comuns, selecionados campo a campo como qualquer
outra coisa.

As raízes e os nomes de tipo do esquema inteiro:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ __schema { queryType { name } mutationType { name } types { name } } }"}' | jq -c '.data.__schema | {queryType, mutationType, types: [.types[].name]}'
{"queryType":{"name":"Query"},"mutationType":{"name":"Mutation"},"types":["Query","ID","Mutation","Int","Book","String","Author","Boolean","__Schema","__Type","__TypeKind","__Field","__InputValue","__EnumValue","__Directive","__DirectiveLocation"]}
```

`Query`, `Mutation`, `Book` e `Author` são do `graph.py`, os escalares que ele usa vêm em seguida, e
todo nome que começa com `__` pertence à própria introspecção. Um tipo em detalhe:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ __type(name: \"Book\") { fields { name type { kind ofType { name } } } } }"}' | jq -c '.data.__type.fields[]'
{"name":"id","type":{"kind":"NON_NULL","ofType":{"name":"ID"}}}
{"name":"isbn","type":{"kind":"NON_NULL","ofType":{"name":"String"}}}
{"name":"title","type":{"kind":"NON_NULL","ofType":{"name":"String"}}}
{"name":"year","type":{"kind":"NON_NULL","ofType":{"name":"Int"}}}
{"name":"priceCents","type":{"kind":"NON_NULL","ofType":{"name":"Int"}}}
{"name":"stock","type":{"kind":"NON_NULL","ofType":{"name":"Int"}}}
{"name":"author","type":{"kind":"NON_NULL","ofType":{"name":"Author"}}}
```

Todo campo de `Book` é `NON_NULL`, embrulhando o escalar ou o tipo de baixo. É o `!` do esquema, do
jeito que o cliente o recebe: `kind` diz o que é o embrulho, e `ofType`, o que ele embrulha.

## Por que as ferramentas adoram isso

Como o servidor sabe se descrever, uma ferramenta não precisa de nada além do endereço. Um editor
ligado a `/graphql` completa nomes de campo enquanto você digita a consulta e sublinha um que não
existe. Um gerador de código lê o esquema e escreve código de cliente tipado, então um campo removido
do servidor quebra o build do cliente em vez das telas dos usuários. Uma página de documentação tirada
da introspecção não tem como ficar para trás do código, porque é o código respondendo. A aula 6
apresenta a resposta do REST para a mesma necessidade, uma descrição da API escrita ao lado dela.

## Desligar em produção

**O argumento para desligar** é que a introspecção entrega o mapa inteiro a quem pedir: cada tipo,
cada campo, cada mutation, inclusive as que eram só para uma tela interna. Uma API pública sem nada a
esconder não perde nada publicando o esquema; uma com uma mutation interna de administração acabou de
anunciá-la.

**O argumento contra** é que esconder um campo não o protege. Uma mutation que qualquer um pode
chamar continua chamável, publicado o nome ou não, então todo campo ainda precisa das verificações de
autorização das aulas 7 e 11. Esconder também vaza. A recusa de `titel` na seção sobre consultas
respondeu `Did you mean 'title'?`, com introspecção ou sem ela, e um estranho paciente consegue
reconstruir boa parte de um esquema a partir das sugestões.

O meio-termo usual sai dos dois: introspecção ligada onde os seus desenvolvedores trabalham,
desligada num servidor público cujos clientes são todos seus, e em nenhum dos casos tratada como
segurança. O graphql-core traz uma regra de validação exatamente para isso,
`NoSchemaIntrospectionCustomRule`, e a maioria dos servidores tem uma configuração com o mesmo
efeito.
