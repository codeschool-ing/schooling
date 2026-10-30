---
title: O que gasta energia num celular
version: 1
---

**A imagem comum é que um app gasta bateria enquanto calcula, então um app rápido é um app
econômico.** Num celular, o processador raramente é o que esvazia a bateria. As partes caras são as
que conversam com o mundo lá fora ou acendem: o rádio, o receptor de satélite, a tela. E o hábito
mais caro não é fazer muito trabalho. É fazer pouco trabalho com frequência, porque cada vez acorda
alguma coisa que depois demora a voltar a dormir.

| o quê | por que custa | o hábito que desperdiça |
|---|---|---|
| o rádio de dados móveis | liga a cada conexão e continua ligado depois do último byte | requisições pequenas, com frequência |
| GPS | uma posição por satélite mantém um receptor funcionando | pedir a posição precisa sem parar, quando a cidade bastaria |
| a tela | o maior consumo isolado enquanto está acesa | mantê-la acordada quando o usuário já parou de olhar |
| um wake lock | mantém o processador rodando com a tela apagada | pegar um e esquecer de soltar |
| polling | acorda tudo isso num cronômetro | perguntar "tem novidade?" a cada minuto |

## O rádio, que fica acordado depois que você termina

**O rádio é o que a maioria dos programadores nunca ouviu explicar, e é o que muda o jeito de
escrever uma sincronização.** O guia de acesso à rede do Android, lido em 30 de outubro de 2026,
descreve a máquina de estados de um rádio 3G típico com tempos da operadora AT&T. O rádio tem três
estados: *potência máxima* enquanto transfere; *potência baixa*, que corta o consumo em cerca de
metade; e *repouso*, que custa muito pouco. Subir do repouso para a potência máxima leva mais de
dois segundos, então o rádio não desce no instante em que uma transferência acaba. Ele espera.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l15-tail\" aria-label=\"Uma transferência pequena num rádio 3G típico, ao longo de uma linha do tempo em segundos. A transferência leva cerca de um segundo em potência máxima. Depois o rádio fica em potência máxima por mais 5 segundos, então em potência baixa, cerca de metade do consumo, por 12 segundos, e só então cai para o repouso. Ao todo, pelo menos 18 segundos consumindo energia por uma transferência.\"><rect x=\"40\" y=\"60\" width=\"32\" height=\"50\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"72\" y=\"60\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"152.0\" y=\"78.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">potência</text><text x=\"152.0\" y=\"91.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">máxima, à espera</text><rect x=\"232\" y=\"60\" width=\"384\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"424.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">potência baixa: cerca de metade do consumo</text><rect x=\"616\" y=\"60\" width=\"80\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"656.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">repouso</text><text x=\"56.0\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">transferência</text><path d=\"M40 130 L696 130\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M40 126 L40 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"40\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M72 126 L72 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"72\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M232 126 L232 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"232\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M616 126 L616 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"616\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18</text><text x=\"692\" y=\"146\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">segundos</text><text x=\"360\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">um rádio 3G típico, como o guia de acesso à rede do Android o descreve</text></svg>", "caption": "A transferência é a parte curta. O rádio consome energia por pelo menos 18 segundos a cada transferência, carregue ela o que carregar."}
```

Para esse rádio, a mesma página dá as esperas: potência máxima pela duração da transferência **mais
5 segundos**, depois **12 segundos** em potência baixa, então toda transferência de dados mantém o
rádio consumindo energia por pelo menos 18 segundos. O exemplo dela é o hábito de que esta aula
trata. Um app que faz uma transferência de um segundo três vezes por minuto mantém o rádio acordado
o tempo todo; os mesmos dados mandados numa transferência de três segundos por minuto o deixam em
repouso por 40 segundos de cada minuto.

A página é igualmente clara que **esses números pertencem a um rádio numa rede**. Os tempos de cauda
mudam com a tecnologia, 3G, LTE ou 5G, e quem os configura é a operadora. Então os segundos exatos
não são algo em que se apoiar. O formato é: um rádio acordado por um byte custa quase o mesmo que um
rádio acordado por muitos, e o custo de uma requisição é, na maior parte, o custo de acordar para
ela.

## Wake locks e polling, os dois que são culpa sua

**Um wake lock é uma promessa ao sistema de que você precisa do processador, e a bateria paga até
você retirar a promessa.** No Android, um app pode segurar um para continuar trabalhando com a tela
apagada. O perigo é um caminho de código que o pega e um erro que pula a liberação. Um celular com a
tela apagada e um lock preso não dorme, e nada na tela diz por quê.

**Polling é um cronômetro que acorda todo o resto.** "A cada minuto, pergunte ao servidor se algo
mudou" parece modesto, e no rádio acima é um despertar a cada minuto do dia: 1.440 deles, cada um
com a sua cauda. A alternativa é ser avisado: o servidor manda uma mensagem push quando algo de fato
mudou, que é o assunto da aula 17, e todo o resto espera um momento que o sistema escolhe, que é a
próxima etapa.

## O usuário consegue ver quem foi

**Os dois sistemas mostram ao usuário uma lista de apps ordenada pela bateria que usaram.** É nessa
lista que uma sincronização descuidada é encontrada, pela pessoa cujo celular morreu às quatro da
tarde, e o remédio que ela tem é o botão de desinstalar. É por isso que os sistemas da próxima etapa
são tão rígidos quanto são, e é por isso que a bateria deve ser tratada como algo emprestado.
