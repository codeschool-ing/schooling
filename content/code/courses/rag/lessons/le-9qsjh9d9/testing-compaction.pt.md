---
title: Testando a compactação
version: 1
---

Tudo nesta aula se reduz a um teste, e vale escrevê-lo como teste e não como conselho:

- **Um conjunto de conversas**, reais, com os dados pessoais trocados, longas o bastante para serem
  compactadas.
- **Para cada uma, uma lista de essenciais**, os fatos de que uma pessoa que assume a conversa
  precisaria, escrita por alguém que a leu.
- **Para cada compactação**, depois de cada rodada, o número de essenciais ainda presentes. A nota de
  aprovação é todos; uma compactação que larga um essencial é um defeito com uma conversa que o
  reproduz.

A verificação desta aula é uma busca de trecho exato, que serve a um resumidor que copia frases e a
frases fixadas mantidas literalmente. O resumo de um modelo de linguagem parafraseia, então "write to me
by email only" pode voltar como "prefere contato por e-mail", e a verificação precisa ser mais solta onde
o fato permite e estrita onde não permite. **Identificadores continuam estritos**: um número de pedido ou
aparece exatamente ou se perdeu. Preferências e decisões podem ser conferidas com uma pequena lista de
redações aceitáveis, ou com um segundo modelo a quem se faz uma pergunta de sim ou não por essencial, com
a cautela da aula 8 sobre usar um modelo para julgar outro: meça o juiz em alguns casos que uma pessoa
marcou antes de confiar na contagem dele.

Rode o teste quando mudar qualquer coisa que toque a compactação: o modelo ou o prompt do resumidor, o
limite de palavras, a regra de fixação, o limite que a dispara. Cada um é um padrão que alguém um dia vai
mudar por um bom motivo, e o teste é como essa pessoa descobre quanto custou.
