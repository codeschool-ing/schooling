---
title: As Cheat Sheets, para o como
version: 1
---

O ASVS diz **o que** uma aplicação bem construída faz. De propósito, diz pouco sobre **como**, porque
o como depende da linguagem e do framework. O como mora num projeto irmão, a **OWASP Cheat Sheet
Series**: páginas curtas e práticas, uma por assunto, escritas e revisadas por quem faz, de leitura
gratuita em `cheatsheetseries.owasp.org`.

Uma folha de referência é o que abrir quando o requisito está claro e a chamada certa não. Cada aula
deste curso tem uma ou mais (os nomes ficam em inglês, como aparecem no site):

| aula | folha de referência |
|---|---|
| 2, 3 | Input Validation |
| 4, 7 | Cross Site Scripting Prevention |
| 5 | SQL Injection Prevention, e Query Parameterization |
| 8 | Content Security Policy |
| 9 | Cross-Site Request Forgery Prevention |
| 10 | Session Management |
| 11 | Password Storage, e Authentication |
| 12, 13 | Authorization, e Insecure Direct Object Reference Prevention |
| 14 | File Upload |
| 15 | Error Handling, e Logging |
| 16 | Secrets Management |
| 17 | Vulnerable Dependency Management |

### Como ler uma

Uma folha de referência não é um tutorial para seguir do começo. Três hábitos a tornam útil:

- **Vá até ela com uma pergunta.** "Quanto tempo uma sessão deve durar parada?" tem resposta num
  parágrafo da Session Management. Ler a folha inteira primeiro é mais lento e fixa menos.
- **Traduza o conselho para a chamada do seu framework, e depois confira a documentação dele.** As
  folhas nomeiam conceitos e muitas vezes mostram várias linguagens; a função exata do Flask, do
  Django ou do Express é você quem acha, aquilo que a aula 1 chamou de metade que não se leva.
- **Prefira a folha a um post de blog.** Uma folha é revisada e atualizada quando o conselho muda; um
  post de 2017 mandando guardar senha com SHA-256 continua indexado e continua errado.

### As duas juntas

O padrão de trabalho de uma equipe é curto: **o ASVS para a lista, as folhas de referência para o
método, os testes para a prova.** Um requisito do ASVS vira um teste que o enuncia, a folha diz como
fazer o teste passar de um jeito que outros já revisaram, e o teste o mantém verdadeiro.
