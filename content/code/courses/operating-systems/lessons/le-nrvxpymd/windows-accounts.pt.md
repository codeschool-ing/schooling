---
title: Contas no Windows
version: 1
---

Um PC com Windows pode ter três tipos de conta, e a aula 2 escolheu entre elas na configuração:

| tipo | entra com | onde mora |
|---|---|---|
| **conta local** | um nome e uma senha neste PC | só neste PC |
| **conta Microsoft** | um endereço de e-mail | na Microsoft, sincronizada com o PC |
| **conta corporativa ou de estudante** | o endereço da organização | no Entra ID ou no Active Directory do escritório |

Seja qual for o tipo, **dois grupos decidem o que ela pode**: **Administradores** e **Usuários**. Um
membro de Usuários é um **usuário padrão**, que roda programas e muda os próprios ajustes, mas não
instala para todos, não muda configurações do sistema nem lê arquivos dos outros.

O Windows também tem uma conta embutida chamada **Administrador**, **desativada por padrão** desde o
Windows Vista. Como o root do Ubuntu, ela existe e ninguém entra nela.

```sh
net user                                   # the local accounts
net localgroup Administrators              # who is an administrator here
Get-LocalUser | Select-Object Name, Enabled, LastLogon
Get-LocalGroupMember -Group Administrators
New-LocalUser -Name "reception" -NoPassword
Add-LocalGroupMember -Group Users -Member "reception"
whoami /groups                             # which groups this session carries
```

**Nada disso foi rodado para esta aula.** Vale lembrar do `whoami /groups`: ele lista os grupos que a
*sessão atual* carrega, que é o que decide o acesso, e depois que alguém é posto num grupo ele mostra se
a sessão dessa pessoa já se atualizou. A regra da aula 9 era a mesma: **mudanças de grupo chegam no
próximo login**.

*Configurações > Contas > Outros usuários* faz o mesmo com janelas e botões; o **`lusrmgr.msc`**,
*Usuários e Grupos Locais*, é a ferramenta mais completa, na Pro para cima.
