---
title: O macOS, e a regra que os três compartilham
version: 1
---

Um Mac tem dois tipos de conta: **Administrador** e **Padrão**, definidos em *Ajustes do Sistema >
Usuários e Grupos*. O Assistente de Configuração da aula 4 fez da primeira conta uma administradora.

Quando um usuário Padrão, ou um administrador, faz algo que precisa de mais, uma janela pede **nome e
senha de um administrador**. É o aviso de credenciais do UAC, e não existe versão só com Sim: **no Mac
até um administrador digita a senha**, ou usa o Touch ID, o que fica mais perto do `sudo` do
que do UAC.

No Terminal, o `sudo` funciona como no Linux, e **só administradores podem usá-lo**. As contas e o grupo
admin podem ser listados:

```sh
dscl . -list /Users | grep -v '^_'          # the accounts, without the system ones
dscl . -read /Groups/admin GroupMembership  # who is an administrator
id                                          # the same command as on Linux
```

**Nada disso foi rodado para esta aula.** O `grep -v '^_'` esconde as contas de sistema, cujos nomes
começam com sublinhado no macOS; `_www` é a do servidor web, como a `www-data` do Linux.

## Os três lado a lado

| | Linux | Windows | macOS |
|---|---|---|---|
| a conta todo-poderosa | `root`, bloqueado no Ubuntu | *Administrador*, desativado | `root`, desativado |
| o que faz de alguém administrador | o grupo `sudo` (ou `wheel`) | o grupo Administradores | o grupo admin |
| pegando o poder emprestado | `sudo`, por comando | um aviso do UAC, por programa | uma janela de senha, por ação |
| a senha de quem | a sua | Sim, ou a de um administrador | a de um administrador |
| onde fica registrado | o journal, por comando | o log de Segurança, se a auditoria estiver ligada | o log unificado |

A regra por baixo de tudo é o **princípio do menor privilégio**: cada pessoa e cada programa recebe o
menor acesso que o deixa fazer o seu trabalho. As contas das pessoas são padrão; o poder é emprestado,
usado e devolvido; e o registro de cada empréstimo é o que torna uma máquina compartilhada responsável.
