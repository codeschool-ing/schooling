---
title: Quando parear compensa, e quanto custa
version: 1
---

**Parear custa mais horas de gente por tarefa e compra menos defeitos, aprendizado mais rápido e uma
segunda pessoa que entende o código.** Se a troca vale a pena depende da tarefa, e o erro é comum nas
duas direções: times que nunca pareiam porque isso "corta a produtividade pela metade", e times que
pareiam em tudo e não entendem por que estão cansados.

## O que as evidências dizem

O estudo inicial mais citado, de Alistair Cockburn e Laurie Williams, em 2000, comparou estudantes
trabalhando sozinhos e em pares. Os pares gastaram cerca de 15% mais esforço total nos mesmos
programas e produziram código com cerca de 15% menos defeitos. Estudos posteriores, entre eles uma
meta-análise de Jo Hannay e colegas em 2009, acharam efeitos reais, mas modestos, e dependentes da
tarefa: parear ajudou mais em tarefas complexas e com programadores menos experientes, e ajudou menos,
ou custou mais, em tarefas simples feitas por especialistas.

**Então a resposta para "parear compensa?" é "para qual tarefa, e qual par?"**, e a próxima parte é
um jeito de responder.

## Pareie quando

- **A tarefa é difícil ou arriscada.** Uma mudança em como o checkout reserva estoque (as ofertas
  relâmpago da aula 8) é onde uma segunda pessoa pegando um erro vale uma hora do tempo dela.
- **O conhecimento precisa se espalhar.** Só uma pessoa entende o leitor do outbox; parear a próxima
  mudança nele com outra pessoa leva o *bus factor* (quantas pessoas precisariam sumir para ninguém
  mais entender o código) de um para dois em uma semana.
- **Alguém é novo**, no time, no código ou na linguagem. Parear é o onboarding mais rápido que
  existe; a tarefa de crescimento da aula 10 andou mais rápido porque Diego pareou na primeira parte.
- **Duas pessoas discordam sobre um design.** Escrever a primeira versão juntas muitas vezes resolve
  mais rápido do que a discussão resolveria.

## Não pareie quando

- **A tarefa é simples e bem entendida.** Uma mudança de configuração, a correção de um texto, uma
  atualização que a ferramenta faz por você.
- **O trabalho é leitura exploratória.** Ler um código grande para entendê-lo se faz sozinho, e
  depois se discute.
- **Um dos dois está exausto**, ou passou o dia todo pareando.

## O custo que as pessoas esquecem

Os 15% de esforço a mais aparecem no mesmo dia. O que não aparece é o custo de **não** parear nas
tarefas certas: o leitor do outbox que só uma pessoa entende cai enquanto essa pessoa está de férias,
e o time passa dois dias aprendendo como ele funciona sob pressão. Parear traz esse custo para antes e
o deixa menor. **Se a troca vale a pena é uma pergunta sobre risco e conhecimento, não sobre
velocidade de digitação.**
