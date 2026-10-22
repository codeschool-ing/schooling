---
title: Modelos de resposta: o formato que sai
version: 1
---

O `response_model` declara com o que uma rota responde, e o FastAPI faz três coisas com ele: **valida**
o valor de retorno da função contra ele, **filtra** todo campo que o modelo não cita, e descreve a
resposta na documentação da API, que é a aula 8.

## Inscrever-se, e o que volta

A rota de inscrição responde com `RegistrationOut` e um 201:

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Elisa\", \"email\": \"elisa@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/testing-dojo/registrations
{"name":"Elisa","email":"elisa@example.org","created_at":"2026-10-22T22:32:17.635456Z"}
201
```

Quem se inscreveu recebe o próprio endereço de volta, com a hora que o servidor definiu, em UTC.

## O que todo o resto vê

A lista de quem vem é pública, e os endereços nela não são. A função devolve as linhas cruas, com
endereço, e a rota declara `list[RegistrationPublic]`:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/testing-dojo/registrations | python3 -m json.tool
[
    {
        "name": "Elisa",
        "created_at": "2026-10-22T22:32:17.635456Z"
    }
]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 175\" role=\"img\" aria-label=\"A função do endpoint de inscrições devolve linhas com um slug, um nome, um endereço de e-mail e uma data. O modelo de resposta, uma lista de RegistrationPublic, cita só o nome e a data, então o cliente recebe esses dois campos e nunca o endereço de e-mail.\"> <defs><marker id=\"rf-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"40\" width=\"210\" height=\"90\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"125\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que a função devolveu</text> <text x=\"32\" y=\"62\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"slug\": \"testing-dojo\"</text> <text x=\"32\" y=\"81\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"name\": \"Elisa\"</text> <text x=\"32\" y=\"100\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"email\": \"elisa@…\"</text> <text x=\"32\" y=\"119\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"created_at\": \"2026-…\"</text> <rect x=\"280\" y=\"60\" width=\"170\" height=\"50\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"365\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">response_model=</text> <text x=\"365\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">list[RegistrationPublic]</text> <rect x=\"500\" y=\"40\" width=\"200\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"600\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que o cliente recebeu</text> <text x=\"512\" y=\"72\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"name\": \"Elisa\"</text> <text x=\"512\" y=\"91\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"created_at\": \"2026-…\"</text> <path d=\"M230 85 L274 85\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rf-a)\"></path> <path d=\"M450 85 L494 85\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rf-a)\"></path> <text x=\"360\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Campos que o modelo de resposta não cita nunca saem do servidor.</text> </svg>", "caption": "O modelo de resposta é um filtro na saída, então uma função que devolve demais não consegue vazar o excesso."}
```

**Os endereços não chegaram ao cliente**, e nada na função precisou lembrar de tirá-los. Essa é a
propriedade que vale ter: uma função que devolve demais, porque alguém acrescentou um campo ao store no
ano que vem, ainda assim não consegue vazá-lo, já que o modelo na saída diz o que pode sair. Devolver o
dicionário direto, sem `response_model`, teria mandado todas as chaves.

## As regras na entrada continuam valendo

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Elisa\", \"email\": \"elisa@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/testing-dojo/registrations
{"detail":"This address is already registered."}
409
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/testing-dojo | python3 -m json.tool | grep -E "capacity|taken"
    "capacity": 20,
    "taken": 1
```

O duplicado foi recusado com 409, e o `taken` do evento conta a inscrição que foi feita. **Essas regras
são o mesmo confere-depois-acrescenta da aula 3 do Django**, sobre uma lista Python, e têm o mesmo
defeito: o FastAPI roda uma rota `def` numa pool de threads, então duas requisições podem se
intercalar entre a contagem e o append. A aula 10 as leva para o PostgreSQL, com a mesma trava que a
aula 4 usou.
