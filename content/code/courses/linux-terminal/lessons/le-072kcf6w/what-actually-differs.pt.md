---
title: As seis coisas que de fato diferem
version: 1
---

Esta é a seção para chegar na qual a aula foi construída. Tudo antes era orientação; esta é a lista
que você vai usar.

**Seis diferenças.** Quase todo momento de "esse comando não funciona aqui" é uma delas.

## A tabela

| | Debian, Ubuntu | RHEL, Rocky, Alma | SUSE | Alpine |
|---|---|---|---|---|
| **gerenciador de pacotes** | `apt` | `dnf` | `zypper` | `apk` |
| **formato do pacote** | `.deb` | `.rpm` | `.rpm` | `.apk` |
| **pacote do servidor web** | `apache2` | `httpd` | `apache2` | `apache2` |
| **configuração dele em** | `/etc/apache2` | `/etc/httpd` | `/etc/apache2` | `/etc/apache2` |
| **frente do firewall** | `ufw` | `firewalld` | `firewalld` | `iptables` direto |
| **arcabouço de segurança** | AppArmor | **SELinux** | AppArmor | nenhum, por padrão |

Duas linhas ali são as que de fato vão te pegar.

## 1 · O Apache se chama duas coisas diferentes

`sudo systemctl restart apache2` numa máquina Rocky responde que não existe esse serviço, e o
serviço está rodando. Lá ele se chama `httpd`, a configuração dele está em `/etc/httpd`, e o pacote
é `httpd` também.

É o exemplo mais claro do que uma família te dá: **o software é idêntico, e o nome da coisa que
você digita não é.** O Nginx, em contraste, é `nginx` em todo lugar, e é por isso que ninguém te
avisa sobre o Apache até acontecer.

## 2 · O SELinux está ligado, e ele fica acima das permissões que você conhece

Do lado Red Hat, o SELinux vem habilitado em modo obrigatório. A aula 4 ensina nove bits de
permissão; o SELinux é um segundo sistema acima deles, e os dois discordam numa direção só — **o
SELinux pode negar o que os bits permitem, e nunca o contrário.**

O que isso produz é a recusa mais confusa que um iniciante encontra:

> O `ls -l` diz que o arquivo é legível por todos. O servidor web não consegue ler. Nada nas
> permissões explica por quê.

Toda resposta de fórum vai mandar você desligar o SELinux. Não aprenda esse hábito. A aula 4 dá uma
seção a ele; por ora, reconheça o formato e saiba que existe um log que nomeia a negativa.

## O que não difere, que é mais coisa

A lista acima é curta, e esse é o fato útil. Tudo isto é igual em todo lugar:

- o shell, e tudo nas aulas 3, 6, 8 e 9
- o layout do sistema de arquivos da seção 13 da aula 1
- usuários, grupos e os bits de permissão da aula 4
- `systemd`, `systemctl` e `journalctl` — aula 5, e igual em toda família menos o Alpine
- processos, sinais, `ps`, `top` — aula 6
- `grep`, `sed`, `awk`, pipes e redirecionamento — aula 8
- SSH, e tudo sobre alcançar uma máquina

**O Alpine é a exceção que confirma a regra**: ele difere também no userland e no sistema de
inicialização, e é por isso que a seção 07 dá uma seção inteira a ele em vez de uma coluna.

## Traduzindo um comando que te deram

A habilidade prática é pegar uma instrução escrita para uma família e rodar em outra:

| te deram | no Red Hat | no SUSE |
|---|---|---|
| `apt update && apt install nginx` | `dnf install nginx` | `zypper install nginx` |
| `apt remove nginx` | `dnf remove nginx` | `zypper remove nginx` |
| `apt search nginx` | `dnf search nginx` | `zypper search nginx` |
| `ufw allow 80` | `firewall-cmd --add-service=http` | `firewall-cmd --add-service=http` |
| `systemctl restart apache2` | `systemctl restart httpd` | `systemctl restart apache2` |

Repare quanto de cada linha sobrevive. O verbo é o mesmo, o nome do pacote quase sempre é o mesmo,
e o que mudou foi a primeira palavra — que é exatamente o que o único comando da próxima seção te
diz.
