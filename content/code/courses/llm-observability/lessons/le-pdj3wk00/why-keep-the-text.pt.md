---
title: Por que vale guardar o texto
version: 2
---

A aula 10 do `observability` termina com uma regra para serviços comuns: o corpo de um pedido não vai
para um log, porque cedo ou tarde ele carrega tudo o que nunca deveria estar lá. Uma chamada a modelo
é o caso em que essa regra é mais difícil de seguir, porque **o corpo é justamente o que se observa**.

Veja o que a aula 1 conseguiu e não conseguiu explicar. A resposta sobre a postagem da devolução
estava errada, e o trace disse onde: o único trecho mantido era o certo, e o modelo o contradisse.
Isso funcionou porque a pergunta e a resposta estavam no span raiz. Tire as duas, e o trace diz que um
pedido da funcionalidade `help` manteve um trecho e recebeu uma resposta de 14 tokens, e ninguém sabe
dizer se é uma boa resposta a uma boa pergunta ou uma resposta errada à pergunta certa.

O texto é necessário para três trabalhos, e cada um precisa de uma quantidade diferente dele:

| trabalho | precisa de | por quanto tempo |
|---|---|---|
| **depurar uma resposta ruim** | a pergunta, a resposta, e quais fontes foram usadas | até a reclamação ser encerrada: dias |
| **avaliar qualidade** (aulas 8 a 13) | perguntas e respostas, em quantidade, e as fontes contra as quais um juiz confere | até a avaliação rodar: dias, ou uma amostra guardada por mais tempo |
| **contar e alertar** (aulas 3 a 5, 16) | nenhum texto: tokens, tempos, resultados, notas | enquanto a tendência importar: meses |

A tabela é o argumento desta aula. **O texto e os números têm vidas diferentes.** Um sistema que
guarda os dois no mesmo lugar pelo mesmo tempo ou jogou fora a sua depuração ou guardou um ano de
conversas de que ninguém precisou por mais de uma semana.

## O que torna uma chamada a modelo diferente de um pedido comum

Três coisas, e cada uma torna o texto mais perigoso de guardar que o corpo de um pedido web.

**As pessoas escrevem para ela como escreveriam para uma pessoa.** Um formulário pede um número de
pedido num campo. Uma caixa de chat recebe um parágrafo: um nome, um endereço, como o pedido deu
errado, e às vezes por que o livro era um presente e para quem. A próxima seção conta o que os
clientes da Marginalia digitaram numa semana.

**O prompt carrega mais do que o cliente escreveu.** Ele carrega as fontes recuperadas, que num
sistema como o da aula 14 do `rag` podem incluir documentos que só parte da equipe pode ler. Um trace
que guarda o prompt inteiro guarda uma cópia desses documentos fora do banco que controla quem pode
lê-los.

**A resposta pode repetir qualquer parte disso.** Um modelo a quem se diz o nome do cliente vai
usá-lo, e uma remoção que só olha a entrada deixa a saída carregando exatamente o que foi tirado dela.

Nada disso diz que o texto não pode ser guardado. Diz que **o que se guarda é uma decisão, tomada
campo a campo, com um propósito e uma data de fim**, que é o que a LGPD pede de qualquer tratamento de
dados pessoais, e o resto desta aula constrói as peças: saber o que chega, tirar antes de escrever,
uma segunda rede atrás da primeira, nomes no lugar de identidades, e um prazo de validade.
