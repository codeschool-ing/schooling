---
title: O OWASP Top 10, lido a partir do front-end
version: 1
---

**O OWASP Top 10 é uma lista dos tipos de falha que mais deixam alguém fazer o que não deveria,
ordenada a partir de dados de aplicações reais.** É uma lista de riscos, não de requisitos: ela diz onde
olhar, e a edição atual é o **Top 10:2025**. A maior parte dela acontece em servidores. Lida do lado do
navegador, ela fica assim:

| | categoria | onde o front-end a encontra |
|---|---|---|
| A01 | Broken Access Control | esconder um botão não é controle de acesso: quem precisa recusar é o servidor, como o 401 da aula 5 |
| A02 | Security Misconfiguration | cabeçalhos faltando, ferramentas de debug publicadas, a política da aula 8 ausente |
| A03 | Software Supply Chain Failures | todo pacote em `node_modules` roda com os direitos da página; uma seção desta aula |
| A04 | Cryptographic Failures | tokens em armazenamento legível, cookies sem `Secure`; aula 6 |
| A05 | Injection | texto que vira código na página: **cross-site scripting**, a primeira metade desta aula |
| A06 | Insecure Design | uma defesa que ninguém projetou, como um logout que não encerra o login |
| A07 | Authentication Failures | aulas 5 e 6 |
| A08 | Software or Data Integrity Failures | um script carregado de uma CDN sem nada que confira se ele mudou |
| A09 | Security Logging and Alerting Failures | relatórios de CSP que ninguém junta, erros de que ninguém fica sabendo |
| A10 | Mishandling of Exceptional Conditions | uma página de erro que mostra um stack trace, uma falha que deixa a página pela metade |

Esta aula fica com os três ataques que pertencem ao navegador mais do que a qualquer outra coisa. O
**cross-site scripting** transforma o texto de uma pessoa em código na página de alguém. O **cross-site
request forgery** faz o navegador de uma pessoa mandar uma requisição que ela nunca quis mandar, com os
cookies dela. E o **clickjacking** põe uma página dentro de outra para um clique cair onde a pessoa não
viu. Cada um é mostrado no planner com uma testemunha que não faz nada além de provar a falha, depois
fechado, com um teste que o mantém fechado.

A seção sobre a cadeia de suprimentos vem por último, porque é a que nenhum teste do código do próprio
planner consegue cobrir.
