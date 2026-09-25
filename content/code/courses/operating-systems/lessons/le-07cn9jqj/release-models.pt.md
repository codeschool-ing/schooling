---
title: Versões fixas e contínuas
version: 1
---

As distribuições diferem em **como a mudança chega**, e essa é a diferença que mais importa numa
máquina de que alguém depende.

## Versões fixas

Ubuntu, Debian, Fedora, RHEL e openSUSE Leap publicam **versões numeradas**. Dentro de uma versão, as
versões dos programas ficam **congeladas**: o `bash` do servidor hoje é a mesma versão do `bash` que
ele tinha no dia em que a 24.04 saiu, com as correções de segurança aplicadas a ela. Recursos novos
esperam a próxima versão, e passar para ela é um passo deliberado, o `do-release-upgrade` da aula 3.

É isso que torna uma versão fixa confiável. Uma atualização comum existe para fechar uma brecha ou
corrigir um bug, não para mudar o que um programa faz, e um script escrito no primeiro ano continua
funcionando no quinto.

## Versões contínuas

O **Arch**, o **openSUSE Tumbleweed** e o **sid** do Debian **não têm versões**. Cada pacote passa
para a versão mais nova quando ela fica pronta, e uma atualização pode trazer uma nova versão principal
de qualquer coisa em qualquer dia. Nunca há uma atualização de versão a fazer, porque o sistema está
sempre no mais recente.

Isso serve ao notebook de um desenvolvedor, em que o compilador mais novo importa e uma quebra custa uma
tarde a uma pessoa. Não serve ao servidor do escritório, em que ninguém quer que o software do
compartilhamento de arquivos mude de comportamento na semana em que o contador fecha o ano.

## Os dois tipos do Ubuntu

O Ubuntu publica uma versão a cada **abril e outubro**, numerada por ano e mês: 24.04 é abril de 2024.
A cada dois abris a versão é uma **LTS**, *long-term support*, suporte de longo prazo. As do meio são
versões **intermediárias**, com suporte por **nove meses**, feitas para experimentar o que vem por aí.

A seção 04 põe números nisso, e o servidor consegue lê-los sozinho.
