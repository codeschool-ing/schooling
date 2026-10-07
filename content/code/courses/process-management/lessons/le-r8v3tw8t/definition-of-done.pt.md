---
title: A Definição de Pronto
version: 1
---

A Definição de Pronto é **uma descrição formal do estado em que o Incremento está quando atende às medidas de qualidade exigidas para o produto**. Quando um item do backlog a atende, nasce um Incremento. Quando não atende, ele não é mostrado na revisão e volta ao Product Backlog para consideração futura. Não existe "quase pronto" no vocabulário do guia.

## Como é uma

Uma Definição de Pronto é uma lista curta que vale para todo item, escrita pelo time ou herdada da organização. Para o time Agenda da Ponte Saúde — o time inventado que este curso acompanha, construindo um aplicativo de agendamento para clínicas de fisioterapia — ela diz:

- o código foi revisado por alguém que não o escreveu;
- testes automatizados cobrem o comportamento novo e a suíte inteira passa;
- a mudança está implantada no ambiente de homologação e foi conferida lá;
- as verificações de acessibilidade passam em toda tela que a mudança toca;
- o texto que o usuário vê existe em português e em inglês;
- o que um operador precisa saber está no runbook.

**Cada linha é algo que alguém consegue conferir com sim ou não.** "Boa qualidade" não é uma linha; "a suíte inteira passa" é.

## Pronto não é critério de aceite

Duas listas costumam ser confundidas. **Critérios de aceite pertencem a um item** e dizem o que aquele item tem de fazer: *um paciente pode cancelar até 24 horas antes da consulta*. **A Definição de Pronto pertence a todo item** e diz quão terminado ele tem de estar: revisado, testado, implantado em homologação. Um item precisa das duas para contar, e um time que escreve suas regras de qualidade nos critérios de aceite de cada história acaba com uma Definição de Pronto diferente por história.

## Por que isso importa a um arquiteto

A Definição de Pronto é onde requisitos não funcionais ganham dentes. Uma organização que precisa que toda mudança mantenha o tempo de resposta p95 abaixo de um limite, registre logs num formato estruturado ou passe por uma varredura de segurança pode escrever isso na Definição de Pronto, e a partir daí isso faz parte do que *pronto* significa em vez de ser uma tarefa à parte que alguém agenda quando sobra tempo. Se a organização tem uma Definição de Pronto padrão, todo Time Scrum tem de segui-la como mínimo, e os times podem acrescentar a ela.

O custo também aparece aqui. Uma Definição de Pronto que exige um teste de regressão manual do aplicativo inteiro torna cada item mais lento de terminar, e a resposta honesta é automatizar o teste ou aceitar o ritmo mais lento — não apagar a linha em silêncio nos últimos dias de uma Sprint.
