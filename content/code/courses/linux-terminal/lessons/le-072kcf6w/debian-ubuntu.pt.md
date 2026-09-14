---
title: Debian, Ubuntu, e o arquivo que mente para você
version: 1
---

Esta é a família em que você tem mais chance de estar pisando. A maioria dos tutoriais assume ela,
a maioria das imagens de nuvem vem com ela, e a imagem Docker de todo exemplo é construída em cima
dela.

## Debian

Um projeto voluntário, começado em 1993, com uma constituição escrita e um contrato social. Não é
produto de empresa e não há de quem comprar suporte — o que é justamente o ponto, e também a razão
de uma empresa poder não escolher.

**O hábito que o define é a cautela.** Um lançamento estável entrega versões de um a três anos
atrás, porque foram testadas por um a três anos. Nada se mexe até ficar sem graça. A seção 29
defende o argumento; por ora, Debian é o que você escolhe quando quer uma máquina que possa
esquecer.

## Ubuntu

O produto da Canonical, construído sobre o Debian, lançado a cada seis meses — e a cada dois anos
um deles é um **LTS**, com suporte de cinco anos, estendível a dez.

O número da versão é a data: **24.04** é abril de 2024, **22.04** é abril de 2022. Todo LTS é um
lançamento de abril de ano par, o que faz `24.04`, `22.04` e `20.04` serem LTS e `24.10` não ser.
Essa é a coisa mais útil de saber sobre as versões do Ubuntu, e cabe numa frase.

Todo lançamento tem também um codinome, e os codinomes são animais de duas palavras em ordem
alfabética — o 24.04 é *Noble Numbat*. Eles aparecem na configuração dos repositórios, então vale
saber consultar:

```
ana@vm:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
```

Leia as duas últimas linhas juntas: **`ID=ubuntu`, `ID_LIKE=debian`.** É uma máquina te dizendo
qual distribuição ela é e a qual família pertence, e é o assunto inteiro da seção 32.

## O arquivo que mente

Aqui está a mesma máquina, com a pergunta mais antiga:

```
ana@vm:~$ cat /etc/debian_version
trixie/sid
```

**É uma máquina Ubuntu afirmando ser Debian trixie.** Ela não está exatamente mentindo — o arquivo
registra de qual foto do Debian este Ubuntu foi construído — mas se você ler como "em qual sistema
eu estou", recebe uma resposta errada com confiança total.

`/etc/debian_version`, `/etc/redhat-release` e os outros são arquivos antigos, por família, de
antes do padrão. Eles ainda existem, ainda são escritos, e são a razão de o `/etc/os-release` ter
sido inventado: **um arquivo, toda distribuição, os mesmos nomes de campo.** Faça a pergunta nova.

## O que o Ubuntu acrescentou, e o que isso custa

| | |
|---|---|
| **PPAs** | repositórios de terceiros, um comando para acrescentar. Conveniente, não assinado pela Canonical, e a aula 7 ordena por risco |
| **snaps** | um segundo sistema de empacotamento ao lado do `apt`, isolado e que se atualiza sozinho. Genuinamente polêmico: alguns softwares só vêm assim, e algumas pessoas removem por princípio |
| **um LTS em que dá para confiar** | cinco anos por padrão, dez com assinatura, e é por isso que é o padrão em toda nuvem |

Dá para ver os repositórios de terceiros de uma máquina direto — eles são arquivos:

```
ana@vm:~$ ls /etc/apt/sources.list.d/
deadsnakes-ubuntu-ppa-noble.sources
docker.list
ondrej-ubuntu-php-noble.sources
ubuntu.sources
```

Quatro entradas: a do próprio Ubuntu, a do Docker, e duas PPAs. **Cada uma delas é alguém em quem
você decidiu confiar**, e a lista vale ser lida quando você herda uma máquina — a seção 15 da aula
1 disse que o risco se mudou para fora do repositório, e este diretório é para onde ele se mudou.

## E as derivadas abaixo

Linux Mint, Pop!_OS, Zorin e outras são construídas sobre o Ubuntu, que é construído sobre o
Debian. Elas trocam o ambiente gráfico e alguns padrões; por baixo, o `apt` funciona, os caminhos
são os mesmos, e o `ID_LIKE=debian` vale. **Se você dirige Ubuntu, dirige qualquer uma delas** —
que é exatamente o que a família da seção 24 estava prometendo.
