---
title: Duas maneiras de usar os mesmos pacotes
version: 1
---

Tudo até aqui foi sobre a promessa da rede, que é *melhor esforço*: vou tentar, posso perder, posso
entregar atrasado, posso entregar depois do que vinha atrás, e não vou te avisar.

Uma transferência de arquivo não consegue viver com isso. Uma chamada de voz não consegue viver sem
isso.

Então existem duas respostas, elas rodam exatamente sobre os mesmos pacotes, e escolher entre as
duas é uma das poucas decisões genuinamente estruturais em construir qualquer coisa em rede.

## O que o TCP acrescenta

O **TCP** pega o melhor esforço da rede e constrói em cima dele um **fluxo confiável e ordenado**.
Cada mecanismo que ele usa é um conserto para um item específico daquela lista.

Pacotes podem chegar fora de ordem, então o TCP os **numera** — não os pacotes, na verdade, mas os
bytes: cada byte do fluxo tem uma posição, e quem recebe os recoloca em ordem por número antes de
entregar qualquer coisa ao programa.

Pacotes podem se perder, então quem recebe **confirma** o que recebeu. O remetente guarda uma cópia
de tudo que mandou até a confirmação voltar, e se ela não chegar a tempo, ele **manda aqueles dados
de novo**.

Quem recebe pode ser afogado, então anuncia quanto espaço ainda tem. O remetente não pode mandar
mais do que isso, e é por isso que uma máquina rápida falando com uma lenta não simplesmente a
soterra.

E a própria rede pode estar congestionada, então o TCP observa as perdas — a perda é o único sinal
que a rede dá — e **desacelera** quando as vê. Essa é a parte que ninguém pediu e de que todo mundo
se beneficia: é a razão de cem downloads simultâneos dividirem um enlace em vez de destruí-lo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 258\" role=\"img\" aria-label=\"Duas linhas do tempo dos mesmos cinco pacotes, com o terceiro perdido. Na linha do TCP, quem recebe retém os pacotes quatro e cinco, o remetente reenvia o terceiro, e o programa recebe os cinco em ordem. Na linha do UDP, os pacotes quatro e cinco vão direto para o programa e o terceiro simplesmente nunca é mencionado.\"><rect x=\"8\" y=\"14\" width=\"344\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"180\" y=\"36\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">TCP</text><rect x=\"26\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"48\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"78\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"100\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"130\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-dasharray=\"3 3\"></rect><text x=\"152\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">3</text><rect x=\"182\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"204\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"234\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"256\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><text x=\"152\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o 3 se perde</text><text x=\"180\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 e 5 chegaram e ficam RETIDOS</text><text x=\"180\" y=\"146\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nenhuma confirmação do 3 — reenvie</text><rect x=\"96\" y=\"162\" width=\"168\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"180\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3 de novo, e ele chega</text><text x=\"180\" y=\"210\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">o programa recebe 1 2 3 4 5</text><text x=\"180\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">completo, em ordem, e atrasado</text><rect x=\"368\" y=\"14\" width=\"344\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"540\" y=\"36\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">UDP</text><rect x=\"386\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect><text x=\"408\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"438\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect><text x=\"460\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"490\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 3\"></rect><text x=\"512\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"542\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect><text x=\"564\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"594\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect><text x=\"616\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><text x=\"512\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o 3 se perde</text><text x=\"540\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 e 5 vão DIRETO para o programa</text><text x=\"540\" y=\"146\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nada espera, nada é reenviado</text><text x=\"540\" y=\"176\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ninguém menciona o 3 nunca mais</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">o programa recebe 1 2 4 5</text><text x=\"540\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">incompleto, em ordem, e na hora</text></svg>", "caption": "A mesma perda, tratada de duas maneiras. Repare que nenhuma das colunas é o erro — elas são respostas a perguntas diferentes.", "same": ["TCP", "UDP"]}
```

## O que o UDP acrescenta

Quase nada, e essa é a funcionalidade.

O **UDP** coloca um número de porta num pacote e o envia. Não há numeração, confirmação,
retransmissão, reordenação, controle de fluxo nem desaceleração. Se um pacote se perde, ele se
perdeu, e o programa não é avisado.

Ler isso como deficiência é o erro natural. É uma **escolha**, e o que ela compra é tudo do
parágrafo anterior *não acontecendo*: nenhuma espera para combinar uma conexão, nenhum dado retido,
nenhum atraso enquanto algo é buscado de novo.

## A troca, dita direito

A maneira honesta de enunciar é que o TCP converte perda em **atraso**, e o UDP converte perda em
**ausência**.

É isso inteiro. Nenhum é melhor, e qual é o certo depende de uma única pergunta: **os seus dados
ainda servem se chegarem atrasados?**

Para um arquivo, sim — obviamente. Um arquivo com um kilobyte faltando não é um arquivo um pouco
pior, é um arquivo corrompido, e um arquivo que demora meio segundo a mais está ótimo. Converta
perda em atraso.

Para uma chamada de voz, não. Os vinte milissegundos da fala de alguém que sumiram eram devidos ao
ouvido do interlocutor vinte milissegundos atrás. Entregá-los agora é pior do que inútil — teriam
que ser inseridos em algum lugar, e não há lugar. Bem melhor seguir em frente e deixar o cérebro de
quem escuta remendar uma lacuna que ele mal percebe. Converta perda em ausência.

## Bloqueio de cabeça de fila

Há um custo específico da ordenação do TCP que vale nomear, porque tem nome e você vai reencontrá-lo
na aula 6.

O TCP entrega **em ordem**. Se o pacote 3 se perde, os pacotes 4 e 5 podem ter chegado perfeitamente
bem — mas não são dados ao programa. Não podem ser: eles vêm depois do 3 no fluxo, e entregá-los
colocaria os dados fora de ordem, que é a única coisa que o TCP existe para impedir.

Então 4 e 5 ficam na memória, completos e inúteis, enquanto o 3 é buscado de novo.

Isso é o **bloqueio de cabeça de fila**: uma peça faltando segurando tudo que vem atrás. Num enlace
bom ele é invisível. Num ruim, é a diferença entre uma página que carrega devagar e uma página que
parece congelar e depois chegar toda de uma vez.

## Onde cada um está de fato

| o quê | qual | por quê |
|---|---|---|
| páginas web, APIs | TCP | uma página sem um fragmento está quebrada, não mais lenta |
| e-mail, transferência de arquivo | TCP | todo byte importa e nada é urgente |
| consultas de DNS | UDP | uma pergunta pequena, uma resposta pequena — perguntar de novo sai mais barato que combinar antes |
| chamadas de voz e vídeo | UDP | áudio atrasado é áudio inútil |
| estado de jogo ao vivo | UDP | a próxima posição substitui a que se perdeu |
| streaming de vídeo | TCP, quase sempre | não é ao vivo, então há um buffer, e um buffer converte atraso em nada |
| HTTP/3 | UDP, com maquinário próprio em cima | veja abaixo |

Essa última linha é a que impede a tabela de ser uma regra arrumadinha.

## Quando a resposta não é nenhum dos dois

O HTTP/3 — sobre o qual boa parte da web hoje roda — é construído sobre **UDP**, e não é porque
alguém deixou de querer confiabilidade.

É por causa do bloqueio de cabeça de fila. Um navegador busca muitas coisas ao mesmo tempo, e numa
única conexão TCP um pacote perdido trava *todas* elas, inclusive as que nada tinham a ver com ele.
Então o HTTP/3 pega o UDP, que não impõe ordenação nenhuma, e reconstrói numeração, confirmação e
retransmissão **por fluxo** em vez de para a conexão inteira. Um download travado não segura mais os
outros nove.

O motivo de valer conhecer isso neste nível é o formato da jogada, não o detalhe. *Confiável* e *não
confiável* não são duas caixas para separar coisas. O UDP é um piso — um número de porta e nada mais
— e quem precisar de algo diferente do que o TCP oferece pode construir ali. A aula 6 volta a isso
quando compara as versões do HTTP.

## Onde isto te deixa

Duas maneiras de usar os mesmos pacotes. O TCP numera, confirma, reenvia, reordena e desacelera
quando a rede está sofrendo — transformando perda em atraso, ao custo de uma viagem de ida e volta
antes de qualquer coisa começar e de um pacote perdido segurar o que vem atrás. O UDP acrescenta uma
porta e nada mais, transformando perda em ausência.

A viagem de ida e volta é a parte que vale ver em vez de ler a respeito, e é o que a próxima seção
faz: a mesma conexão, aberta num relógio, ao lado dos mesmos dados enviados sem combinar nada.
