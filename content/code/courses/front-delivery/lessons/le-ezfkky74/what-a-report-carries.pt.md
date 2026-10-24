---
title: O que um relatório leva
version: 1
---

**Um bom relatório tem o que é preciso para achar a causa, e nada que não seja.** O do planner leva seis
campos, e cada um justifica o lugar que ocupa:

| campo | vem de | por quê |
|---|---|---|
| `message` | o erro | o que deu errado, numa linha, e o que agrupa os relatórios primeiro |
| `stack` | o erro | onde, depois que um map a desfaz |
| `source` | o planner | qual parte capturou: um listener ou um dos `catch` do próprio planner |
| `release` | o build | com quais maps ler a pilha |
| `path` | `location.pathname` | qual tela, sem a query string |
| `at` | o coletor | quando, por um relógio em que a equipe confia |

## O que um serviço hospedado acrescenta

Os serviços de uma seção mais adiante acrescentam mais, e a maior parte é útil:

- **Breadcrumbs**: as últimas coisas que aconteceram antes do erro, como cliques, navegações, requisições
  e linhas de console. *Apertou Mark done, depois um `POST /graphql` respondeu 502* explica um relatório
  que a pilha sozinha não explica.
- **O ambiente**: navegador, versão, sistema operacional. Um bug que só um navegador mostra é achado por
  essa coluna.
- **Agrupamento**: relatórios com a mesma mensagem e os mesmos frames de cima são uma **issue**, contada,
  em vez de dez mil linhas. Um serviço chama isso de fingerprint.
- **Amostragem**: guardar um relatório em dez, ou em cem, quando um site grande mandaria milhões.

## O que ele deixa de fora, de propósito

O `path` é `location.pathname`, e não `location.href`. A parte depois do `?` é onde endereços levam coisas
como um termo de busca, um token de um link de e-mail ou o próprio endereço de e-mail, e nada disso é
preciso para achar um bug. O mesmo vale para os valores de campos de formulário, o conteúdo da página e
qualquer coisa que identifique a pessoa: **o planner não manda id de usuário, nome nem e-mail.** A próxima
seção é sobre por que isso é uma questão legal, e não só de capricho.
