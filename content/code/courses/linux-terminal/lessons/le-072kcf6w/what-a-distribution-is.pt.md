---
title: O que está de fato sendo empacotado
version: 1
---

A aula 1 disse que "Linux" é o kernel e nada além disso. Isso deixa uma pergunta que ela não
respondeu: se o kernel é um programa, o que são Ubuntu, Debian, Rocky e Alpine?

**São pacotes.** Cada um pega o mesmo kernel e embrulha mais quatro coisas em volta dele, e toda
diferença que você vier a encontrar entre duas distribuições é diferença numa das quatro.

## As quatro coisas

| | o que é | por que difere |
|---|---|---|
| **o kernel** | o programa que a aula 1 descreveu | versão, e quais patches foram aplicados |
| **o userland** | `ls`, `grep`, `bash` — os comandos | GNU na maioria, **busybox** no Alpine |
| **o gerenciador de pacotes** | como software chega — seção 15 da aula 1 | `apt`, `dnf`, `zypper`, `apk` |
| **padrões e política** | quais serviços sobem, onde os arquivos ficam, por quanto tempo tem suporte | quase todo o resto |

As duas primeiras são quase iguais em todo lugar, e é por isso que este curso funciona. **As duas
últimas são tudo o que distingue uma distribuição de outra**, e a quarta é maior que a terceira.

## Política é a invisível

"Padrões e política" parece a categoria mole. É a que decide como é conviver com uma máquina:

- **Quão novo é o software?** O Debian entrega versões de anos atrás e muito bem testadas. O Arch
  entrega o que saiu esta semana. Nenhum está errado; são respostas a perguntas diferentes, e o
  `release-models` daqui a duas seções é sobre essa troca.
- **Por quanto tempo tem suporte?** Cinco anos, dez anos, ou até o próximo lançamento daqui a seis
  meses. O `lifecycles` é sobre o que acontece quando essa janela fecha.
- **O que vem ligado?** Um firewall, ou não. SELinux em modo obrigatório, ou AppArmor, ou nada.
- **Onde os arquivos ficam?** Quase sempre igual — o padrão da seção 13 da aula 1 — e não
  inteiramente. A configuração do Apache é `/etc/apache2` no Debian e `/etc/httpd` no Red Hat.
- **Quem decide?** Uma empresa com contrato de suporte, ou um projeto voluntário com uma
  constituição. Isso não é fato técnico e é o que mais importa numa instalação de dez anos.

## O que uma distribuição não é

**Não é um sistema operacional diferente.** Um programa compilado para uma normalmente roda em
outra. A interface do kernel é a mesma, os comandos são os mesmos, o sistema de arquivos é o
mesmo. Quem conhece Ubuntu não é iniciante no Rocky; é alguém que vai ter de consultar dois
comandos.

**E não é um fork do Linux.** Todas entregam essencialmente o mesmo kernel, do mesmo lugar, com os
patches e a versão delas. Não existe um "Linux do Ubuntu" separado de um "Linux do Red Hat" no
nível do kernel — existe um kernel e cem jeitos de empacotar as coisas em volta.

## Por que existem tantas

Porque empacotar é barato e discordar é de graça. Qualquer um pode pegar o kernel, escolher um
userland, escolher um gerenciador de pacotes, decidir uma política e publicar o resultado. Quase
todas essas tentativas não vão a lugar nenhum. Um punhado virou as famílias da próxima seção, e
**as que duraram duraram por serem mantidas, não por serem espertas.**

Que é o filtro prático quando alguém sugerir uma distribuição que você nunca ouviu falar: não "ela
é boa", mas *quem vai estar publicando as atualizações de segurança dela daqui a quatro anos.*
