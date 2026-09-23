---
title: A revisão, do ponto de vista da plataforma
version: 1
---

Esta seção é a mecânica: o que os botões registram. As aulas 13 e 14 são a parte mais difícil que os
botões — o que dizer numa revisão, e como receber uma.

## Comentários em linhas

Quem revisa lê a aba *files changed* e **comenta numa linha específica do diff**. O comentário fica
preso àquela linha, e quando o autor envia uma mudança nela, o serviço mostra o comentário como
*outdated* e mantém a conversa. A maioria dos serviços também deixa quem revisa propor a substituição
exata de uma linha, que o autor aceita com um clique, gerando um commit.

## Uma revisão termina com um veredito

No GitHub, quem revisa termina com um de três:

- **Comment** — observações, sem veredito para nenhum lado.
- **Approve** — pode entrar como está.
- **Request changes** — não deve entrar até alguma coisa ser resolvida.

GitLab e Bitbucket têm as mesmas ideias com nomes um pouco diferentes. O que importa é que o veredito
fica **registrado, com nome e horário**, ao lado da mudança a que se refere.

## Regras que o repositório pode impor

O branch principal de um repositório de equipe costuma ser **protegido**: configurações no serviço de
hospedagem das quais o próprio Git não sabe nada. As comuns:

- ninguém envia direto para o `main`; toda mudança chega por um pull request;
- um pull request precisa de uma ou duas aprovações antes de o botão de merge funcionar;
- os checks têm de passar;
- um `git push --force` para o `main` é recusado de vez, que é o aviso da aula 7 virado trava.

Alguns repositórios também nomeiam donos para partes do código, num arquivo chamado `CODEOWNERS`, de
modo que uma mudança no código de pagamentos peça automaticamente a revisão das pessoas de pagamentos.

**Nada disso é Git.** Um clone do repositório não tem nenhuma dessas regras, e os mesmos commits
poderiam ser enviados para um repositório sem nenhuma delas. A proteção mora no servidor, e é
exatamente por isso que a cópia compartilhada é onde a equipe a coloca.
