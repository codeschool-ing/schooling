---
title: A mesma chamada, no Node
version: 1
---

Com os arquivos no lugar, classificar e-mail é a chamada de pipeline da aula 12, escrita em
JavaScript. O `sort.mjs` roda o modelo da ana nos dez casos que ele nunca viu:

```schooling-example
{
  "language": "javascript",
  "file": "sort.mjs",
  "parts": [
    {
      "code": "import { pipeline, env } from \"@huggingface/transformers\";\nimport { readFileSync } from \"node:fs\";\n\n",
      "note": "A biblioteca, importada do `node_modules` do próprio projeto, como qualquer pacote."
    },
    {
      "code": "env.allowRemoteModels = false;              // nothing is fetched from the Hub\nenv.localModelPath = process.cwd() + \"/models/\";\n\n",
      "note": "Dois ajustes decidem de onde vem o modelo. Com modelos remotos desligados, um arquivo ausente é um erro, não um download do huggingface.co."
    },
    {
      "code": "const classify = await pipeline(\"text-classification\", \"lantern-sorter\", { dtype: \"fp32\" });\n",
      "note": "A tarefa da seção 02 da aula 12, e o modelo pelo nome: `lantern-sorter` é uma pasta sob `models/`. O `dtype` escolhe o arquivo, como a seção 02 mostrou; no Node já seria `fp32`, e dizer isso deixa o programa igual onde quer que rode."
    },
    {
      "code": "const cases = JSON.parse(readFileSync(\"cases/held-out.json\", \"utf8\"));\nlet right = 0;\nfor (const c of cases) {\n  const [top] = await classify(c.text);\n  if (top.label === c.label) right++;\n  console.log(`${c.id} ${top.label.padEnd(16)} ${top.score.toFixed(3)}  (${c.label})`);\n}\nconsole.log(`${right} of ${cases.length} held-out cases right`);\n",
      "note": "Os dez casos que o `train_sorter.py` deixou de fora. Cada resposta é uma lista de rótulos com notas, a melhor primeiro; o programa fica com a primeira e imprime ao lado, entre parênteses, o rótulo dado pela pessoa."
    }
  ]
}
```

```
ana@desk:~/desk$ time node sort.mjs
c31 refund           0.910  (refund)
c32 address-change   0.449  (address-change)
c33 product-question 0.840  (product-question)
c34 refund           0.441  (other)
c35 order-status     0.366  (order-status)
c36 address-change   0.502  (refund)
c37 address-change   0.803  (address-change)
c38 other            0.488  (product-question)
c39 other            0.483  (other)
c40 order-status     0.690  (order-status)
7 of 10 held-out cases right

real	0m0.259s
user	0m0.413s
sys	0m0.028s
```

**Sete de dez**, e a execução inteira levou 0,259 segundo, carga incluída. Sem chave, sem
requisição, sem conta: o programa leu quatro arquivos e fez a conta na CPU.

Leia os erros do jeito que a seção 07 da aula 5 leu erros, pelo que foi confundido com o quê. O
`c34`, que uma pessoa rotulou `other`, virou `refund`; o `c36`, um reembolso, virou
`address-change`; o `c38`, uma pergunta sobre produto, virou `other`. As notas dizem quão seguro ele
estava, e são baixas justamente nesses: 0,441, 0,502, 0,488, contra 0,910 no reembolso que acertou.
**Uma nota é a confiança do modelo, não a precisão dele**, e um limite abaixo do qual o e-mail vai
para uma pessoa é o uso óbvio para ela.

E leia os sete com a seção 06 da aula 5 em mente. Sete de dez tem intervalo de Wilson de **40% a
89%**: dez casos não distinguem um modelo que acerta metade das vezes de um que acerta nove em dez.
O ponto desta execução é que o modelo funciona no Node a partir dos arquivos. Se ele é bom o
bastante para classificar o correio da Lantern Books é uma pergunta para o conjunto completo e um
modelo melhor, e a aula 5 já diz como fazê-la.
