---
title: O postmortem
version: 1
---

Um **postmortem** é o relato escrito de um incidente, feito depois que ele acabou. O propósito é
mudar alguma coisa, para a mesma falha ficar menos provável ou menos danosa da próxima vez. Aqui vai
um curto, do incidente das aulas 10 e 11.

## O que aconteceu

O 1.6.0 acrescentou uma estimativa de entrega por estado. A tabela de estados pulou o prefixo de CEP
57, Alagoas, e toda cotação para Alagoas levantava `KeyError: 57`, respondido como 500. Os testes
passaram: os quatro exemplos não incluíam Alagoas. O smoke test passou: ele não pede cotação. O green
recebeu todo o tráfego, e 77 de 1.551 requisições falharam antes da volta para o blue.

## O que limitou o estrago

- O blue continuava rodando, então voltar levou três milissegundos.
- O erro foi registrado com a causa, então o diagnóstico levou um `grep`.
- Liberado como canário, o mesmo bug falhou 2 requisições, e o `canary.py` o parou sem ninguém
  olhando.

## O que muda

- **Um teste de regressão** confere que todo prefixo tem estimativa. Feito no 1.6.1.
- **A estimativa fica atrás de uma flag**, então o próximo problema com ela pode ser desligado sem
  deploy. Feito no 1.6.1.
- **Os releases saem como canários** com os critérios de parada desta aula, em vez de uma troca
  completa.
- **A regra do `canary.py` é revista**, porque um erro só pode abortar um release bom entre 50 e 99
  respostas.

## Sem culpados

O relato nomeia **o que** aconteceu, não **quem** deixou acontecer. A Ana escreveu `range(40, 57)` e
a revisão não viu; nenhum dos dois fatos é uma causa sobre a qual alguém consiga agir. "Ter mais
cuidado" não é mudança. Um teste, uma flag e uma regra são mudanças, e protegem a próxima pessoa, que
vai ser tão cuidadosa quanto e vai cometer outro erro. Uma equipe cujos postmortems procuram culpados
logo tem postmortems que os escondem.
