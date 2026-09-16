---
title: Red Hat, e o que aconteceu com o CentOS
version: 1
---

Esta família é onde mora o Linux corporativo, e é a que tem uma história — uma história de que você
precisa, porque os nomes mudaram recentemente o bastante para que quase toda a documentação que
você vai encontrar seja sobre um mundo que não existe mais.

## Três posições, não três produtos

| | o que é | quem paga |
|---|---|---|
| **Fedora** | rio acima. Coisas novas chegam aqui primeiro, lançado duas vezes por ano, suporte de uns 13 meses | ninguém |
| **RHEL** | Red Hat Enterprise Linux. Dez anos de suporte, certificações, contrato | uma assinatura |
| **Rocky, Alma** | RHEL reconstruído do código, grátis, compatível binariamente | ninguém |

Leia isso como uma esteira: uma ideia se prova no Fedora, é estabilizada no RHEL, e o RHEL é
reconstruído por outros para quem quer a compatibilidade sem o contrato.

## A história, resumida

**O CentOS era o RHEL grátis.** Por anos, a resposta para "quero RHEL mas não posso pagar" era
CentOS — uma reconstrução, versão por versão, lançada algumas semanas atrás. Um número enorme de
servidores rodava isso.

No fim de 2020 a Red Hat encerrou aquilo e transformou o CentOS em **CentOS Stream**, que fica
*rio acima* do RHEL em vez de rio abaixo. O Stream é uma prévia do que o próximo lançamento menor
do RHEL vai conter. É uma coisa razoável de existir, e **não** é o que quem rodava CentOS queria:
queriam a coisa atrás do RHEL, não a coisa à frente dele.

**O Rocky Linux e o AlmaLinux nasceram em resposta**, em poucos meses, ambos fazendo o que o CentOS
fazia. O Rocky foi começado por um dos próprios fundadores do CentOS. Os dois são grátis, os dois
acompanham o RHEL de perto, e os dois são o que você deve esperar encontrar hoje num servidor onde
antes encontraria CentOS.

## Por que isso te importa, em vez de ser curiosidade

**Porque você vai ler documentação que diz CentOS e quer dizer Rocky ou Alma.** Anos de posts,
respostas de Stack Overflow e instruções de fabricante foram escritos para CentOS 7 ou 8. Quase
tudo se aplica sem mudança — os comandos são os mesmos — mas os nomes e as URLs dos repositórios
não.

**E porque o CentOS 7 está fora de suporte.** Acabou em junho de 2024, e máquinas rodando ele
continuam por aí recebendo nada. A seção 09 é sobre o que isso quer dizer; aqui basta reconhecer o
nome como um aviso, e não como um fato neutro.

## O que você de fato digita

O gerenciador de pacotes da família é o `dnf`, e `yum` é o nome antigo dele — em sistemas atuais o
`yum` costuma ser mantido como link para o `dnf`, para instruções antigas continuarem funcionando:

| | |
|---|---|
| instalar | `sudo dnf install nginx` |
| atualizar tudo | `sudo dnf upgrade` |
| buscar | `dnf search nginx` |
| qual pacote é dono deste arquivo | `rpm -qf /caminho` |

Dois hábitos desta família que diferem do Debian, e a aula 7 volta nos dois:

- **O `dnf` atualiza os metadados sozinho.** Não há passo de `apt update` para esquecer.
- **Software extra costuma vir do EPEL** — Extra Packages for Enterprise Linux — um repositório que
  você acrescenta de propósito, porque o conjunto do próprio RHEL é pequeno e conservador de
  propósito.

## E o SELinux está ligado

Esta família habilita o **SELinux** por padrão, em modo obrigatório. É um segundo sistema de
permissões acima do que a aula 4 ensina, e ele vai, em algum momento, negar algo que as permissões
comuns claramente permitem.

Isso não é defeito e a resposta não é desligar, que é o que todo post de fórum vai mandar você
fazer. A aula 4 o nomeia direito. O que importa agora é reconhecer o formato: **no Red Hat, uma
negativa que não faz sentido contra o `ls -l` normalmente é SELinux**, e existe um log que diz
isso.
