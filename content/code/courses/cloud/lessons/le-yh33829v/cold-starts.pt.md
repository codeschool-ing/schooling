---
title: Cold starts, as partidas a frio
version: 1
---

Escalar até zero tem um preço, e quem paga é uma requisição. **Quando nenhuma cópia da função está
pronta, a plataforma precisa criar uma antes de responder, e a requisição que chegou espera enquanto
isso acontece.** Essa espera é um cold start, uma partida a frio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas linhas do tempo que começam quando chega uma requisição. Uma invocação fria primeiro cria um ambiente de execução, depois carrega o código, depois roda a inicialização do módulo, e só então roda o handler e responde. Uma invocação quente reaproveita um ambiente já inicializado e roda o handler na hora. As larguras não são medidas.\"><defs><marker id=\"sl-cold-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">Fria</text><rect x=\"110\" y=\"52\" width=\"120\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"170.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ambiente novo</text><rect x=\"230\" y=\"52\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"285.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">carrega o código</text><rect x=\"340\" y=\"52\" width=\"150\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">init: código do módulo</text><rect x=\"490\" y=\"52\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">handler</text><path d=\"M600 70 L630 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-cold-ah)\"></path><text x=\"636\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">resposta</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">Quente</text><rect x=\"110\" y=\"132\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"165\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">handler</text><path d=\"M220 150 L250 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-cold-ah)\"></path><text x=\"256\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">resposta</text><path d=\"M110 34 L110 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"110\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">chega a requisição</text><path d=\"M110 100 L338 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"224\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a parte da plataforma</text><path d=\"M342 100 L598 100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"470\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a sua: o que fica fora do handler</text><text x=\"20\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">As larguras dizem quais fases acontecem, não quanto duram: nada aqui foi cronometrado.</text></svg>", "caption": "Um cold start são as três primeiras caixas. Uma chamada quente pula as três, e por isso a primeira requisição depois de um tempo parado é a lenta.", "same": ["handler"]}
```

Fase por fase, no Lambda:

1. Chega uma requisição e nenhum ambiente de execução está livre: ainda não existe nenhum, ou todos
   estão ocupados com outras requisições.
2. A plataforma cria um ambiente de execução novo, uma pequena máquina virtual isolada com o runtime
   que você escolheu, e põe o seu código dentro dele.
3. O runtime sobe e roda o seu código do nível do módulo, o init. No handler desta aula isso é o
   `import json` e duas atribuições; numa função de verdade costumam ser imports grandes e os
   clientes de um banco de dados e de outros serviços.
4. Só então o handler é chamado com o evento, e a resposta volta.

Depois da resposta o ambiente não é jogado fora. **Ele é congelado e guardado, e a próxima requisição
que chega a ele pula direto para o passo 4: uma partida a quente.** Por quanto tempo um ambiente
ocioso é mantido não é um número que a AWS publica, e um projeto não deve depender dele. Uma função
chamada a cada poucos segundos vive quase só de partidas a quente. Uma função chamada algumas vezes
por hora pode dar com um cold start na maioria das chamadas.

**É por isso que a primeira requisição depois de um tempo parado é a lenta**, e por isso um teste de
carga com tráfego constante pode parecer melhor que um dia real, cheio de picos. Um pico também é onde
os cold starts se acumulam: cinquenta requisições chegando juntas numa função com cinco ambientes
quentes quer dizer uns quarenta e cinco ambientes novos criados de uma vez, cada um pagando os três
primeiros passos.

Esta aula não cita durações. Nenhuma foi medida aqui, e elas dependem do runtime, do tamanho do
código e do que o init faz. O que dá para dizer sem cronômetro é de quem é cada parte: **o passo 2 é
da plataforma, e o passo 3 é, na maior parte, o código que você pôs no nível do módulo.**

## Tire o trabalho do handler, e deixe o init pequeno

Duas regras puxam para lados opostos, e as duas estão certas.

**O que é reaproveitado entre chamadas fica fora do handler**: o cliente do banco de dados, a
configuração lida, o modelo carregado de um arquivo. Criado ali, é pago uma vez por ambiente e
reaproveitado por cada chamada quente depois. Criado dentro do handler, é pago em toda chamada,
quente ou fria.

**Mesmo assim, o init deve fazer só o que toda chamada precisa.** Importar uma biblioteca grande que
só um caminho raro usa faz todo cold start pagar por ela, inclusive os que nunca passam por esse
caminho. Importe-a dentro do ramo que precisa dela.

Os provedores vendem jeitos de contornar o cold start. No Lambda, a provisioned concurrency mantém
um número de ambientes inicializados de antemão e é cobrada pelo tempo em que está configurada,
usada ou não, o que devolve parte do que escalar até zero economizou. O SnapStart restaura um
ambiente a partir de um snapshot tirado depois do init, nos runtimes que têm suporte. **Nenhum dos
dois acaba com a troca; cada um a desloca.** O Cloudflare Workers faz uma troca diferente, três
seções adiante.
