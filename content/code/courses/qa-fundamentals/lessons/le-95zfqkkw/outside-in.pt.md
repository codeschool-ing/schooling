---
title: Testando de fora
version: 1
---

**O teste caixa preta examina um sistema só pelo que ele faz: as entradas que aceita e as saídas que
devolve.** Quem testa não lê o código, e não precisa. O que lê no lugar é a especificação, o requisito, a
expectativa de quem usa, qualquer coisa que diga o que o sistema **deveria** fazer. O teste é a comparação
entre isso e o que ele **faz**.

O nome vem da engenharia, em que uma caixa preta é um aparelho que só se estuda mandando sinais e
observando o que sai. O oposto, uma caixa branca, é um que dá para abrir; a aula 7 a abre, e a aula 8 é
sobre o meio-termo.

## O que dá para ver de fora

De fora, o `tickets.py` é um comando que recebe quatro palavras e imprime um preço. É tudo o que quem testa
como caixa preta sabe, e é muito:

- **as entradas**: uma idade, um sim ou não para estudante, um dia, um horário;
- **as saídas**: um preço, no formato `R$ 36,00`, ou outra coisa quando falha;
- **a regra** que ele deveria seguir: as quatro frases da Joana, da aula 1.

Tudo nesta aula é feito com essas três coisas e nada mais. A aula 4 já trabalhou assim até o último
passo, quando a evidência disse à Lia que linha olhar.

## Por que testar sem o código

Parece uma desvantagem. É o contrário, por três motivos.

**Testa o que o cliente vive.** Clientes nunca veem o código. Um defeito importa pelo que o sistema faz a
alguém, e o teste caixa preta olha exatamente para isso.

**É independente da implementação.** Quem lê `if age > 60` antes de testar tende a testar essa linha, e
confirma o que ela faz. Quem lê só *maiores de 60* pergunta o que a regra quer dizer, e testa isso. O
defeito dos sessenta anos foi achado pela regra, não pelo código.

**Sobrevive a uma reescrita.** Se o Rafael reescrever o `tickets.py` do zero no ano que vem, todo teste
caixa preta dele continua valendo sem mudança, porque a regra não mudou. Um teste escrito contra a
estrutura do código pode precisar ser reescrito junto.

## O que não dá para ver de fora

O teste caixa preta tem um limite estrutural, e vale nomeá-lo exatamente. **Você só testa os
comportamentos em que pensou.** A regra diz o que acontece com estudantes, pessoas idosas, crianças,
noites, matinês e quartas. Não diz nada sobre um estudante numa quarta, um horário escrito `9:30` ou uma
idade digitada como palavra. Se o código faz algo especial para uma entrada específica que nenhuma regra
menciona, nenhum volume de teste a partir da regra vai achá-lo, porque nada aponta quem testa para lá.

Esse limite é o motivo de a caixa preta não ser a única abordagem, e de as duas próximas aulas existirem.
Dentro do limite, é a abordagem que acha os defeitos que os clientes achariam, e a maior parte dos
defeitos deste curso até aqui.

## As técnicas, só pelo nome

Há jeitos sistemáticos de escolher entradas de caixa preta, e você vai ouvir os nomes em todo emprego de
teste: **partição de equivalência**, que agrupa entradas que deveriam se comportar igual para você testar
uma de cada grupo; **análise de valor-limite**, que testa nas bordas desses grupos, onde morava a pessoa de
sessenta anos; **tabelas de decisão**, para regras que combinam condições; e **teste de transição de
estados**, para sistemas cuja resposta depende do que aconteceu antes.

Elas são o assunto das aulas 4 e 5 de `manual-testing`, que as ensinam direito. Esta aula faz algo mais cedo
e mais rústico de propósito: lê a regra da Joana uma frase por vez, transforma cada frase em casos, e
depois pergunta o que a regra deixa de fora. Esses hábitos são o que as técnicas tornam sistemático.
