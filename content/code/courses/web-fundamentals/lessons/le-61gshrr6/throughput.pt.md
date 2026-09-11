---
title: O que você de fato consegue
version: 1
---

**Vazão é com o que você termina.** Não o número do plano, nem a capacidade teórica de nenhum
enlace — a taxa com que os dados de verdade de fato andaram, medida depois do fato.

É sempre menor que a largura de banda, e a pergunta interessante é para onde foi a diferença.

## Quatro lugares para onde a diferença vai

**O enlace mais estreito.** Já visto, e ainda a primeira coisa a conferir. Você fica com a menor
capacidade do caminho, e o seu plano é só um dos candidatos.

**Tudo que não são os seus dados.** Cada camada acrescenta um cabeçalho, e cada cabeçalho é
capacidade gasta em rótulos em vez de conteúdo. Um cabeçalho de quadro, um de pacote, um de TCP,
depois TLS, depois os cabeçalhos do próprio HTTP — em transferências pequenas isso é uma fração
relevante, e numa página de requisições minúsculas é uma fração grande.

**A outra ponta.** Um servidor atendendo milhares de pessoas divide a capacidade de saída entre
elas. Um disco lento, um banco de dados ocupado, uma máquina sobrecarregada — tudo isso limita a
sua vazão a algo bem abaixo do que qualquer das duas conexões poderia carregar. **A sua largura de
banda é um teto do que você pode receber, não uma promessa sobre o que alguém vai mandar.**

**E a própria conversa.** Esta é a que ninguém espera, e precisa de um título próprio.

## Um cano largo e longo não se enche pedindo com educação

Lembre da aula dois como o TCP funciona: ele manda alguns dados, espera uma confirmação, e manda
mais. Ele não vai simplesmente despejar tudo de uma vez, porque não faz ideia do que a rede ou o
destinatário conseguem absorver.

Então, a cada momento, há um limite de quanto dado está **em voo** — enviado e ainda não
confirmado. Esse limite se chama janela.

Agora considere o que isso significa num caminho longo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um cano longo entre duas máquinas com um pequeno bloco de dados dentro e muito espaço vazio. Uma nota diz que o remetente está esperando uma confirmação antes de mandar mais, então a linha fica ociosa a maior parte do tempo.\"><rect x=\"12\" y=\"70\" width=\"92\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"58\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">remetente</text><rect x=\"616\" y=\"70\" width=\"92\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"662\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">destinatário</text><rect x=\"116\" y=\"74\" width=\"488\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><rect x=\"126\" y=\"84\" width=\"74\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".34\" stroke=\"var(--phosphor)\"></rect><text x=\"163\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">em voo</text><text x=\"406\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vazio — capacidade que existe e não está sendo usada</text><text x=\"360\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 Gbps de capacidade, ida e volta de 200 ms</text><text x=\"360\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o remetente parou e está esperando uma confirmação</text><text x=\"360\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ele vai esperar 200 ms antes de poder mandar de novo</text><text x=\"360\" y=\"220\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">uma janela de 64 kB em 200 ms dá cerca de 2,6 Mbps, faça o enlace o que fizer</text></svg>", "caption": "Para encher um cano longo é preciso ter dados em voo suficientes para cobrir a ida e volta inteira. Capacidade sozinha não resolve."}
```

Para manter um enlace ocupado, a quantidade em voo tem que cobrir a ida e volta inteira — porque é
esse o tempo até a permissão de mandar mais voltar. A quantidade de que você precisa é
**capacidade × ida e volta**, e tem nome: o *produto banda-atraso*.

Para 1 Gbps e 200 ms, são cerca de 25 megabytes em voo. Com uma janela de 64 kilobytes, você
tiraria uns 2,6 Mbps de um enlace de gigabit — não porque algo está quebrado, mas porque o
remetente passa quase todo o tempo esperando.

Sistemas modernos crescem a janela sozinhos e chegam a números bem melhores, e ainda assim é por
isso que uma única transferência atravessando o mundo raramente alcança o que a mesma
transferência alcança na porta ao lado. **A distância custa vazão, não só latência.** É a segunda
razão de a resposta da aula 9 ser aproximar o conteúdo em vez de comprar uma conexão maior.

## Por que um download é mais lento que oito

O que leva a algo que você talvez já tenha notado e suposto ser truque.

Programas gerenciadores de download oferecem há décadas partir um arquivo em várias conexões
simultâneas, e isso ajuda de verdade. Não porque cada conexão fique mais rápida, mas porque **cada
uma tem uma janela própria**, e oito janelas põem oito vezes mais dado em voo.

O mesmo raciocínio é por que um navegador abre várias conexões por site, e por que um teste de
velocidade abre muitas de uma vez. Um teste de velocidade relata o que a sua linha consegue com
todos os truques aplicados — o que é uma medida justa da linha, e uma previsão ruim de qualquer
transferência isolada que você vá fazer.

## Para onde vai uma hora de verdade

Ajuda pôr números nisso uma vez. Você está baixando um arquivo de 1 GB numa conexão de 300 Mbps.

A conta que todo mundo faz primeiro: 1 GB são 8.000 megabits, a 300 megabits por segundo, então uns
**27 segundos**. Ele chega em 48. Aqui estão os 21 que faltam, e nada disso é alguém trapaceando.

| para onde foi | mais ou menos |
|---|---|
| a sua linha é 300 Mbps *até*, e entrega uns 280 na prática | 2 s |
| cabeçalhos de cada camada — cerca de 5% do que cruza o fio são rótulos | 1 s |
| o TCP começando cauteloso e levando alguns segundos para chegar à taxa cheia | 3 s |
| o servidor dividindo a capacidade entre todo mundo que está baixando agora | 9 s |
| um segmento compartilhado à noite, e umas duas retransmissões | 6 s |

A maior linha isolada é **a outra ponta**, e é justamente aquela sobre a qual o seu plano não tem
influência nenhuma. Este é o caso comum, não um dia ruim: uma transferência que chega a 70% do
número anunciado é uma transferência saudável.

O que é também a resposta para *por que este download é mais lento que o teste de velocidade*. O
teste mediu a sua linha até um servidor próximo com todos os truques aplicados. Isto mediu uma
conversa real com uma máquina real que tem outras pessoas para atender.

## Medir com honestidade

Três hábitos, e é o que separa uma medição útil de um número.

**Meça a coisa com que você se importa.** Um teste de velocidade mede a sua linha até um servidor
próximo escolhido pelo seu provedor. Se a reclamação é sobre um site específico, o teste pode estar
perfeito e não dizer nada.

**Meça mais de uma vez, em mais de um horário.** Uma conexão compartilhada às nove da noite é uma
conexão diferente da mesma às seis da manhã.

**E observe a latência enquanto mede a vazão.** Esse é o hábito que quase ninguém tem, e é o
assunto da próxima seção: uma conexão pode entregar a vazão anunciada por inteiro e ficar
inutilizável para todo o resto no mesmo instante.

## Onde isto te deixa

Vazão é a taxa com que os dados de verdade andaram. É limitada pelo enlace mais estreito, reduzida
pelos cabeçalhos de cada camada, travada no que a outra ponta estiver disposta a mandar e — em
caminhos longos — limitada por quanto uma única conversa consegue manter em voo enquanto espera
permissão.

Esse último significa que a distância te custa capacidade, e não só tempo. E o hábito de medição do
fim desta seção é o que abre a próxima: **olhe o que acontece com a latência enquanto a linha está
cheia.**
