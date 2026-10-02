---
title: Uma janela para a pergunta e a resposta
version: 1
---

Todo modelo tem uma **janela de contexto**: o máximo de tokens que ele consegue tratar numa
requisição. O erro comum é lê-la como o tamanho da pergunta que se pode fazer. **Ela é o tamanho da
pergunta e da resposta juntas.** O modelo escreve a resposta na mesma janela de onde leu o prompt,
um token por vez, então cada token de saída que você permite é um token que a entrada não pode
usar.

A requisição leva o segundo número. O `max_tokens` é o máximo que o modelo pode escrever, e a API
o exige, porque sem ele o provedor não saberia quanto espaço reservar. Um provedor publica dois
limites por modelo, a janela e o máximo de saída de uma única resposta, e uma requisição precisa
caber nos dois.

## Batendo nos limites de propósito

O `tiny-1` do labllm tem uma janela de 2.048 tokens e deixa uma resposta ter no máximo 512,
pequenos de propósito, para os limites ficarem a poucas linhas de texto. O `lab/window.py` manda
as primeiras *n* palavras do corpus do laboratório com um certo `max_tokens`:

```
ana@dev:~/shop$ python lab/window.py 900 200
max_tokens: 1717 in, 200 out
ana@dev:~/shop$ python lab/window.py 900 400
400 prompt is too long: 1717 tokens + 400 max_tokens > 2048 maximum
ana@dev:~/shop$ python lab/window.py 1300 200
400 prompt is too long: 2292 tokens + 200 max_tokens > 2048 maximum
ana@dev:~/shop$ python lab/window.py 900 600
400 max_tokens: 600 > 512, which is the maximum allowed number of output tokens for tiny-1
```

Leia as quatro linhas como quatro situações diferentes:

- **1.717 de entrada e 200 de saída cabe**, com 131 tokens sobrando. A resposta parou em 200 tokens
  com `stop_reason` igual a `max_tokens`, assunto da aula 2 seção 08.
- **O mesmo prompt com 400 de saída é recusado**, embora o prompt não tenha mudado. 1.717 mais 400
  passa de 2.048. O prompt estava bom e o espaço pedido para a resposta não.
- **2.292 de entrada não cabe de jeito nenhum**, diga o `max_tokens` o que disser.
- **600 de saída é recusado antes de qualquer contagem**: passa do limite por resposta de 512, e um
  prompt menor não mudaria isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três requisições contra a janela de 2.048 tokens do tiny-1. 1.717 de entrada e 200 de saída cabe. 1.717 de entrada e 400 de saída dá 2.117 e é recusado. 2.292 de entrada com 200 de saída é recusado antes mesmo de a saída contar.\"><defs><marker id=\"wn-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">janela do tiny-1: 2.048 tokens</text><text x=\"140\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1.717 + 200</text><rect x=\"150\" y=\"50\" width=\"343.40000000000003\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"493.40000000000003\" y=\"50\" width=\"40.0\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"541.4000000000001\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">cabe</text><text x=\"140\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1.717 + 400</text><rect x=\"150\" y=\"102\" width=\"343.40000000000003\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"493.40000000000003\" y=\"102\" width=\"80.0\" height=\"24\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"581.4000000000001\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">recusado</text><text x=\"140\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2.292 + 200</text><rect x=\"150\" y=\"154\" width=\"458.40000000000003\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"608.4000000000001\" y=\"154\" width=\"40.0\" height=\"24\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"656.4000000000001\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">recusado</text><path d=\"M559.6 36 L559.6 47\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M559.6 77 L559.6 99\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M559.6 129 L559.6 151\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M559.6 181 L559.6 206\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"559.6\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2048</text><rect x=\"560\" y=\"14\" width=\"12\" height=\"10\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"578\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">entrada</text><rect x=\"630\" y=\"14\" width=\"12\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"648\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">saída</text></svg>", "caption": "O prompt e o espaço para a resposta dividem uma janela. A requisição do meio tem o mesmo prompt da primeira e é recusada por pedir mais espaço."}
```

**Os quatro são erros `400`, levantados antes de qualquer geração**, então não custam nada e
terminam em milissegundos. A regra de somar o prompt ao `max_tokens` é do labllm, e também é como
a API da Anthropic trata os modelos recentes dela: recusa em vez de encurtar a resposta por você.
Outras APIs e modelos mais antigos já cortaram a saída em silêncio, o que é pior, porque a
requisição dá certo com menos do que você pediu. De um jeito ou de outro, a verificação pertence ao
seu código, antes de a requisição sair, e é isso que a aula 2 seção 09 constrói.

## Do tamanho das janelas reais

As janelas dos modelos da tabela de preços da aula 2 seção 04 vão de 200 mil tokens a pouco mais de
um milhão, e o máximo de saída por resposta, de 64 mil a 128 mil. Um milhão de tokens são vários
milhares de páginas. É fácil concluir daí que o limite deixou de importar, e três coisas dizem o
contrário:

- **Você paga por cada token de entrada em cada requisição.** Uma janela que você enche é uma conta
  que você paga, toda vez; a aula 2 seção 05 põe números nisso.
- **Uma janela cheia é mais lenta.** O modelo lê tudo antes de escrever o primeiro token, e a espera
  pelo primeiro token cresce com o prompt.
- **Uma janela cheia não é uma janela bem lida.** Modelos são mensuravelmente piores em usar
  informação enterrada no meio de um contexto muito longo do que no começo ou no fim, resultado
  publicado primeiro como *Lost in the Middle* (Liu e outros, 2023). Pôr o repositório inteiro no
  prompt não é o mesmo que o modelo tê-lo entendido. A aula 6 busca os poucos trechos que importam
  em vez disso.
