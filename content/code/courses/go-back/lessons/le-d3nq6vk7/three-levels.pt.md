---
title: Três distâncias do código
version: 1
---

O `go-concurrency` ensinou as ferramentas: `go test` e subtestes na aula 25, tabelas na 26, `httptest` na
28, cobertura na 30 e o detector de corrida lá na 16. Esta aula aponta essas ferramentas para um serviço, e
a pergunta que ela repete é **a que distância do código um teste deve ficar.** O boxoffice pode ser testado
a três distâncias, e cada uma pega algo que as outras não pegam:

| distância | o que roda | o que pega | quanto custa |
|---|---|---|---|
| **um handler** | a função do handler, uma requisição montada em memória e um `httptest.ResponseRecorder` | status errados, corpos errados, validação que deixa passar um valor ruim | microssegundos; nada a preparar |
| **o roteador inteiro** | `routes(…)` com seus middlewares, servido por um `httptest.Server` numa porta real | uma rota não registrada, middleware na ordem errada, um cabeçalho faltando, um token no log | milissegundos; ainda nada fora do processo |
| **um banco de verdade** | `pgStore` contra o PostgreSQL | SQL que não faz o que diz, uma transação que não é uma, um gatilho que nunca dispara | um servidor de banco, e algumas centenas de milissegundos |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Três caixas aninhadas e uma fora delas. No centro, um handler como o getEvent, com o memStore, testado pelo events_test.go por meio de um ResponseRecorder. Em volta, o roteador: requestID, logRequests, recoverPanics, cors e o mux, testado pelo routes_test.go. Em volta disso, um httptest.Server em 127.0.0.1. À parte, o pgStore com um PostgreSQL de verdade, testado pelo pgstore_test.go.\"><defs><marker id=\"gb-l15-distances-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"15\" width=\"430\" height=\"220\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">httptest.Server · 127.0.0.1</text><rect x=\"35\" y=\"48\" width=\"390\" height=\"172\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"50\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">routes(…)</text><text x=\"50\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">requestID · logRequests · recoverPanics · cors · mux</text><rect x=\"60\" y=\"100\" width=\"340\" height=\"100\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">getEvent(store)</text><rect x=\"75\" y=\"138\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ResponseRecorder</text><rect x=\"245\" y=\"138\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">memStore</text><rect x=\"515\" y=\"95\" width=\"170\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pgStore</text><text x=\"600\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"600\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pgstore_test.go</text><text x=\"410\" y=\"66\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">routes_test.go</text><text x=\"385\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">events_test.go</text></svg>", "caption": "Cada distância acrescenta o que a de dentro não enxerga, e custa um pouco mais para rodar.", "same": ["PostgreSQL"]}
```

As duas primeiras usam o `memStore`, o store em memória que o boxoffice tem desde a aula 1, por trás da
interface `Store` da aula 6. Essa interface foi escrita para o PostgreSQL poder substituir a memória, e ela
se paga uma segunda vez aqui: todo teste de handler roda contra a memória, sem banco e sem limpeza, em
poucos milissegundos.

**A maioria dos testes pertence às duas primeiras distâncias**, porque elas são rápidas o bastante para
rodar a cada salvamento. A terceira é para o que só um banco consegue mostrar. O teste da seção 07 vende
lugares a partir de trinta goroutines e verifica que exatamente dez dão certo; nenhuma imitação em memória
diz se o `UPDATE` da aula 8 é seguro sob concorrência, porque a imitação não é a coisa em que se está
confiando.

## Onde os testes moram

Um arquivo de teste fica ao lado do código que testa, no mesmo pacote. O boxoffice é `package main`, e os
testes dele também são `package main`, então eles podem chamar `getEvent`, `load` e `newMemStore`
diretamente, nomes não exportados inclusive. Cinco arquivos chegam nesta aula:

| arquivo | seção | distância |
|---|---|---|
| `events_test.go` | 03 | um handler |
| `routes_test.go` | 04 | o roteador inteiro |
| `config_test.go` | 05 | uma função |
| `concurrency_test.go` | 06 | o roteador inteiro, cinquenta requisições de uma vez |
| `pgstore_test.go` | 07 | um banco de verdade |

**Um teste que só repete o código não prova nada.** Cada teste aqui afirma algo que o boxoffice promete, um
404 para um evento que não existe, um 401 sem token, dez lugares vendidos de dez, em termos que uma pessoa
lendo poderia conferir contra as aulas que fizeram a promessa. Um deles encontra um defeito que todas as
aulas anteriores deixaram passar, e outro encontra um num teste.
