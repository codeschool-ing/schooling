---
title: "Atores: uma caixa de correio, estado privado e uma mensagem de cada vez"
version: 1
---

**Um ator é um objeto que ninguém chama.** Ele tem um estado que só ele vê, uma caixa de correio onde
as mensagens esperam, e um comportamento que tira uma mensagem, trata dela por completo, e só então
tira a próxima. Outro código nunca alcança o interior dele. Manda uma mensagem e segue em frente.

Quem conhece atores pelo Akka ou pelo Erlang muitas vezes os imagina como threads, e essa imagem
erra de um jeito que importa. Uma thread é um jeito de rodar código; um ator é um jeito de ser dono de
um estado. Um ator roda em alguma thread quando tem mensagens, e um sistema com um milhão de atores
pode ter oito threads entre todos eles, porque a maioria dos atores fica parada a maior parte do
tempo. O que faz de algo um ator é a regra de acesso; a maquinaria que o roda pode variar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" data-fig=\"l17-anatomy\" aria-label=\"Um ator e o código que fala com ele. À esquerda, três remetentes, o balcão norte, o balcão sul e o site, mandam cada um uma mensagem com tell, que retorna na hora. As mensagens esperam na caixa de correio, uma fila desenhada como três espaços: GiveBack, Lend e Lend, com a mais antiga à direita, a próxima a ser tratada. A caixa de correio, o comportamento receive e o estado privado, um dicionário de exemplares, ficam dentro de uma fronteira tracejada, o ator da estante. Uma mensagem de cada vez vai da caixa de correio para o receive, que é o único a ler e escrever o estado. Nada fora da fronteira alcança o estado.\"><defs><marker id=\"l17-anatomy-dp-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l17-anatomy-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"45.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">balcão norte</text><path d=\"M140.0 60.0 L205.0 113.8 L240.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-anatomy-dp-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"110.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">balcão sul</text><path d=\"M140.0 125.0 L205.0 130.0 L240.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-anatomy-dp-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"175.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">site</text><path d=\"M140.0 190.0 L205.0 146.2 L240.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-anatomy-dp-ah-paper-dim)\"></path><text x=\"80.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">tell retorna na hora</text><rect x=\"225.0\" y=\"25.0\" width=\"460.0\" height=\"210.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"240.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o ator da estante</text><text x=\"345.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">caixa de correio</text><rect x=\"250.0\" y=\"117.0\" width=\"60.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GiveBack</text><rect x=\"316.0\" y=\"117.0\" width=\"60.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Lend</text><rect x=\"382.0\" y=\"117.0\" width=\"60.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"412.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Lend</text><text x=\"412.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">próxima</text><path d=\"M448.0 130.0 L520.0 100.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-anatomy-dp-ah-paper)\"></path><text x=\"480.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">uma de cada vez</text><rect x=\"520.0\" y=\"72.0\" width=\"150.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">receive(message)</text><rect x=\"520.0\" y=\"150.0\" width=\"150.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">_copies</text><text x=\"595.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{'Iracema': 1}</text><path d=\"M595.0 116.0 L595.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-anatomy-dp-ah-paper-dim)\" marker-start=\"url(#l17-anatomy-dp-ah-paper-dim)\"></path><text x=\"595.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">privado: nenhuma referência fora</text></svg>", "caption": "Os remetentes só alcançam a caixa de correio. Atrás dela, um único trecho de código trata uma mensagem de cada vez e é o único que toca o estado."}
```

## As três coisas que um ator pode fazer

A definição de Hewitt é curta. Quando um ator trata uma mensagem, ele pode:

1. mandar um número finito de mensagens a atores cujo endereço conhece;
2. criar um número finito de atores novos;
3. decidir como vai tratar a próxima mensagem, que é como o estado dele muda.

Só isso. Ele não pode alcançar o estado de outro ator, e nada pode alcançar o dele. Os campos dele
são privados no sentido mais forte. O sublinhado do Python é uma convenção; aqui nenhum outro código
sequer tem uma referência a eles. A lição 1 chamou o encapsulamento de um objeto cumprindo as
próprias promessas; um ator é encapsulamento que se mantém mesmo quando há duas threads envolvidas.

## Uma mensagem de cada vez

**Dentro de um ator não há concorrência nenhuma.** O comportamento dele é código sequencial comum:
ler um campo, verificá-lo, mudá-lo. A corrida da seção anterior precisava de dois trechos de código
rodando o verificar-e-agir ao mesmo tempo, e aqui só existe um. Os balcões continuam rodando ao mesmo
tempo; o que eles fazem ao mesmo tempo agora é pôr mensagens numa fila, e uma fila é feita para
aguentar dois `put` simultâneos.

Isso desloca a dificuldade em vez de apagá-la. A concorrência agora acontece entre atores, por
mensagens, e as mensagens chegam numa ordem que ninguém controla por inteiro. Dois balcões que mandam
*empreste Iracema* no mesmo instante serão atendidos em alguma ordem; quem ganha continua decidido
pelo tempo. O que não pode mais acontecer é a estante acabar com menos um, porque a regra sobre a
estante roda do começo ao fim sem interrupção.

## Mensagens são valores

Uma mensagem é dado: um título, uma quantia, um endereço de resposta. Ela deve ser imutável, e os
exemplos desta lição usam dataclasses congeladas por esse motivo. Se um balcão pudesse mandar um
dicionário e depois alterá-lo enquanto ele espera na caixa de correio, dois trechos de código
voltariam a compartilhar estado, e a corrida voltaria pela porta dos fundos. O Erlang torna isso
impossível copiando toda mensagem; o Akka pede que você mande objetos imutáveis e confia em você; o
Python, aqui, também confia.

Valores também deixam as mensagens fáceis de ler. `Lend("Iracema", "north desk")` diz o que quer dizer
sem uma assinatura de método para consultar, e um log das mensagens que um ator recebeu é um relato
completo de por que ele está no estado em que está. O event store da lição 9 tinha a mesma
propriedade, pelo mesmo motivo.

## O que você abre mão

Uma chamada de método devolve um valor; uma mensagem não. Quando um balcão precisa de uma resposta,
como *quantos exemplares sobraram?*, ele precisa mandar uma pergunta com um endereço de resposta e
esperar uma mensagem de volta. A seção 05 constrói isso, e mostra como um ator pode esperar por si
mesmo para sempre. Uma chamada também ou acontece ou lança exceção; uma mensagem pode se perder, ou o
ator pode ter caído antes de lê-la. As seções 06 e 07 tratam de cada caso. Em troca você ganha um
estado que a intercalação não corrompe, e uma unidade que pode ser reiniciada, levada para outro
processo ou espalhada por muitas máquinas sem que quem a chama mude. Essa troca é o modelo.
