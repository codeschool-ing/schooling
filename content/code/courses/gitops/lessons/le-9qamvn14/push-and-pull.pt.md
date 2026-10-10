---
title: Push e pull: quem guarda as chaves
version: 1
---

**A maioria dos pipelines de deploy empurra.** Uma mudança entra no merge, um job de CI constrói uma
imagem, e o mesmo job roda `kubectl apply` ou `helm upgrade` contra o cluster. Funciona, e tem três
propriedades que só aparecem depois.

A primeira é **onde ficam as credenciais**. Para empurrar para o cluster, o sistema de CI precisa de
uma credencial capaz de mudar o cluster, quase sempre uma capaz de mudar o cluster inteiro. Todo job
que roda nesse CI, inclusive os de branches que ninguém revisou, está a um passo dela. O curso
`testing-cicd` passa a aula 9 limitando o estrago, e o limite nunca chega a zero enquanto o próprio
pipeline guarda a chave.

A segunda é **o que o pipeline sabe**. Um push acontece uma vez, no fim de um job, e depois o job
acaba. Se alguém muda o cluster uma hora depois, nada percebe. Se o apply falhou pela metade, o
pipeline ficou vermelho e o cluster continua meio mudado até alguém rodar de novo.

A terceira é **onde está a verdade**. Depois de alguns meses de pushes, correções urgentes e
comandos manuais, a resposta honesta para "o que está rodando em produção?" é "pergunte ao cluster".
O repositório guarda o que alguém pretendia publicar, em algum momento.

## Invertendo a direção

O GitOps inverte o sentido. **Um agente dentro do cluster puxa**: ele lê o estado desejado de um
repositório e muda o cluster para combinar com ele. O sistema de CI constrói imagens e, no máximo,
escreve um commit; ele nunca fala com o cluster.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Dois pipelines lado a lado. À esquerda, push: o CI guarda as credenciais do cluster e aplica mudanças nele. À direita, pull: o CI só faz commit no Git, e um agente dentro do cluster lê o Git e aplica.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"300\" fill=\"var(--ink)\"/><text x=\"180\" y=\"28\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">push</text><text x=\"540\" y=\"28\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">pull</text><line x1=\"360\" y1=\"15\" x2=\"360\" y2=\"285\" stroke=\"var(--wire)\" stroke-dasharray=\"4 4\"/><rect x=\"40\" y=\"50\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"95\" y=\"77\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git</text><rect x=\"40\" y=\"130\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"95\" y=\"157\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">job de CI</text><rect x=\"200\" y=\"200\" width=\"130\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"265\" y=\"240\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">cluster</text><line x1=\"95\" y1=\"94\" x2=\"95\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"90,122 100,122 95,130\" fill=\"var(--paper-dim)\"/><line x1=\"150\" y1=\"160\" x2=\"222\" y2=\"198\" stroke=\"var(--amber)\" stroke-width=\"2\"/><polygon points=\"214,200 226,201 219,191\" fill=\"var(--amber)\"/><text x=\"118\" y=\"204\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">kubectl apply,</text><text x=\"118\" y=\"220\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">com as chaves</text><rect x=\"400\" y=\"50\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"455\" y=\"77\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">job de CI</text><rect x=\"570\" y=\"50\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"625\" y=\"77\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git</text><line x1=\"510\" y1=\"72\" x2=\"564\" y2=\"72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"562,67 562,77 570,72\" fill=\"var(--paper-dim)\"/><text x=\"537\" y=\"112\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">um commit</text><rect x=\"520\" y=\"170\" width=\"170\" height=\"100\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"605\" y=\"258\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">cluster</text><rect x=\"545\" y=\"185\" width=\"120\" height=\"40\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"605\" y=\"210\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">agente</text><line x1=\"625\" y1=\"181\" x2=\"625\" y2=\"100\" stroke=\"var(--phosphor)\" stroke-width=\"2\"/><polygon points=\"620,104 630,104 625,96\" fill=\"var(--phosphor)\"/><text x=\"634\" y=\"145\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--phosphor)\">lê</text></svg>", "caption": "No push, o job de CI guarda as chaves do cluster e age uma vez. No pull, o job de CI só faz commit, e o agente que guarda as chaves vive dentro do cluster e não para de ler.", "same": ["push", "pull", "Git", "cluster", "kubectl apply,"]}
```

Cada uma das três propriedades muda. **A credencial que muda o cluster nunca sai dele**: o agente
roda lá dentro com uma service account, e o que chega ao mundo de fora é um token só de leitura do
repositório. **O agente continua olhando**, então uma mudança manual ou um apply que falhou são
percebidos na próxima passada dele, e não no próximo deploy. E **o repositório vira a verdade**,
porque tudo o que o cluster tem e o repositório não diz é, por definição, uma diferença a corrigir.

O pull também tem custos, e eles são reais. Uma mudança vale quando o agente olhar de novo, e não
quando o pipeline termina. O próprio agente precisa ser instalado, atualizado e vigiado. E o
repositório vira a coisa mais valiosa que você tem, porque quem escreve nele muda a produção. A aula
2 é sobre protegê-lo.
