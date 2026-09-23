---
title: O ticket que não estava pronto
version: 1
---

A equipe da padaria cresceu. A Carla entrou para desenvolver e o Diego testa toda mudança antes de ela ser
lançada, então agora são quatro pessoas no quadro. Na segunda, a Ana pega o ticket #35 do topo do *a
fazer*:

> **#35 Pagar online**

Esse é o ticket inteiro. Até quarta ela descobriu, uma de cada vez, as perguntas que ele não respondia:

- **Quais formas?** Cartão, Pix, ou os dois? Pix é o que a maioria dos clientes pede, e ninguém tinha dito.
- **Com qual empresa?** A padaria não tem conta em nenhum serviço de pagamento. Abrir uma leva uma semana,
  e a API de cada serviço é diferente.
- **E o estorno?** Um pedido cancelado tem de ser devolvido. Hoje isso é um formulário preenchido no banco.
- **Como alguém vai saber que terminou?** Não há critérios de aceite, então "pronto" é o que a Ana
  decidir.

Três dias de trabalho construídos sobre palpites, e a maioria estava errada. **O ticket não estava pronto
para começar**, e nada no quadro dizia isso.

## Pronto para começar é um checklist

Muitas equipes escrevem o que um ticket precisa ter antes de alguém poder pegá-lo, uma **definição de
preparado** (*definition of ready*). Ela varia, mas a maioria se parece com isto:

1. **O problema está descrito**, com quem o tem e por que importa.
2. **Critérios de aceite dizem como todo mundo vai saber que terminou** (aula 12).
3. **As perguntas em aberto têm resposta**, ou o ticket diz quais ainda estão abertas e quem vai responder.
4. **As dependências são conhecidas**: outra equipe, um fornecedor, uma conta que precisa existir antes.
5. **É pequeno o bastante** para terminar em poucos dias. Se não for, é dividido antes.

O #35 falha nos cinco. O título dele é um desejo, não um ticket.

## Quando você descobre no meio do caminho

Acontece até em boas equipes, porque algumas perguntas só aparecem quando você começa. Quando acontecer,
**pare de adivinhar e diga**: escreva as perguntas no ticket, avise quem o escreveu ou o product owner, e
marque o card como bloqueado, ou volte com ele. O dia que você perde perguntando custa menos que os dois dias
que você perde respondendo sozinho e errando.

A pior versão é silenciosa: alguém que adivinha, constrói e apresenta o resultado na review, onde quem
pediu vê pela primeira vez e diz que não era isso. A aula 19 é sobre não ter surpresa no fim, e começa aqui.
