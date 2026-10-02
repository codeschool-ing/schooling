---
title: O caminho crítico
version: 1
---

O tempo próprio diz quem fez o trabalho. Ele ainda não diz **o que deixar mais rápido**, e as duas
coisas se separam assim que algo roda em paralelo.

O **caminho crítico** é a cadeia de spans que encerra a requisição: comece pelo fim da raiz, ache o
filho que terminou por último, entre nele e repita. Encurtar um span dessa cadeia encurta a requisição;
encurtar um span fora dela não encurta nada, porque a requisição estava esperando outra coisa naquele
momento.

Na loja toda chamada é feita uma depois da outra, então o caminho crítico de um checkout é ele inteiro,
e a lição é aritmética. Dos 439 ms, a rede de cartões responde por 400. Deixar o `INSERT` dez vezes
mais rápido economiza menos de um milissegundo; acabar com a conexão que o `orders` abre por
mensagem economiza talvez vinte; **a única mudança que um cliente poderia notar está no payments**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma requisição de 300 ms cujo handler chama dois serviços ao mesmo tempo. A chamada de preços leva 280 ms e a de estoque, 120 ms. O caminho crítico passa pela requisição e pela chamada de preços. O estoque tem 160 ms de folga: deixá-lo mais rápido não muda nada.\"><defs><marker id=\"cp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"200\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 ms</text><text x=\"680.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300 ms</text><path d=\"M200 40 L200 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M680.0 40 L680.0 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET /product</text><rect x=\"200\" y=\"62\" width=\"480.0\" height=\"16\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">prices</text><rect x=\"216.0\" y=\"102\" width=\"448.0\" height=\"16\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">stock</text><rect x=\"216.0\" y=\"142\" width=\"192.0\" height=\"16\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M408.0 150 L664.0 150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"536.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">folga: 160 ms</text><text x=\"440.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">caminho crítico: a requisição, depois os preços</text></svg>", "caption": "Dois filhos em paralelo. A requisição termina quando o mais lento termina, então os 160 ms de folga do mais rápido são um tempo que ninguém espera."}
```

Onde as chamadas rodam mesmo em paralelo, o quadro muda. Uma página que pede preços e estoque ao
mesmo tempo espera pela mais lenta das duas, e a mais rápida tem **folga**: ela poderia demorar mais e
ninguém perceberia. Daí saem duas armadilhas:

- **Otimizar o span com mais tempo próprio pode não adiantar nada.** Se ele está fora do caminho
  crítico, o tempo dele já estava escondido atrás de um irmão mais longo.
- **Tornar uma chamada paralela move o caminho crítico em vez de eliminá-lo.** O novo caminho passa
  pelo irmão que agora é o mais lento, e esse é o span a ler em seguida.

O trabalho assíncrono é o extremo disso. O mailer está totalmente fora do caminho crítico do checkout,
mas é o caminho crítico inteiro de outra pergunta, *quando o cliente recebeu o e-mail?* **Um rastro
responde a pergunta que você fizer a ele**, e o span que você lê primeiro depende de qual pergunta é.
