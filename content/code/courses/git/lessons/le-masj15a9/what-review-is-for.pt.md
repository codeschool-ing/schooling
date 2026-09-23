---
title: Para que serve uma revisão
version: 1
---

A aula 8 mostrou a mecânica: um pull request, um comentário numa linha, uma aprovação. Esta aula é sobre a
parte que botão nenhum faz, que é **decidir o que dizer**. A revisão é onde a maioria das pessoas júnior dá
retorno pela primeira vez a alguém mais experiente, e é desconfortável para todo mundo até o propósito
ficar claro.

## Três coisas que ela compra para a equipe

- **Uma segunda chance de pegar um erro.** Quem escreveu leu a mudança muitas vezes e vê o que quis
  escrever. Quem revisa lê o que está lá.
- **Uma segunda pessoa que conhece o código.** Quando quem escreveu está de férias e o formulário de
  pedidos quebra, outra pessoa já o leu uma vez. Numa equipe de duas pessoas isso vale mais que qualquer
  bug encontrado.
- **Uma ideia comum de como as coisas são feitas**, que se espalha sem ninguém escrever um guia de estilo.
  Você aprende uma base de código mais rápido lendo as mudanças dos outros, e por isso as equipes pedem
  para quem chegou agora revisar cedo.

## O que ela não é

Não é uma prova em que quem revisa é o examinador, e não é o lugar de ganhar uma discussão sobre gosto.
**A pergunta que uma revisão responde é "isto está bom o bastante para entrar?"**, não "é exatamente como
eu teria feito?". Uma mudança pode entrar mesmo que você a tivesse escrito diferente. A maioria das boas
mudanças é assim.

Ela também não é a única rede de segurança. Os checks automáticos pegam o que uma máquina consegue pegar,
como formatação, um teste falhando ou um link quebrado, e pegam toda vez. Quem revisa e gasta a atenção no
que um formatador corrigiria tem menos dela para o que só uma pessoa vê.

## Uma ordem para ler

Leia das perguntas que mais importam para as que menos importam, e pare de comentar quando as importantes
tiverem resposta:

1. **Faz o que o ticket pediu?** Leia o ticket e a descrição primeiro.
2. **Funciona?** Resultados errados, casos que faltam, o que acontece com uma entrada vazia ou inesperada.
3. **A próxima pessoa vai entender?** Nomes, estrutura, um comentário onde o motivo não é óbvio.
4. **Combina com o resto do código?** Por último, e a maior parte disso é das máquinas.

Um problema na linha 1 torna as linhas 3 e 4 irrelevantes: não adianta polir nomes numa mudança que
resolve o problema errado.
