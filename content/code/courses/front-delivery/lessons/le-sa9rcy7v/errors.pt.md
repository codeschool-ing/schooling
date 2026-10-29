---
title: Erros, com um 200
version: 1
---

**Uma resposta GraphQL pode conter dados e erros ao mesmo tempo, e o status HTTP dela é 200 de qualquer
jeito.** O status diz que a requisição chegou ao servidor e foi entendida como GraphQL. Se a consulta
funcionou está no corpo: uma lista `errors` no nível de cima, presente só quando algo deu errado, ao lado
de `data`. Um cliente que só confere `response.ok` trata toda consulta que falhou como sucesso.

## Dois tipos de falha

**Uma consulta que o schema não permite** é recusada antes de qualquer coisa rodar. Um erro de digitação
no nome de um campo é o caso comum:

```
ana@dev:~/planner$ node api/ask.mjs '{ course(id: "git") { titel } }'
{
  "errors": [
    {
      "message": "Cannot query field \"titel\" on type \"Course\". Did you mean \"title\"?",
      "locations": [
        {
          "line": 1,
          "column": 23
        }
      ]
    }
  ]
}
```

Nenhum `data`, porque nada rodou, e um erro que diz onde na consulta está o problema e sugere o campo que
existe. Esse é o tipo que o teste do fim da aula pega antes de a consulta sair do computador.

**Um campo que falha durante a execução** produz um erro com um `path`, o campo onde aconteceu, e o resto
que a consulta pediu continua voltando. Pedir uma sessão num curso que não existe faz o `addSession` do
servidor lançar um erro:

```
ana@dev:~/planner$ node api/ask.mjs 'mutation { addSession(input: { course: "rust", date: "2026-10-20", minutes: 30 }) { id } }'
{
  "errors": [
    {
      "message": "No course \"rust\"",
      "locations": [
        {
          "line": 1,
          "column": 12
        }
      ],
      "path": [
        "addSession"
      ]
    }
  ],
  "data": null
}
```

## Por que `data` é `null`

O erro foi em `addSession`, e mesmo assim `data` inteiro é `null`. É o `!` do schema em ação: `addSession`
devolve `Session!`, que nunca pode ser nulo, então quando falha o null sobe até o campo mais próximo que
pode ser nulo. Não há nenhum acima dele, então o próprio `data` vira `null`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Para onde vai o null de uma falha. À esquerda, addSession devolve Session com ponto de exclamação, então, quando ela lança um erro, o null não pode parar ali e sobe até data, que vira null. À direita, markDone devolve Session sem ele, então um id desconhecido deixa markDone null e data fica com todo o resto.\"><rect x=\"20\" y=\"40\" width=\"280\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nunca pode ser null</text><rect x=\"110\" y=\"56\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">data: null</text><rect x=\"70\" y=\"126\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">addSession: Session!</text><line x1=\"160\" y1=\"124\" x2=\"160\" y2=\"90\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"160.0,90.0 163.1,97.4 156.9,97.4\" fill=\"var(--amber)\"></polygon><text x=\"160\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lança um erro, ou não acha nada</text><rect x=\"420\" y=\"40\" width=\"280\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pode ser null</text><rect x=\"510\" y=\"56\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">data</text><rect x=\"470\" y=\"126\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">markDone: Session</text><line x1=\"560\" y1=\"124\" x2=\"560\" y2=\"90\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"560\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lança um erro, ou não acha nada</text><text x=\"168\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o null sobe</text><text x=\"568\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o null para aqui</text></svg>", "caption": "Um campo que falha vira null no lugar mais próximo em que o schema aceita null; com ! em tudo acima dele, a resposta inteira vai embora."}
```

A mesma regra funciona ao contrário quando um campo aceita nulo. `markDone` devolve `Session` sem `!`,
então um id desconhecido dá `{"markDone": null}` e mantém o resto da resposta. **Onde um schema põe os
seus `!` decide quanto de uma resposta uma falha leva junto.**

## O que o cliente faz

O cliente do planner, numa seção mais adiante, lê o corpo e, se houver `errors`, lança um erro com as
mensagens juntas. Ele não tenta usar meia resposta: o planner não tem o que mostrar com metade das
sessões. Um app com painéis independentes numa página pode ficar com as partes que funcionaram; as duas
são escolhas, e a errada é nem olhar para `errors`.
