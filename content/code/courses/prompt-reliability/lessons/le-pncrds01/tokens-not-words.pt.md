---
title: Tokens, não palavras
version: 1
---

Toda configuração de tamanho que um modelo oferece conta tokens, e **um token não é uma palavra**. O
`prompt-engineering` apresentou os tokens na aula 3 e o limite de saída na aula 15. Esta aula retoma
o limite de propósito, com uma pergunta mais estreita: o que um corte faz com uma resposta que um
programa precisa ler.

A bancada conta com `pl tokens`, que recebe um arquivo, ou `-` para o que chegar por um pipe:

```
ana@lab:~/triage$ pl tokens prompts/v4-only-json.txt
84 tokens, 59 words, 362 characters
ana@lab:~/triage$ echo 'They were charged twice for order 4471.' | pl tokens -
8 tokens, 7 words, 40 characters
ana@lab:~/triage$ echo '{"summary": "They were charged twice for order 4471."}' | pl tokens -
16 tokens, 8 words, 55 characters
```

No laboratório, uma sequência de letras ou dígitos é um token, e cada sinal de pontuação é outro. A
frase tem sete palavras e oito tokens, porque o ponto final conta. Coloque-a dentro de um campo JSON
e ela dobra para dezesseis: as duas chaves, os dois-pontos e as quatro aspas são um token cada, e o
nome do campo também.

**Um tokenizador real divide de outro jeito, e o provedor cobra pela contagem dele.** Palavras comuns
tendem a ser um token, palavras raras ou longas são quebradas em pedaços, e a pontuação muitas vezes
se junta ao que está ao lado. Então as contagens do laboratório não são a conta de ninguém. O que se
mantém é a proporção de que esta aula trata: numa resposta em JSON, boa parte do que o modelo escreve
é estrutura.

## Para onde vão os tokens de uma resposta

Esta é uma resposta do prompt que pede o objeto JSON e mais nada:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, written to runs/v4.jsonl
ana@lab:~/triage$ pl show runs/v4.jsonl t01
│ {
│   "category": "billing",
│   "urgency": "high",
│   "summary": "They were charged twice for order 4471."
│ }
stop: end, tokens in 93, out 32
```

`out 32` é o tamanho dessa resposta em tokens do laboratório. O resumo, a parte que uma pessoa lê, é
oito deles. Todo o resto é a moldura: nomes de campo, rótulos e pontuação.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Os 32 tokens de uma resposta, em ordem. 19 são pontuação de JSON, 5 são nomes de campo e rótulos, 8 são o resumo. Um limite de 30 cai depois do ponto final do resumo, e as aspas e a chave de fechamento nunca são escritas.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Uma resposta, 32 tokens, na ordem em que são escritos</text><rect x=\"24\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"44\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"64\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"84\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"104\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"124\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"144\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"164\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"184\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"204\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"224\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"244\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"264\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"284\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"304\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"324\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"344\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"364\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"384\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"404\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"424\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"444\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"464\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"484\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"504\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"524\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"544\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"564\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"584\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"604\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"624\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"644\" y=\"60\" width=\"17\" height=\"30\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"32.5\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"212.5\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10</text><text x=\"412.5\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">20</text><text x=\"612.5\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M622.5 46 L622.5 114\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"616.5\" y=\"42\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">max_tokens=30</text><text x=\"628.5\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nunca escritos</text><rect x=\"24\" y=\"154\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"42\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pontuação de JSON: 19</text><rect x=\"254\" y=\"154\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"272\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nomes de campo e rótulos: 5</text><rect x=\"484\" y=\"154\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"502\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o resumo: 8</text></svg>", "caption": "A resposta para t01, token a token, como o laboratório conta. Mais da metade é pontuação, e um limite de 30 tira os dois tokens que a fecham."}
```

Essa proporção decide duas coisas no resto da aula. **Um limite escolhido pensando em quanto um
resumo deve ter vai sair pequeno demais**, porque o resumo é um quarto da resposta. E pedir um resumo
mais curto mexe no total menos do que você esperaria, porque a moldura não encolhe quando a frase
encolhe.
