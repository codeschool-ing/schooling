---
title: O que o simulador do iOS esconde
version: 1
---

**O simulador esconde mais que o emulador, porque imita menos**: não há iPhone virtual por baixo
dele, só o Mac. O que ele mostra bem é o comportamento do próprio app, as telas em todo tamanho de
iPhone que a Apple lista, o texto em todo idioma, os pedidos de permissão e o tratamento das
respostas do boxoffice. O que ele não consegue mostrar é qualquer coisa que pertença ao celular. Esta
seção foi escrita sem um Mac, como a lição 18 disse de tudo o que é iOS neste curso, e **a própria
documentação do Simulator, da Apple, lista o hardware e os frameworks que faltam nele**; essa lista
muda a cada Xcode, então leia a da versão que você usa.

## Outro binário

O app no simulador é compilado para o processador do Mac. O app num iPhone é compilado de novo, para
o processador do celular, com os ajustes de um build de aparelho, e assinado com o certificado da
equipe. Então **o simulador nunca roda o arquivo que um usuário instala.** Um defeito que vem do
build de aparelho, um ajuste que difere entre os dois, ou uma permissão que só é conferida num app
assinado num celular, aparece pela primeira vez num celular. O caso mais comum é a própria
assinatura: o simulador não pede nada do provisionamento que um celular confere, então um build com
a assinatura configurada errada roda no simulador todo dia e se recusa a instalar no primeiro iPhone
real.

## Nenhum limite de celular

O simulador tem a memória e o processador do Mac. O iOS num celular fecha um app que usa memória
demais, e num iPhone mais antigo esse limite é baixo; no simulador o mesmo app continua rodando.
Tudo é mais rápido também, então uma tela que leva um segundo para montar num iPhone antigo aparece
na hora. **Velocidade e memória são perguntas para um celular**, o mais antigo que seus usuários
ainda carregam.

## Nenhum hardware de celular

No momento em que este curso foi escrito, o simulador não tem câmera para ler o QR code de um
ingresso, e o movimento e a localização dele são o que você define no menu *Features*, sem deriva e
sem caminhada. Tudo o que toca o rádio, como a rede móvel, o Bluetooth ou uma ligação chegando, falta
ou é imitado. A rede dele é a do Mac, estável e rápida, o que facilitou a lição 18 e torna um
elevador ou um túnel impossíveis de encontrar por acaso.

## A mesma regra do emulador

Nada disso faz do simulador uma ferramenta ruim. É onde a maioria dos testes iOS deve rodar, pelo
mesmo motivo que a maioria dos testes Android roda no emulador: ele é rápido, volta limpo ao estado
inicial e só erra em lugares que você consegue nomear. **A habilidade é saber quais lugares**, e a
próxima seção põe as duas plataformas numa tabela só.
