---
title: A fila que ajuda e atrapalha
version: 1
---

Aqui está uma reclamação que você já ouviu, e possivelmente já fez.

*A chamada de vídeo estava boa. Aí alguém em casa começou a baixar alguma coisa, e a chamada
desmoronou — imagem travada, sílabas sumindo, pessoas falando por cima. O download seguiu
perfeitamente.*

Nada disso é largura de banda, e as ferramentas que a maioria das pessoas abre vão todas dizer que
está tudo bem. O que aconteceu foi uma **fila**.

## Por que uma fila tem que existir

Um roteador recebe pacotes por vários enlaces e os manda por outros, e esses enlaces têm capacidades
diferentes. O tempo todo chega tráfego de um enlace rápido destinado a um lento.

Nesse breve momento, chega mais do que consegue sair. O roteador tem duas escolhas: segurar o
excesso, ou jogá-lo fora.

Segurar é obviamente o certo. Rajadas são o que o tráfego real parece — um carregamento de página é
uma correria e depois nada — e um roteador sem buffer descartaria pacotes o tempo todo durante
atividade completamente normal, forçando retransmissões e desperdiçando a capacidade que ele tentava
proteger.

Então todo roteador tem um buffer, e deve ter. **O buffer é o que impede uma rajada de virar uma
perda.**

## O que uma fila cheia faz com o tempo

Agora observe o mesmo buffer quando o tráfego não é uma rajada, e sim um download contínuo.

Um download não para educadamente na capacidade da sua linha. O TCP vai aumentando a taxa até
alguma coisa mandar parar — e a única coisa que manda parar é um **pacote ser descartado**. Então
ele sobe, e sobe, e o excesso vai para o buffer.

O buffer enche. E fica cheio, porque o download continua empurrando.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Dois painéis. À esquerda uma fila vazia com um pacote de voz passando direto em cinco milissegundos. À direita a mesma fila cheia de pacotes de download, com um pacote de voz no fim tendo que esperar trezentos milissegundos pela vez dele.\"><rect x=\"8\" y=\"14\" width=\"340\" height=\"232\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"178\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">uma fila vazia</text><rect x=\"28\" y=\"70\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><rect x=\"284\" y=\"78\" width=\"36\" height=\"20\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".4\" stroke=\"var(--phosphor)\"></rect><text x=\"302\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">voz</text><text x=\"150\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada na frente dele</text><text x=\"178\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">5 ms de espera</text><text x=\"178\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a chamada soa natural</text><text x=\"178\" y=\"218\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e a linha está quase ociosa</text><rect x=\"372\" y=\"14\" width=\"340\" height=\"232\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"542\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">a mesma fila, cheia</text><rect x=\"392\" y=\"70\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><rect x=\"398\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"432\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"466\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"500\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"534\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"568\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"602\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"648\" y=\"78\" width=\"36\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".5\" stroke=\"var(--amber)\"></rect><text x=\"666\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">voz</text><text x=\"515\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pacotes do download, já enfileirados</text><text x=\"542\" y=\"156\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">300 ms de espera</text><text x=\"542\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a chamada desmorona</text><text x=\"542\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e o download vai a toda velocidade</text></svg>", "caption": "Nada se perdeu e nada ficou mais lento. O pacote de voz simplesmente tinha quatrocentas coisas na frente dele."}
```

O seu pacote de voz chega àquele roteador e entra no fim da fila. Ele não é descartado, não é
corrompido, não é mal roteado — ele está **a quatrocentos pacotes do começo**, e espera.

Um buffer segurando um segundo de tráfego acrescenta um segundo de latência a tudo que passar por
ele. E como nada se perde, toda contagem relata sucesso enquanto a chamada está inutilizável.

## O nome, e por que piorou

Isto é o **bufferbloat**, e a razão de ser tão difundido é quase engraçada.

Memória ficou barata. Fabricantes de equipamento colocaram buffers generosos, porque buffer maior
significa menos descartes, e menos descartes fica melhor em todo teste que conta descartes. Ninguém
estava medindo latência sob carga, então ninguém reparou que um buffer grande o bastante para nunca
descartar nada é um buffer grande o bastante para acrescentar meio segundo a tudo.

A medida que teria pego isso é o hábito da seção anterior: **observe a latência enquanto a linha
está cheia.** Uma conexão que pinga 15 ms ociosa e 400 ms durante um download está inchada, e isso é
um diagnóstico completo.

## Por que atinge umas coisas e outras não

A razão de o download passar ileso enquanto a chamada desmorona é que os dois querem coisas
diferentes.

O download quer vazão e não liga para atraso — 300 ms a mais num arquivo que leva um minuto é
invisível. A chamada quer atraso e mal usa capacidade — áudio são dezenas de kilobits por segundo,
um erro de arredondamento ao lado do download.

Então a fila pune exatamente o tráfego que não pode pagar por ela, e recompensa exatamente o tráfego
que a causou. Isso não é um desenho que alguém escolheu; é o que uma única fila por ordem de chegada
faz quando os seus ocupantes querem coisas opostas.

## O que de fato resolve

Vale saber, porque é o único problema desta aula que uma pessoa comum consegue resolver.

O conserto de verdade é **enfileirar com mais inteligência**: em vez de uma fila longa, manter filas
separadas e atender um pouco de cada, para que uma rajada de voz nunca fique atrás de um download.
Equipamentos modernos implementam isso — a configuração costuma se chamar gerenciamento inteligente
de fila — e ligá-la pode levar a latência sob carga de 400 ms de volta a 20.

Um truque relacionado é configurar a conexão um pouco **abaixo** da capacidade verdadeira, o que
impede que o buffer que está de fato causando o problema — normalmente um que você não controla, na
ponta do provedor — chegue a encher. Você abre mão de uns poucos por cento de vazão e recupera a
latência, o que para uma casa com gente em chamadas é uma troca que vale.

O que não resolve é comprar mais largura de banda. Uma linha mais larga enche mais devagar, então a
fila se forma mais tarde — e aí faz exatamente a mesma coisa.

## Onde isto te deixa

Atraso de enfileiramento é o componente da latência que se mexe, e um buffer que existe por boas
razões vira a maior fonte de atraso de uma conexão sempre que uma transferência contínua o enche.
Nada se perde, então tudo relata sucesso; o tráfego que sofre é o tráfego que precisava que o atraso
continuasse pequeno.

Isso é atraso causado por espera. A próxima seção é sobre o que acontece quando o atraso **varia**
de pacote para pacote, e sobre a outra coisa que acontece quando um buffer de fato acaba.
