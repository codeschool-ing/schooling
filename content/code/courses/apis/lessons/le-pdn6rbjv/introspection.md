---
title: Introspection
version: 1
---

**A GraphQL server answers questions about its own schema, in GraphQL.** Two fields exist on every
query root without being declared: `__schema`, the whole schema, and `__type(name:)`, one type.
Their answers are ordinary data, selected field by field like anything else.

The whole schema's roots and type names:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ __schema { queryType { name } mutationType { name } types { name } } }"}' | jq -c '.data.__schema | {queryType, mutationType, types: [.types[].name]}'
{"queryType":{"name":"Query"},"mutationType":{"name":"Mutation"},"types":["Query","ID","Mutation","Int","Book","String","Author","Boolean","__Schema","__Type","__TypeKind","__Field","__InputValue","__EnumValue","__Directive","__DirectiveLocation"]}
```

`Query`, `Mutation`, `Book` and `Author` are `graph.py`'s, the scalars it uses come next, and every
name that starts with `__` belongs to introspection itself. One type in detail:

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

Every field of `Book` is `NON_NULL`, wrapping the scalar or the type underneath. That is the `!`
from the schema, as a client receives it: `kind` says what the wrapper is, and `ofType` what it
wraps.

## Why tools love it

Because the server can describe itself, a tool needs nothing but the address. An editor connected to
`/graphql` completes field names as you type a query and underlines one that does not exist. A code
generator reads the schema and writes typed client code, so a field removed from the server breaks
the client's build rather than its users' screens. A documentation page drawn from introspection
cannot fall behind the code, because it is the code answering. Lesson 6 meets the REST approach to
the same need, a description of the API written beside it.

## Turning it off in production

**The argument for turning it off** is that introspection hands the whole map to anybody who asks:
every type, every field, every mutation, including the ones that were only meant for an internal
screen. A public API with nothing to hide loses nothing by publishing its schema; one with an
internal admin mutation has just advertised it.

**The argument against** is that hiding a field does not protect it. A mutation anybody can call is
callable whether or not its name was published, so every field still needs the authorisation checks
of lessons 7 and 11. Hiding is also leaky. The refusal of `titel` in the section on queries answered
`Did you mean 'title'?`, with introspection or without it, and a patient stranger can rebuild much
of a schema from suggestions.

The usual compromise follows from both: introspection on wherever your own developers work, off on a
public server whose clients are all yours, and in neither case treated as security. graphql-core
ships a validation rule for exactly this, `NoSchemaIntrospectionCustomRule`, and most servers have a
setting with the same effect.
