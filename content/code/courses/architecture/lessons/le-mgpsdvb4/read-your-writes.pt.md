---
title: Ler as próprias escritas: a pessoa que acabou de mudar
version: 1
---

A janela é inofensiva para a maioria dos leitores, que não distinguem 12 de 11 e não se importariam.
Não é inofensiva para **a pessoa que fez a mudança**, porque ela sabe qual deveria ser o número. Uma
pessoa da equipe da Quitanda marca o café como esgotado, depois abre a página do produto para conferir:

```
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8001/stock/coffee -d 0; curl -s localhost:8003/product/coffee
coffee: 0 in stock, version 13
shop-b: coffee: 1 left, version 12
```

O serviço de estoque confirmou 0. A página diz 1. A pessoa da equipe faz a coisa razoável, conclui que a
mudança não pegou, e a faz de novo, ou liga para alguém, ou para de confiar na tela de administração.
Nada estava errado, exceto a ordem em que dois fatos verdadeiros chegaram até ela.

A garantia de que ela precisava é **ler as próprias escritas** (*read-your-writes*): depois que uma
pessoa escreve alguma coisa, as leituras dela veem isso, mesmo que as leituras dos outros ainda não
vejam. É uma das garantias de sessão de Terry, e é bem mais barata que consistência forte, porque é uma
promessa a uma pessoa sobre as próprias mudanças.

## A versão viaja com a pessoa

O serviço de estoque responde a toda escrita com a versão que ela criou. Se a próxima leitura levar
essa versão, a cópia consegue saber se está atrasada, e mandar a leitura para o dono quando estiver. A
loja `b` faz isso com `?after=`:

```
ana@vm:~/lab/eventual$ curl -s 'localhost:8003/product/coffee?after=13'
shop-b: coffee: 0 in stock, version 13 (copy behind, asked the stock service)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma sequência entre três participantes: uma pessoa da equipe, a loja b e o serviço de estoque. A pessoa da equipe define o café como 0 no serviço de estoque e recebe de volta a versão 13. Ela abre a página do produto na loja b com after=13. A cópia da loja b está na versão 12, mais velha que 13, então a loja b pergunta ao serviço de estoque e responde 0 em estoque, versão 13.\"><defs><marker id=\"l9-ryw-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l9-ryw-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"26\" width=\"160\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">equipe</text><path d=\"M110 56 L110 276\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"280\" y=\"26\" width=\"160\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">loja b (cópia em 12)</text><path d=\"M360 56 L360 276\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"530\" y=\"26\" width=\"160\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">estoque</text><path d=\"M610 56 L610 276\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M113 80 L607 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-ryw-ah-phosphor)\"></path><text x=\"230\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PUT coffee 0</text><path d=\"M607 108 L113 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l9-ryw-ah-phosphor)\"></path><text x=\"230\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">versão 13</text><path d=\"M113 146 L357 146\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-ryw-ah-amber)\"></path><text x=\"235\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET coffee?after=13</text><text x=\"368\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">12 &lt; 13: atrasada</text><path d=\"M363 198 L607 198\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-ryw-ah-amber)\"></path><text x=\"485\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET coffee</text><path d=\"M607 222 L363 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l9-ryw-ah-amber)\"></path><text x=\"485\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">0, versão 13</text><path d=\"M357 252 L113 252\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l9-ryw-ah-phosphor)\"></path><text x=\"235\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">0, versão 13</text></svg>", "caption": "Ler as próprias escritas com uma versão: a resposta da escrita traz a versão, a leitura seguinte pede pelo menos essa, e uma cópia atrasada manda a leitura para o dono."}
```

A cópia da loja `b` ainda estava em 12, então ela perguntou ao serviço de estoque, e disse isso. Um
navegador guardaria a versão num cookie ou na própria página; a tela de administração de uma loja de
verdade faria isso sem a pessoa da equipe jamais ver um número. **O dono só é consultado quando a cópia
está atrasada e quem lê é quem escreveu**, então a carga que a cópia existe para absorver fica, na maior
parte, nela.

## Os outros jeitos de conseguir isso

| abordagem | como | o que custa |
| --- | --- | --- |
| uma versão, como acima | a escrita devolve uma, a leitura pede pelo menos essa | todo leitor da cópia tem de entender versões |
| ler do dono por um tempo | depois que uma pessoa escreve, mandar as leituras dela para o dono durante, digamos, o próximo minuto | um palpite sobre o tamanho da janela, e falha quando a janela é maior |
| mostrar o que foi escrito | a tela mostra o valor que a escrita devolveu, e não o lê de volta | nada, quando serve; a próxima carga da página ainda pode vir velha |
| ler sempre do dono, nesta tela | a tela de administração fala com o serviço de estoque; só as páginas públicas usam a cópia | o dono carrega o tráfego de administração, que costuma ser pequeno |

As duas últimas são as mais comuns na prática, e as mais simples. **A correção muitas vezes é ler os
dados da própria pessoa de onde ela os escreveu**, e deixar as cópias para todo o resto.
