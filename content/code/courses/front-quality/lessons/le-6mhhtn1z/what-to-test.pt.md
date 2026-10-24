---
title: Teste o que o usuário vê, não como o código faz
version: 1
---

**Um bom teste falha quando o planner deixa de fazer o seu trabalho e passa enquanto ele o faz, seja
como for o código por dentro.** Essa frase decide mais sobre uma suíte de testes do que a escolha da
ferramenta, e é fácil quebrá-la sem perceber.

Pense em marcar uma sessão como feita. Aqui estão dois testes que alguém poderia escrever, em
palavras:

- *Depois de clicar em Done na sessão de quinta, a sessão diz "done" e não tem botão.*
- *Depois de clicar em Done, o `markDone` foi chamado uma vez com o id 4, e a classe do item da lista é
  `session done`.*

Os dois passam hoje. Agora renomeie a classe para `is-done` no `view.ts` e no `style.css` juntos, o que
não muda nada que alguém veja: o segundo teste falha. Depois quebre o tratador do clique para que ele
marque a sessão errada: o primeiro teste falha e o segundo pode até passar, se conferir a chamada e
não o resultado. **O segundo teste é uma descrição do código atual**, e falha numa refatoração e passa
num defeito, que é o contrário do que um teste existe para fazer.

## Três hábitos que vêm disso

**Confira a saída, não as chamadas.** No `planner.ts` a saída é um valor devolvido, então um teste
compara o que voltou. No `view.ts` a saída é o que está na página: texto, papéis, o nome de um botão.
A aula 3 é uma biblioteca construída exatamente sobre essa ideia, e é por isso que ela acha as coisas
pelo nome que uma pessoa leria, e não por uma classe CSS.

**Escolha dados que podem falhar.** Um total testado numa semana com uma sessão não distingue somar de
copiar. Os dados do planner põem sessões na segunda e no domingo da semana de 19 de outubro e uma de
cada lado dela, então um total dessa semana sai errado se qualquer ponta da semana estiver um dia
deslocada. O primeiro teste do `weekTotal` na aula 2 é escrito contra esses dados, e ele não fica
verde.

**Um motivo para falhar por teste.** Um teste chamado *o total da semana* que também confere a lista
de cursos, o título e os nomes dos botões falha por qualquer um deles, e o nome dele não diz nada.
Vários testes curtos com nomes que são frases fazem o relatório de falhas ser lido como uma lista do
que está quebrado.

## E o que não testar

Código que você não escreveu é de outra pessoa testar: que o `createElement` cria um elemento, que o
Vite serve `public/`, que o `fetch` busca. Um teste disso passa para sempre e deixa a suíte mais lenta.
Teste onde estão as suas decisões: as regras do `planner.ts`, as ligações do `view.ts`, e o único
caminho pelo navegador que prova que as peças se encontram.
