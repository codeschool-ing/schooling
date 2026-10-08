---
title: Posicionamento
version: 2
---

Escolhidas as fontes, ainda é preciso escrevê-las em alguma ordem, e também as instruções e a pergunta
em volta. O prompt da aula 7 escrevia as fontes da melhor para a pior, a ordem em que a busca as
devolveu e a que ninguém precisa pensar. Se é a melhor ordem é uma propriedade do modelo, e não do
pipeline, e **este curso não a mede**: com três fontes, na maior parte das vezes, mal existe um meio
onde uma fonte se perca, e trinta perguntas não separariam um efeito pequeno do acaso.

A medição que existe é a citada duas seções atrás. O *Lost in the Middle* viu que os modelos testados
usavam um trecho relevante melhor quando ele estava no começo ou no fim da entrada, e pior quando
estava no meio, e o efeito crescia com o número de trechos em volta. A resposta de costume é uma ordem
que põe as fontes mais fortes nas duas pontas e deixa as mais fracas preencherem o meio:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Cinco caixas de fontes na ordem em que o ends() as escreve no prompt: posição 1, posição 3, posição 5, posição 4, posição 2. As duas mais fortes ficam no início do prompt e junto da pergunta; a mais fraca fica no meio.\"><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">cinco fontes, numeradas pela posição na busca</text><rect x=\"30\" y=\"60\" width=\"112\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"86.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">posição 1</text><text x=\"86.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lugar 1</text><rect x=\"160\" y=\"60\" width=\"112\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"216.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">posição 3</text><text x=\"216.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lugar 2</text><rect x=\"290\" y=\"60\" width=\"112\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"346.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">posição 5</text><text x=\"346.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lugar 3</text><rect x=\"420\" y=\"60\" width=\"112\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"476.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">posição 4</text><text x=\"476.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lugar 4</text><rect x=\"550\" y=\"60\" width=\"112\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"606.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">posição 2</text><text x=\"606.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lugar 5</text><path d=\"M30 134 L30 142 L662 142 L662 134\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"30\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">início do prompt</text><text x=\"662\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">junto da pergunta</text><text x=\"346.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o meio, para onde vão as mais fracas</text></svg>", "caption": "A ordem que o ends() escreve, e que o LostInTheMiddleRanker do Haystack também escreve. Ela segue uma medição de outros modelos; este curso não a mediu no llama3.2:3b."}
```

O `ends` do `context.py` escreve essa ordem, e o Haystack traz a mesma ideia como componente, o
`LostInTheMiddleRanker`, que leva o nome do artigo:

```schooling-example
{
  "language": "python",
  "file": "order.py",
  "parts": [
    {
      "code": "from context import ends\nfrom haystack import Document\nfrom haystack.components.rankers import LostInTheMiddleRanker\n\nranked = [\"first\", \"second\", \"third\", \"fourth\", \"fifth\"]\nprint(\"ends():              \", ends(ranked))\ndocs = [Document(content=name) for name in ranked]\nprint(\"LostInTheMiddleRanker:\", [d.content for d in LostInTheMiddleRanker().run(documents=docs)[\"documents\"]])",
      "note": "A ordem em que o `ends` põe cinco fontes classificadas, ao lado da ordem que o `LostInTheMiddleRanker` do Haystack usa para a mesma ideia."
    }
  ]
}
```
```
ana@vm:~/rag$ python order.py
ends():               ['first', 'third', 'fifth', 'fourth', 'second']
LostInTheMiddleRanker: ['first', 'third', 'fifth', 'fourth', 'second']
```

**Os dois concordam**: primeira, terceira, quinta, quarta, segunda. Com cinco fontes ordenadas pela
busca, a melhor vai primeiro, a segunda melhor vai por último, junto da pergunta, e a quinta, a mais
fraca, cai no meio.

## Instruções primeiro, pergunta por último

A mesma pesquisa é o argumento para o arranjo que a aula 7 já usava. As instruções vão primeiro, na
mensagem de sistema, onde a API do provedor as mantém separadas de tudo o que o usuário mandou. A
pergunta vai por último, logo antes de o modelo começar a escrever, de modo que a última coisa que ele
leu é o que lhe perguntaram. As fontes vão no meio, ordenadas como acima. Um prompt que põe a pergunta
primeiro e depois três mil tokens de fontes pede ao modelo que carregue a pergunta por todas elas.

## O que fazer sem uma medição

Nada aqui torna o `ends` certo para um modelo dado, e nada o torna errado; com três fontes, como este
pipeline costuma mandar, o meio é um lugar só. A ordem é, portanto, uma configuração a testar no modelo
real da implantação, com o teste da aula 8, antes de acreditar em qualquer lado. O que esta aula
pode mostrar é que mudá-la não custa nada: as mesmas fontes, os mesmos tokens, outra sequência.
