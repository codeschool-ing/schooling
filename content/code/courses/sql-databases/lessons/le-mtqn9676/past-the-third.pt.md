---
title: Além da terceira, brevemente e com honestidade
version: 2
---

Existem formas normais além da terceira. Você vai ouvir os nomes, principalmente de gente tentando
estabelecer que os conhece, e você deve saber o que são para que a citação não funcione.

Esta seção é curta de propósito. **Encontrar uma tabela que precisa de FNBC é um evento notável,
não uma terça-feira**, e as duas acima dela são mais raras ainda.

## Forma normal de Boyce-Codd

A 3FN tem uma brecha. Ela proíbe uma coluna não-chave depender de outra coluna não-chave — e não
diz nada sobre uma coluna **de chave** depender de uma não-chave. A FNBC fecha isso:

> **Toda dependência na tabela tem que partir de uma chave candidata inteira.**

O formato que quebra a 3FN-mas-não-a-FNBC precisa de várias chaves candidatas sobrepostas, que é
por que é raro. O exemplo clássico:

| aluno | disciplina | tutor |
|---|---|---|

com duas regras: um aluno tem um tutor por disciplina, e **cada tutor leciona só uma disciplina**.

```localised
aluno, disciplina  →  tutor        a chave determina o tutor
tutor              →  disciplina   e o tutor determina a disciplina
```

Essa segunda dependência tem uma coluna não-chave à esquerda e uma coluna **de chave** à direita. A
3FN não tem o que dizer sobre isso, e a anomalia é real: registrar que o Dias tuteia Redes só é
possível inventando um aluno. O conserto é o de sempre — separar `tutor → disciplina` na própria
tabela.

**Quase toda tabela que está na 3FN já está na FNBC.** Você alcança a diferença só quando uma
tabela tem mais de uma chave candidata e elas se sobrepõem, que é coisa de passar anos sem ver.

## Quarta e quinta

A **4FN** trata de dois fatos multivalorados independentes espremidos numa tabela. Um curso tem
vários livros e vários horários, e os livros nada têm a ver com os horários — ponha os dois numa
tabela e você é obrigado a escrever uma linha por combinação, então três livros e quatro horários
são doze linhas que não dizem nada. O conserto são duas tabelas, e o sinal é exatamente essa
sensação de multiplicar coisas que não se relacionam.

A **5FN** trata de casos em que uma tabela só pode ser reconstruída juntando três ou mais peças em
vez de duas. É genuinamente obscura e você pode parar de ler sobre ela aqui.

Existe também uma **forma normal de domínio-chave**, que é o fim teórico da estrada e não é algo
contra o que alguém projete.

## Por que a 3FN é o padrão de trabalho

Não porque as formas mais altas estejam erradas. Por causa do que cada uma compra, contra o que
custa:

| | o que remove | com que frequência você encontra |
|---|---|---|
| 1FN → 3FN | as anomalias de atualização, inserção e exclusão | constantemente |
| FNBC | mais uma anomalia, em tabelas com chaves sobrepostas | raramente |
| 4FN, 5FN | redundância de fatos multivalorados independentes | raramente, e normalmente visível como absurdo óbvio |

**As três anomalias com que esta aula abriu já sumiram na 3FN.** Tudo além dela trata de formatos
incomuns, e cada divisão custa uma junção em toda leitura, para sempre.

Então a posição honesta, e a que a maioria de quem constrói bancos profissionalmente sustenta:

> Projete para a terceira forma normal. Reconheça as mais altas se uma tabela por acaso precisar —
> o sintoma é sempre o mesmo, um valor repetido que pode discordar de si mesmo. Não saia
> procurando.

**E desconfie da afirmação oposta.** "Isto está na quinta forma normal" quase nunca é uma afirmação
sobre o projeto de um sistema real; normalmente é uma afirmação sobre uma prova. A pergunta útil
sobre qualquer tabela não é qual forma ela satisfaz, e sim a que esta aula vem fazendo o tempo
todo: *o que pode dar errado aqui que não daria se fosse dividida?*
