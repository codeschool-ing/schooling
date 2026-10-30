---
title: No máximo, pelo menos, exatamente: uma pergunta sobre uma queda
version: 1
---

**Uma garantia de entrega é a resposta a uma pergunta: quando um leitor cai, o que acontece com o
evento que ele estava tratando?** Um leitor de um event hub faz duas coisas com cada evento, numa
certa ordem: faz o trabalho, somar um pagamento a um total ou gravar uma linha, e registra até onde
chegou, o checkpoint da lição 22. Uma queda entre as duas é o assunto da garantia, e a ordem dos dois
passos é o que a decide.

**Checkpoint primeiro, depois o trabalho, é no máximo uma vez.** Se o processo morre depois do
checkpoint e antes do trabalho, o leitor reiniciado começa depois do checkpoint, e o evento nunca é
tratado. Nada é feito duas vezes e às vezes algo nunca é feito.

**O trabalho primeiro, depois o checkpoint, é pelo menos uma vez.** Se o processo morre depois do
trabalho e antes do checkpoint, o leitor reiniciado começa do checkpoint anterior e faz o trabalho de
novo. Nada se perde e às vezes algo é feito duas vezes. O `checkpointed.py` da lição 22 chamava o
`update_checkpoint` depois de tratar o evento, e assim faz todo exemplo que a Microsoft publica para
essas bibliotecas: pelo menos uma vez é o padrão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas ordens dos mesmos dois passos, com uma queda entre eles. Em cima, pelo menos uma vez: fazer o trabalho, depois a queda, depois o checkpoint que não aconteceu; o reinício começa no checkpoint antigo e o trabalho é feito de novo. Embaixo, no máximo uma vez: checkpoint primeiro, depois a queda, depois o trabalho que não aconteceu; o reinício começa depois do checkpoint novo e o trabalho nunca é feito.\" data-fig=\"l24-order\"><text x=\"20\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pelo menos uma vez</text><rect x=\"170\" y=\"30\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fazer o trabalho</text><line x1=\"322\" y1=\"46\" x2=\"366.0\" y2=\"46.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><polygon points=\"372,46 366.0,49.0 366.0,43.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"374\" y=\"30\" width=\"90\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"419\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">queda</text><line x1=\"466\" y1=\"46\" x2=\"510.0\" y2=\"46.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><polygon points=\"516,46 510.0,49.0 510.0,43.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"518\" y=\"30\" width=\"150\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"593\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">checkpoint</text><text x=\"170\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">reinício no checkpoint antigo: o trabalho é feito de novo</text><text x=\"20\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no máximo uma vez</text><rect x=\"170\" y=\"140\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">checkpoint</text><line x1=\"322\" y1=\"156\" x2=\"366.0\" y2=\"156.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><polygon points=\"372,156 366.0,159.0 366.0,153.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"374\" y=\"140\" width=\"90\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"419\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">queda</text><line x1=\"466\" y1=\"156\" x2=\"510.0\" y2=\"156.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><polygon points=\"516,156 510.0,159.0 510.0,153.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"518\" y=\"140\" width=\"150\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"593\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fazer o trabalho</text><text x=\"170\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">reinício depois do checkpoint novo: o trabalho nunca é feito</text></svg>", "caption": "A mesma queda em dois lugares: depois do trabalho ela repete um evento, depois do checkpoint ela perde um.", "same": ["checkpoint"]}
```

**Exatamente uma vez não é uma terceira ordem.** Não há como arrumar duas gravações separadas, uma
no destino e outra no armazenamento de checkpoints, de modo que uma queda entre elas deixe as duas ou
nenhuma. O que se chama de exatamente uma vez é uma de duas coisas: o trabalho e o checkpoint gravados
num passo atômico, no mesmo lugar, ou entrega pelo menos uma vez num destino onde fazer o trabalho
duas vezes não muda nada. As duas últimas seções desta lição são essas duas.

## O que os serviços do Azure prometem

**Esta parte vem da documentação da Microsoft e não foi executada.** Cada serviço declara a sua
garantia, e nenhum diz exatamente uma vez de ponta a ponta:

| serviço | o que a documentação promete |
|---|---|
| Event Hubs | pelo menos uma vez: um evento sem checkpoint do leitor é entregue de novo |
| Stream Analytics | processamento exatamente uma vez dentro do job, e entrega pelo menos uma vez às saídas |
| o gatilho do Event Hubs no Azure Functions | pelo menos uma vez: uma function que falha ou estoura o tempo vê o lote de novo |

**Pelo menos uma vez é o padrão em todo lugar, porque é a única das três que não perde nada.** No
máximo uma vez serve para um painel de contagens aproximadas e é errado para qualquer coisa que seja
dinheiro. O que pelo menos uma vez custa é que todo leitor precisa sobreviver a ver um evento duas
vezes, e a próxima seção conta as maneiras de isso acontecer.
