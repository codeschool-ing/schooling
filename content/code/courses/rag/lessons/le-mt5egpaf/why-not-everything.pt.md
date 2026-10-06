---
title: Por que não colocar tudo no prompt
version: 1
---

Se um documento no prompt resolve uma pergunta, os treze deveriam resolver todas. É a primeira ideia
que todo mundo tem, e para um corpus pequeno o bastante e uma janela grande o bastante ela até
funciona. Medida neste, ela falha antes de começar, e os motivos da falha continuam valendo muito
depois de a janela ficar grande o bastante.

## Contando o corpus

Um provedor conta em tokens, então o corpus também tem de ser contado em tokens. O `count.py` usa o
`cl100k_base` do tiktoken, a codificação com que o labgen conta:

```
ana@lab:~/rag$ python count.py
   816  data/docs/affiliate-api.md
   660  data/docs/ebooks-and-audiobooks.md
   483  data/docs/finance-refund-controls.md
   342  data/docs/gift-cards.md
   617  data/docs/payments-and-invoices.md
   626  data/docs/privacy-notice.md
   403  data/docs/returns-policy-2025.md
 1,113  data/docs/returns-policy.md
   726  data/docs/seller-agreement.md
   845  data/docs/shipping-and-delivery.md
   906  data/docs/support-handbook.md
   841  data/docs/terms-of-sale.md
   536  data/docs/warehouse-runbook.md
 8,914  in all
```

**8.914 tokens para 6.843 palavras**, cerca de 1,3 token por palavra, o normal para prosa em inglês com
alguns números e identificadores. O `everything.py` põe os treze num prompt só, numerados, e pergunta
o preço da entrega expressa:

```
ana@lab:~/rag$ python everything.py
refused: prompt is too long: 9072 tokens + 256 max_tokens > 8192 maximum
```

A requisição tinha 9.072 tokens, os documentos mais seus números, nomes e a pergunta, e o provedor a
recusou antes de ler uma palavra. Os 256 são o espaço reservado para a resposta: uma requisição tem de
caber com o que manda **e** com o que pede de volta, e o labgen reserva 256 quando a requisição não diz
de que tamanho quer a resposta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três barras medidas em tokens. Todos os documentos e uma pergunta: 9.072, mais que a janela. A janela do extract-1, para prompt e resposta juntos: 8.192. Um documento e uma pergunta: 1.144.\"><text x=\"218\" y=\"54\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">todos os documentos</text><text x=\"218\" y=\"71\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e uma pergunta</text><rect x=\"230\" y=\"44\" width=\"440.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"678.0\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9.072</text><text x=\"218\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a janela do extract-1</text><text x=\"218\" y=\"133\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">prompt e resposta</text><rect x=\"230\" y=\"106\" width=\"397.3\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"2\"></rect><text x=\"635.3192239858906\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8.192</text><text x=\"218\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um documento</text><text x=\"218\" y=\"195\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e uma pergunta</text><rect x=\"230\" y=\"168\" width=\"55.5\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"293.4850088183422\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.144</text><text x=\"230\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a primeira barra tem 880 tokens a mais que a segunda</text></svg>", "caption": "Os treze documentos e uma pergunta somam 9.072 tokens, que não cabem; um documento e a mesma pergunta somam 1.144. Todos os números foram impressos pelo laboratório."}
```

## Suponha que coubesse

Uma janela de um milhão de tokens levaria este corpus cem vezes. Restam três custos, e cada um cresce
com o corpus, não com a pergunta.

**Toda pergunta paga por todos os documentos.** A um preço ilustrativo de 3 por milhão de tokens de
entrada, que não é o de nenhum provedor, um prompt de 9.072 tokens custa 0,027 para mandar, e dez mil
perguntas por dia custam 272 por dia antes de uma única palavra de resposta. As mesmas perguntas com um
documento relevante custam cerca de um oitavo disso. Os provedores guardam em cache um prefixo repetido
com desconto, e a aula 17 conta o que isso compra, mas um desconto sobre um texto de que a pergunta não
precisava ainda é um preço por um texto de que a pergunta não precisava.

**Toda pergunta espera por todos os documentos.** Um modelo lê o prompt inteiro antes de escrever o
primeiro token da resposta, e ler leva tempo proporcional ao tamanho. Um chat de atendimento que lê o
manual do armazém antes de responder uma pergunta sobre vale-presente fica mais lento por um motivo que
o cliente não enxerga.

**Toda pergunta disputa com todos os documentos.** Quanto mais texto sem relação um prompt carrega,
mais chances a resposta tem de usar a parte errada. Um único documento já puxou uma frase sobre livros
com defeito para uma resposta sobre o prazo de devolução, na seção anterior a esta. Pesquisadores que
mediram modelos reais com contextos longos viram que eles usam melhor a informação do começo e do fim
de um prompt longo do que a do meio; o artigo é *Lost in the Middle*, de Liu e outros, 2023. Este
laboratório não consegue reproduzir esse resultado, porque o extract-1 lê todas as frases do mesmo
jeito, e a aula 12 volta ao que isso significa para a forma de montar um prompt.

## E o corpus cresce

Treze documentos é um corpus de ensino. A base de conhecimento de uma equipe de atendimento de verdade
tem milhares de artigos, a de um escritório de advocacia tem milhões de páginas, e as duas mudam toda
semana. O que cabe hoje não vai caber no ano que vem, e um projeto que depende de caber tem data para
quebrar.

Então a pergunta útil não é *como faço tudo caber*, e sim **como encontro, para esta pergunta, os
poucos trechos que a respondem, e mando só esses.** Isso é recuperação, e a próxima seção constrói a
versão mais simples dela.
