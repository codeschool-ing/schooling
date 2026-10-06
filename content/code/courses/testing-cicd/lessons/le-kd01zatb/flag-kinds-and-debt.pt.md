---
title: Tipos de flag, e a dívida que deixam
version: 1
---

Desligar a funcionalidade é a mesma edição que ligar:

```
ana@laptop:~/shipquote$ echo '{"delivery_estimate": 0}' > ~/envs/flags.json
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990&customer=c3"; echo
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8300/version; echo
{"version": "1.6.1", "env": "production-green", "carrier": "table"}
```

O `c3`, que tinha a estimativa há um instante, não tem mais. A produção continua no 1.6.1. Nada foi
implantado nem revertido: a funcionalidade saiu e o release ficou.

## Quatro tipos, com vidas diferentes

As flags não são todas iguais, e tratá-las do mesmo jeito é como uma base de código acaba com
centenas delas.

- **Flags de release** escondem uma funcionalidade até ela ficar pronta, como a `delivery_estimate`.
  Deveriam viver dias ou semanas, e sair quando a funcionalidade estiver ligada para todos.
- **Flags operacionais**, ou kill switches, desligam algo caro ou frágil sob pressão: a chamada à
  transportadora, um painel de recomendações. Podem ficar anos, e deveriam ser testadas, porque o
  dia em que são usadas é um dia ruim.
- **Flags de experimento** dividem os clientes para comparar duas versões de alguma coisa, a exibição
  de um preço ou um passo do checkout. Vivem enquanto dura o experimento, e a medição importa mais
  que a flag.
- **Flags de permissão** ligam uma funcionalidade para alguns clientes por direito: um plano pago, um
  programa beta. São uma regra do produto e talvez nem sejam flags.

## A dívida

Uma flag é duas versões do código num arquivo. Cada flag dobra o número de jeitos de o programa se
comportar; dez flags dão 1024 combinações, e nenhuma suíte de testes cobre todas. Então:

- **Cada flag de release ganha um dono e uma data de remoção** quando é criada. Uma flag ainda em 100%
  um mês depois é um ramo morto que alguém precisa ler toda vez.
- **Remover uma flag é uma mudança como outra qualquer**: apagar a verificação e o caminho perdedor,
  rodar os testes, liberar.
- **Os testes rodam com a flag no estado que a produção tem**, e com as flags que estão no meio da
  liberação nos dois estados. Uma suíte que só conhece "todas as flags desligadas" testa um programa
  que ninguém roda.

O repositório que publica este curso só deixa um comportamento virar configuração quando ele não tem
resposta certa, e escreve por quê: cada botão multiplica os estados que alguém precisa testar. É a
dívida acima, com o preço calculado antes de qualquer coisa entrar.
