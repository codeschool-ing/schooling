---
title: Atalhos, que são bilhetes sobre onde algo estava
version: 1
---

Um atalho é um arquivo minúsculo cujo conteúdo inteiro é **um caminho para outro arquivo**. Um
duplo clique lê o caminho e abre o que estiver lá.

Essa frase explica toda coisa estranha que atalhos fazem. É um bilhete dizendo *a coisa está ali
adiante*, e um bilhete não sabe quando a coisa muda de lugar.

## Os três tipos, e eles se comportam diferente

| | o que é | quando o alvo muda de lugar |
|---|---|---|
| **atalho do Windows** (`.lnk`) | um arquivo com um caminho, mais ícone e argumentos | normalmente quebra. O Windows às vezes adivinha |
| **link simbólico** | uma entrada do sistema de arquivos com um caminho | quebra, em silêncio |
| **link físico** | um segundo nome para o mesmo conteúdo | continua funcionando. Ele nunca apontou |

O terceiro é o estranho e interessante. Um **link físico** não é um ponteiro para um arquivo — ele
*é* um arquivo, um segundo nome numa segunda pasta para exatamente os mesmos bytes. Apague um nome
e o outro ainda abre. O conteúdo só desaparece quando o último nome some.

Um **alias** no macOS é o meio-termo: ele guarda um caminho *e* um identificador interno, então
sobrevive ao alvo ser movido ou renomeado, o que nenhum dos outros dois consegue.

## As falhas, e como cada uma se parece

- **Copiar um atalho para um pendrive copia o bilhete, não o arquivo.** O pendrive agora tem um
  arquivo de 4 kilobytes apontando para um caminho que não existe em máquina nenhuma. Essa é a
  versão mais comum de *eu trouxe a apresentação e ela não abre*.
- **Um backup de uma pasta cheia de atalhos copia nada.** A mesma razão, com mais em jogo.
- **Mover o alvo quebra o atalho**, e o erro nomeia o caminho antigo, o que é genuinamente útil —
  ele te diz onde o arquivo ficava.
- **Um atalho pode ser renomeado à vontade.** O nome do atalho e o nome do arquivo não têm nada a
  ver um com o outro, o que é ocasionalmente conveniente e confiavelmente confuso.

## Onde eles são genuinamente a resposta certa

- **O mesmo arquivo preciso em duas estruturas** — um documento que pertence tanto a
  `2026/faturas` quanto a `clientes/tavares`. Um arquivo, um lugar, duas entradas.
- **Um caminho longo usado todo dia.** Um atalho na área de trabalho para uma pasta seis níveis
  abaixo.
- **Uma pasta grande que mora no segundo disco** enquanto o programa a espera na pasta pessoal. Um
  link simbólico faz o programa vê-la onde ele quer.

A regra que cobre as falhas: **um atalho serve para alcançar algo, nunca para guardar.** Se o que
você está fazendo é mover ou guardar o arquivo, o atalho é o objeto errado.

## E o que vale reconhecer

Um atalho pode apontar para um programa e carregar **argumentos**, o que significa que um arquivo
`.lnk` pode ter cara inofensiva e executar qualquer coisa. O ícone dele é o que quem o fez
escolheu.

É o mesmo formato do truque da extensão: a coisa que você vê não é a coisa que executa. Os dois
são a razão de um anexo que chega sem ser esperado ser olhado antes de ser aberto.
