---
title: Repetições e ritmo, em segundos
version: 1
---

`min_backoff = "10s"`, `max_backoff = "300s"` e `max_doublings = 3` parecem três configurações
independentes. **São uma regra só, e o único jeito de saber o que fazem com uma tarefa é calcular a
regra.** O Google a documenta: a primeira repetição espera `min_backoff`, a espera dobra
`max_doublings` vezes, depois cresce num passo fixo, e nunca passa de `max_backoff`.

## Calculando

Uma dúzia de linhas de Python segue a regra. **Salve isto como `~/gcp/backoff.py`:**

```schooling-example
{"language": "python", "file": "backoff.py", "parts": [{"code": "import sys\n\n\n", "note": "Um módulo, para ler a linha de comando."}, {"code": "def waits(min_backoff, max_backoff, max_doublings, max_attempts):\n    \"\"\"The wait before each retry, by the rule Cloud Tasks documents.\"\"\"\n    wait, step = min_backoff, min_backoff * 2 ** max_doublings\n    for retry in range(1, max_attempts):\n        yield retry, min(wait, max_backoff)\n        wait = wait * 2 if retry <= max_doublings else wait + step\n\n\n", "note": "A regra como o Google a documenta para o Cloud Tasks: a primeira espera é `min_backoff`, ela dobra `max_doublings` vezes, depois cresce num passo fixo de `min_backoff` vezes dois elevado a `max_doublings`, e nunca passa de `max_backoff`."}, {"code": "def main():\n    args = [int(a) for a in sys.argv[1:]] or [10, 300, 3, 9]\n    total = 0\n    for retry, wait in waits(*args):\n        total += wait\n        print(f'retry {retry}: wait {wait:>3} s, {total:>4} s after the first attempt')\n\n\nif __name__ == '__main__':\n    main()\n", "note": "Sem argumentos ele usa os números do próprio exemplo do Google, 10 e 300 segundos, três dobras e nove tentativas, então a saída pode ser conferida com a documentação."}]}
```

Sem argumentos ele usa os números do próprio exemplo do Google, nove tentativas:

```
ana@laptop:~/gcp$ python3 backoff.py
retry 1: wait  10 s,   10 s after the first attempt
retry 2: wait  20 s,   30 s after the first attempt
retry 3: wait  40 s,   70 s after the first attempt
retry 4: wait  80 s,  150 s after the first attempt
retry 5: wait 160 s,  310 s after the first attempt
retry 6: wait 240 s,  550 s after the first attempt
retry 7: wait 300 s,  850 s after the first attempt
retry 8: wait 300 s, 1150 s after the first attempt
```

**10, 20, 40 e 80 são as três dobras; 160 e 240 são o passo linear de 80; e 300 é o teto**, que é a
sequência que a documentação do Google dá para as mesmas configurações. Agora a fila da seção 02,
que permite cinco tentativas e portanto quatro repetições:

```
ana@laptop:~/gcp$ python3 backoff.py 10 300 3 5
retry 1: wait  10 s,   10 s after the first attempt
retry 2: wait  20 s,   30 s after the first attempt
retry 3: wait  40 s,   70 s after the first attempt
retry 4: wait  80 s,  150 s after the first attempt
```

Uma tarefa que falha toda vez é abandonada dois minutos e meio depois da primeira tentativa. É esse
o número a comparar com quanto tempo a coisa de que ela depende costuma ficar fora do ar. Se as
quedas do provedor de e-mail duram dez minutos, esta fila desiste de todo e-mail mandado durante
uma delas, e as correções honestas são mais tentativas ou um `max_backoff` maior, não esperança.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Um gráfico de barras com a espera antes de cada repetição, com min_backoff de 10 segundos, max_backoff de 300 e três dobras. As repetições 1 a 4 esperam 10, 20, 40 e 80 segundos, as dobras. As repetições 5 e 6 esperam 160 e 240, crescendo 80 fixos. As repetições 7 e 8 esperam 300, o teto. Uma linha tracejada marca o fim da fila desta lição, que permite cinco tentativas e por isso para depois da repetição 4.\"><defs><marker id=\"f20back-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">espera (s)</text><rect x=\"70\" y=\"224.0\" width=\"56\" height=\"6.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"98.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10</text><text x=\"98.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rep. 1</text><rect x=\"144\" y=\"218.0\" width=\"56\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"172.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20</text><text x=\"172.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rep. 2</text><rect x=\"218\" y=\"206.0\" width=\"56\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"246.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">40</text><text x=\"246.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rep. 3</text><rect x=\"292\" y=\"182.0\" width=\"56\" height=\"48.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">80</text><text x=\"320.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rep. 4</text><rect x=\"366\" y=\"134.0\" width=\"56\" height=\"96.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"394.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">160</text><text x=\"394.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rep. 5</text><rect x=\"440\" y=\"86.0\" width=\"56\" height=\"144.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"468.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">240</text><text x=\"468.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rep. 6</text><rect x=\"514\" y=\"50.0\" width=\"56\" height=\"180.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"542.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">300</text><text x=\"542.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rep. 7</text><rect x=\"588\" y=\"50.0\" width=\"56\" height=\"180.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"616.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">300</text><text x=\"616.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rep. 8</text><rect x=\"60\" y=\"230\" width=\"600\" height=\"1\" rx=\"0\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M357.0 52 L357.0 228\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#f20back-amber)\"></path><text x=\"349.0\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cinco tentativas acabam aqui</text><text x=\"209.0\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">dobrando</text><text x=\"431.0\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">passo fixo</text><text x=\"579.0\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">teto</text></svg>", "caption": "A espera antes de cada repetição. Três dobras, depois um passo fixo, depois o teto; a fila desta lição para na linha tracejada."}
```
## Ritmo: a fila como freio

As repetições decidem por quanto tempo uma tarefa insiste. Os limites de ritmo decidem com que
velocidade a fila esvazia, e a conta é mais simples: uma fila com 1.000 confirmações, despachando no
máximo 5 por segundo, precisa de 1.000 ÷ 5 = 200 segundos para esvaziar, uns três minutos e meio,
por mais rápido que o mailer pudesse ir. **Esse é o ponto.** A fila absorve o pico para que o
provedor de e-mail, ou o banco atrás de um handler, veja cinco por segundo constantes e nunca mil de
uma vez.

`max_concurrent_dispatches` é o outro freio: no máximo dez requisições em andamento. Com um handler
que leva dois segundos por e-mail, dez em andamento também dão cinco por segundo, e os dois limites
concordam; com um handler mais lento, o limite de concorrência pega primeiro. Saber qual dos dois
manda vale antes de uma promoção, e os dois são uma linha de Terraform para mudar.

## Quando uma tarefa nem deveria ser repetida

Uma tarefa cujo pedido não existe mais vai falhar em toda tentativa, e todas serão desperdício. O
handler é o único lugar que sabe a diferença, então ele decide: **responda 2xx para uma tarefa que
nunca vai dar certo**, depois de registrar o motivo, e guarde as respostas não 2xx para falhas que o
tempo resolve. É a mesma regra que a lição 18 deu para eventos, pelo mesmo motivo.
