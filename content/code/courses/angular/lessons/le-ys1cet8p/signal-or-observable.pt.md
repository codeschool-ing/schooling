---
title: Quando um signal basta
version: 1
---

**Use um signal para o que uma coisa é, e um Observable para o que acontece com ela ao longo do
tempo.** A maior parte de uma aplicação Angular é do primeiro tipo: os dados, o curso selecionado,
se um painel está aberto, os totais calculados a partir dos três. Para esses, um `signal`, um
`computed` e um resource dizem tudo o que precisa ser dito, sem assinatura para esquecer. O RxJS
vale a pena onde o tempo faz parte da pergunta.

| o código precisa de | use |
|---|---|
| um valor, e mudá-lo | `signal` |
| um valor calculado a partir de outros | `computed` |
| dados do servidor, para ler | `httpResource`, ou `resource` |
| mandar uma escrita, e saber como foi | `HttpClient`, assinado uma vez |
| esperar uma pausa, ou descartar repetições | `debounceTime`, `distinctUntilChanged` |
| só o mais novo de vários pedidos sobrepostos | `switchMap` |
| tentar de novo, ou cair num plano B | `retry`, `catchError` |
| combinar eventos de várias fontes ao longo do tempo | `combineLatest`, `merge` |

O planner cai exatamente aí. O estado dele são signals. A única escrita passa pelo `HttpClient` com
um `retry`, porque "tente de novo em dois segundos" é uma afirmação sobre o tempo. E a caixa de busca
dele, se tivesse uma, seria `toObservable`, `debounceTime` e `switchMap`, terminando em `toSignal`
para o template continuar lendo um signal.

**Código escrito antes dos signals usa RxJS para tudo**, e você vai ler muito dele: um
`BehaviorSubject` onde um signal bastaria, `combineLatest` onde um `computed` bastaria, e `| async`
em todo template. Funciona, e nada obriga ninguém a reescrevê-lo. Quando você muda um código assim,
o `toSignal` e o `toObservable` deixam os dois tipos se encontrarem na borda do que você mexeu.

## Devolvendo o planner

O bench sai, e o `App` volta ao que o git tem:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts
```

```
ana@dev:~/planner$ git status --short
 M src/app/planner-store.ts
```

Uma mudança fica, o retry no store:

```
ana@dev:~/planner$ git add -A && git commit -q -m "RxJS: retry a save that may work the second time"
```
