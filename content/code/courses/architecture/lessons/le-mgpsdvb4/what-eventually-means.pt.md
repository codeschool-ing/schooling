---
title: O que "eventualmente" promete, e o que deixa de fora
version: 1
---

Um sistema é **eventualmente consistente** quando uma coisa é garantida: se as escritas pararem, toda
cópia dos dados termina com o mesmo valor. Werner Vogels disse isso assim em 2008, escrevendo sobre os
armazenamentos por trás da loja da Amazon, e a definição não mudou desde então.

Leia de novo prestando atenção no que fica de fora. Ela não diz **quanto tempo** é "eventualmente": um
segundo, uma hora, ou enquanto um consumidor estiver fora do ar. Não diz **o que um leitor vê** nesse
meio-tempo, nem em que ordem. E não diz **o que acontece quando duas cópias mudam ao mesmo tempo**,
além da promessa de que no fim vão concordar em alguma coisa.

O outro extremo se chama **consistência forte**, ou, na sua forma mais estrita, **linearizabilidade**:
depois que uma escrita retornou, toda leitura em qualquer lugar a vê, como se houvesse uma cópia só. A
aula anterior mostrou quanto isso custa. Um sistema que a mantém se recusa a responder quando não tem
certeza, e espera uma ida e volta em todo commit quando nada está errado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas linhas do tempo, o serviço de estoque em cima e a cópia da loja embaixo. Na primeira marca o serviço de estoque muda o café de 12 para 11. O evento chega à cópia dois segundos depois. Toda leitura da cópia entre as duas marcas responde 12. Esse trecho é a janela de inconsistência.\"><defs><marker id=\"l9-window-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l9-window-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l9-window-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M250 172 L510 172\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"380\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a janela: leituras aqui respondem 12</text><text x=\"30\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">estoque</text><text x=\"30\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">loja b</text><path d=\"M100 62 L690 62\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l9-window-ah-wire)\"></path><path d=\"M100 142 L690 142\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l9-window-ah-wire)\"></path><text x=\"150\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">12</text><text x=\"380\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">11</text><text x=\"170\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">12</text><text x=\"600\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">11</text><circle cx=\"250\" cy=\"62\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"510\" cy=\"142\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><path d=\"M254 67 L505 137\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l9-window-ah-phosphor)\"></path><text x=\"250\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">PUT 11</text><text x=\"560\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">evento aplicado</text><path d=\"M300 170 L300 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l9-window-ah-amber)\"></path><path d=\"M360 170 L360 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l9-window-ah-amber)\"></path><path d=\"M420 170 L420 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l9-window-ah-amber)\"></path><path d=\"M470 170 L470 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l9-window-ah-amber)\"></path><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "A janela é o tempo entre o dono mudar e a cópia ficar sabendo. Toda leitura dentro dela recebe o valor velho, e nada na tela diz isso."}
```

## Já está no curso

O curso já a encontrou duas vezes. A aula 5 listou um jeito de a loja saber o estoque sem perguntar: o
serviço de estoque publica um evento cada vez que uma contagem muda, e a loja mantém a sua própria
cópia, um pouco atrasada. Esta aula constrói exatamente isso. E na aula 8 o standby assíncrono
respondeu leituras com um valor que o primário já tinha mudado.

Ela também aparece em lugares que ninguém projeta como "uma cópia". Uma **réplica de leitura** atrás de
um banco. Um **cache** na frente de um serviço. Um **índice de busca** alimentado pelo banco, que a aula
17 constrói. Uma **CDN** guardando a página de ontem. Um **relatório** montado toda noite. Cada um
responde a partir de uma cópia que o dono atualiza depois, e cada um tem uma janela em que a cópia está
errada.

## O que a aula cobre

"Eventualmente" é a parte fácil. A aula é sobre o que fica em volta, e cada item ganha uma seção:

| pergunta que "eventualmente" deixa aberta | a seção |
| --- | --- |
| qual o tamanho da janela, e o que a aumenta | a janela |
| uma pessoa vê a própria mudança | ler as próprias escritas |
| uma pessoa pode ver o tempo andar para trás | leituras monotônicas |
| um evento atrasado pode desfazer um mais novo | ordem e convergência |
| o que acontece quando dois lugares mudam a mesma coisa | o último a escrever vence |
| o que a tela deveria dizer sobre tudo isso | o que dizer ao cliente |

As garantias do meio da tabela têm nome porque Douglas Terry e colegas deram esses nomes em 1994, para
um sistema chamado Bayou: **garantias de sessão**, promessas feitas a um usuário sobre o que esse usuário
vê, mais baratas que consistência forte para todo mundo. São o que faz um sistema eventualmente
consistente parecer consistente para a pessoa na frente dele.
