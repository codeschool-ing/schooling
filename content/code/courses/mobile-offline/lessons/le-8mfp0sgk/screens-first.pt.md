---
title: Comece pelas telas, não pelo servidor
version: 1
---

**O esquema de um aparelho é desenhado a partir das perguntas que as telas fazem, e o esquema do
servidor é um ponto de partida ruim para ele.** O primeiro movimento comum é copiar as tabelas que
a API devolve, uma tabela local por endpoint, e depois descobrir que toda tela precisa de um join,
uma soma e uma ordenação antes de desenhar qualquer coisa. O servidor foi desenhado para todo
cliente e todo relatório. O celular tem poucas telas e uma pessoa, e pode se dar ao luxo de ter a
forma delas.

Então o primeiro passo é uma lista, escrita antes de qualquer `CREATE TABLE`: cada tela, a pergunta
que ela faz e com que frequência. Para o planner ela é curta.

| tela | a pergunta | com que frequência |
|---|---|---|
| lista de cursos | o nome de cada curso, quantas sessões ele tem, quantos minutos elas somam | a cada abertura |
| um curso | as sessões dele numa semana, em ordem de data | toda vez que é aberto |
| a semana | toda sessão numa semana, e os minutos planejados e feitos | a cada abertura, e depois de cada marcação |
| adicionar uma sessão | o curso existe; gravar uma linha | algumas vezes por dia |

Duas coisas saem da lista na hora.

**As leituras superam as escritas com folga.** A lista de cursos é lida toda vez que o app abre;
uma sessão é adicionada algumas vezes por dia. Um esquema que deixa a escrita barata e a leitura
cara tem a troca ao contrário para um celular, e a próxima seção move trabalho da leitura para a
escrita.

**As perguntas dão nome aos índices.** "As sessões de um curso numa semana" é o índice
`(course, date)` da aula 3, e "toda sessão numa semana" é o índice `(date)` dela. Um índice de que
nenhuma tela precisa é um custo sem leitor, e a lista é como você sabe quais são esses.

## O que a lista deixa de fora de propósito

O servidor sabe coisas que o planner nunca mostra: quem criou um curso, quando um administrador o
editou pela última vez, que outras pessoas o estudam. Nada disso é coluna aqui. **Uma coluna que o
aparelho não lê é uma coluna que ele baixa, guarda, migra e põe no backup à toa**, e uma coluna com
dado de outra pessoa é uma coluna que a aula 20 vai pedir que você justifique.

A mesma lista também diz o que precisa estar no aparelho para o app funcionar offline. Se uma tela
faz a pergunta, a resposta tem de estar no banco local antes de a rede ir embora, porque a regra
da aula 7 é que a tela lê o banco e nunca a rede.
