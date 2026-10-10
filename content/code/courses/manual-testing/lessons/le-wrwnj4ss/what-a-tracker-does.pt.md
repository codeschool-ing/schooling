---
title: O que toda ferramenta de acompanhamento faz
version: 1
---

Esta aula cita quatro produtos, e nenhum deles foi rodado para este curso. Isso é de propósito: os
produtos mudam de tela todo ano, e **o que uma ferramenta de acompanhamento faz não muda há vinte**.
Quem testa e entende as cinco coisas abaixo consegue sentar diante de qualquer um dos quatro, ou do
que o próximo empregador usar, e ser útil até a hora do almoço. Quem aprendeu os botões de um
produto tem de começar de novo.

O erro comum é achar que a ferramenta é o processo: que instalar o Jira dá ao time um ciclo de vida
de defeito. Dá um ciclo padrão, escrito por alguém que nunca viu o produto deles. O ciclo de vida da
aula 16 é uma decisão que o time toma; a ferramenta é onde ele é escrito e cobrado.

## As cinco coisas

**Um item.** Um registro por coisa a fazer ou decidir: um defeito, uma funcionalidade, uma tarefa.
Ele ganha um identificador no momento em que é criado, e esse identificador é como todo mundo se
refere a ele dali em diante, numa mensagem de commit, num chat, num caso de teste. O relato da aula
15 vira um item. O identificador também explica por que vale um defeito por relato: dois defeitos
num item dividem um identificador, um estado e um histórico, e não podem ser fechados em separado.

**Campos.** As partes estruturadas de um item: um resumo, uma descrição, uma prioridade, um estado,
a pessoa a quem foi atribuído, a versão em que foi achado, rótulos, anexos. Alguns campos vêm com o
produto; a maioria das ferramentas deixa um administrador criar outros. **Os campos que existem
decidem o que o time consegue buscar e contar**, então uma severidade que só existe no texto da
descrição não serve para listar todos os defeitos críticos abertos.

**Um fluxo de trabalho.** Os estados em que um item pode estar e os movimentos permitidos entre
eles, que é a figura da aula 16 virada configuração. Um fluxo rígido recusa um movimento que não
permite: um item não salta de *novo* para *fechado* sem passar pelos estados do meio. Um fluxo
frouxo deixa qualquer pessoa arrastar qualquer coisa para qualquer lugar, e confia nos hábitos do
time.

**Um quadro.** O fluxo desenhado como colunas, uma por estado, com cada item como um cartão na
coluna em que está. Um quadro responde num relance *o que está acontecendo agora*: três cartões em
*pronto para reteste* são três coisas esperando quem testa.

**Busca.** Um jeito de pedir todos os itens que atendem a certas condições, e de salvar a pergunta:
*todo defeito aberto do boxoffice com severidade crítica, do mais antigo para o mais novo*. As buscas
salvas são de onde vêm os números da aula 16. A idade dos defeitos críticos abertos é uma busca e uma
data; a taxa de reabertura são duas buscas e uma divisão.

## E o que vem junto

Toda ferramenta desta aula também guarda **um histórico** de cada item, quem mudou que campo e
quando, que é o que permite a um defeito reaberto carregar o seu passado. Ela **notifica** as pessoas
envolvidas quando algo muda. Ela **liga** itens entre si, para que um duplicado aponte para o
original e uma regressão aponte para a mudança que a causou. E ela **restringe quem pode ver um
item**, que é para onde vai o relato de segurança da aula 15.

Nada disso é específico de defeitos. A mesma ferramenta costuma guardar também as funcionalidades e
as tarefas do time, e um defeito é um **tipo de item** entre vários. Isso importa para quem testa de
um jeito: um defeito registrado como tarefa, ou uma tarefa registrada como defeito, some das buscas
feitas para o outro tipo, e as contagens da aula 16 ficam erradas sem ninguém perceber.
