---
title: Uma linguagem, direito
version: 1
---

**Você escolheu JavaScript para o servidor, e o conselho que vem junto com a escolha é ficar nela
até conhecê-la bem.** Parece uma regra para iniciantes. É o contrário: é como pessoas que já
programam decidem o que aprender a seguir, e vale conhecer os motivos, porque você vai ter vontade
de quebrá-la.

## A imagem errada

A imagem comum é a de que uma linguagem de programação é principalmente a sua sintaxe. Aprenda as
palavras-chave de uma segunda, diz o raciocínio, e você sabe duas linguagens. Então, algumas semanas
depois de começar no Node, alguém lê que Go é mais rápido ou que Python tem as melhores vagas,
começa um tutorial de Go, e três meses depois terminou quatro tutoriais e não construiu nada que
rode fora do próprio notebook.

**A sintaxe é a menor parte de uma linguagem.** O que um servidor de verdade exige de quem o
escreve é tudo o que está em volta da sintaxe:

| o que você precisa saber | como isso aparece neste curso |
|---|---|
| o runtime, e como ele roda o seu código | aula 2: o event loop, o pool de threads, por que um laço lento para todas as requisições |
| como o código é dividido e encontrado | aula 3: dois sistemas de módulos e as regras que o Node usa para escolher um |
| o ecossistema e as ferramentas | aula 4: npm, o lockfile, o que uma dependência traz junto |
| a biblioteca padrão | aulas 5 e 8: o servidor HTTP e o sistema de arquivos sem instalar nada |
| as bibliotecas que todo mundo usa | aulas 6 e 7: Express |
| como o programa encontra a máquina | aulas 9 e 10: configuração, processos, workers e modo cluster |

Nada da coluna da direita é sintaxe, e nada disso vai junto para o Go quando você muda. O Go tem
o próprio runtime, o próprio jeito de achar um pacote e a própria biblioteca de servidor, e cada
um deles leva tanto tempo para aprender quanto levou o do Node.

## O que a profundidade compra

**Um problema em produção quase nunca é um problema de sintaxe.** É uma requisição que trava, um
processo que fica sem memória às três da manhã, uma dependência que mudou por baixo de você, uma
configuração que está certa no seu notebook e errada no servidor. Cada um desses é encontrado por
alguém que sabe o que o runtime faz quando nada está escrito, e esse conhecimento vem do tempo
passado em uma linguagem, não de um passeio por várias.

O segundo motivo é que **as ideias só se transferem depois que você as tem**. HTTP, códigos de
status, middleware, configuração vinda do ambiente, streams, um processo que encerra direito: a aula
11 mostra que Python, Go, Java, PHP e C# têm cada uma dessas coisas. Quem construiu cada uma uma
vez, direito, em Node, lê a mesma ideia em outra linguagem com nomes novos. Quem encontrou cada uma
por uma tarde em quatro linguagens precisa aprender tudo de novo na quinta.

E o terceiro é aritmética simples. Esta trilha gasta 140 horas com JavaScript e Node juntos, e os
cursos depois dela são escritos para quem consegue construir um servidor em uma linguagem. Gastar
essas horas em duas linguagens é chegar ao `sql-databases` e ao `apis` com metade de cada uma.

## Quando uma segunda linguagem faz sentido

Nada disso diz para nunca aprender outra. Diz **ainda não**. Uma segunda linguagem vale a pena
quando a primeira deixou de ser aquilo com que você está lutando: quando você consegue construir,
depurar e publicar um serviço pequeno nela sem procurar como se lê o corpo de uma requisição. A aula
11 trata do que muda entre linguagens e do que não muda, e ela é a última de propósito. Até lá a
comparação faz sentido, porque você tem um dos lados dela.
