---
title: Registrar o que quem defende precisa
version: 1
---

Deixar coisas fora do log é metade da aula. A outra metade é pôr nele o que alguém vai precisar no dia
em que algo der errado: **um registro de eventos de segurança detalhado o bastante para dizer quem fez
o quê, quando, e se era permitido**.

### Quais eventos

| evento | por que importa |
|---|---|
| login, bem-sucedido e falho | uma rajada de falhas numa conta, ou em muitas contas vindas de um lugar, é o primeiro sinal mais comum de problema |
| logout e expiração de sessão | para saber quando o acesso terminou |
| acesso recusado | o 404 da aula 1 para o agendamento de outra pessoa vale uma linha: um é engano, cinquenta são um padrão |
| uma mudança em quem pode fazer o quê | um papel concedido ou removido, por quem |
| uma exportação ou leitura em massa | o evento que transforma um vazamento de um registro em milhares |
| um erro inesperado | com a referência, como na correção desta aula |

### O que cada linha traz

**Quando** (data e hora com fuso), **quem** (um identificador de conta, nunca uma senha), **o quê** (a
ação e o objeto, por identificador), **de onde** (o endereço da requisição, onde a lei e a política
permitirem) **e o resultado** (permitido, recusado, falhou). Uma linha sem qualquer um dos cinco é uma
linha que não responde à pergunta para a qual foi escrita.

### Alguém precisa ler

Um log que ninguém olha não protege nada. O mínimo é um alerta nos eventos que deveriam ser raros:
muitas falhas de login, uma mudança de papel fora do horário, um pico de recusas. Para onde os logs vão
e quem os observa vai além do código de uma aplicação.

::: track security devsecops
Na sua trilha, `soc-response` é o curso sobre ler esses registros: reuni-los num lugar, correlacioná-los
e decidir quando um evento é um incidente. O que esta aula pede do código é escrevê-los, completos e
seguros.
:::

::: track *
Reunir esses registros num lugar, correlacioná-los e decidir quando um evento é um incidente é o
trabalho de uma equipe de operações de segurança, e um assunto próprio. O que esta aula pede do código
é escrevê-los, completos e seguros.
:::
